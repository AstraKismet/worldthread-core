[CmdletBinding()]
param(
    [string]$PackagePath = 'dist/worldthread-core'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $PackagePath -PathType Container)) {
    throw "Package directory not found: $PackagePath"
}
$PackagePath = (Resolve-Path -LiteralPath $PackagePath).Path

$fixturesPath = Join-Path $PackagePath 'tools/healthcheck.fixtures.jsonl'
$mjsPath = Join-Path $PackagePath 'tools/healthcheck.mjs'
$pyPath = Join-Path $PackagePath 'tools/healthcheck.py'
foreach ($required in @($fixturesPath, $mjsPath, $pyPath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Missing required file: $required"
    }
}

# Runs a tool and captures exit code plus UTF-8 stdout/stderr. Uses
# System.Diagnostics.Process directly: PowerShell 5.1 wraps native stderr in
# ErrorRecords and its stream redirection mangles the raw bytes we compare.
function Invoke-Tool([string]$Exe, [string[]]$ArgumentParts) {
    $rendered = foreach ($part in $ArgumentParts) {
        if ($part -match '"') { throw "Tool arguments must not contain quotes: $part" }
        if ($part -match '\s') { '"' + $part + '"' } else { $part }
    }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Exe
    $psi.Arguments = ($rendered -join ' ')
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $process = [System.Diagnostics.Process]::Start($psi)
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    return [pscustomobject]@{ ExitCode = $process.ExitCode; StdOut = $stdout; StdErr = $stderr }
}

# Picks the first candidate that exists and answers --version with exit 0
# (skips e.g. the Windows Store python stub). Returns exe plus prefix args.
function Find-Runtime([object[]]$Candidates, [string]$Label) {
    foreach ($candidate in $Candidates) {
        $command = Get-Command $candidate.Name -CommandType Application -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if (-not $command) { continue }
        try {
            $probe = Invoke-Tool $command.Source ($candidate.Prefix + @('--version'))
        } catch {
            continue
        }
        if ($probe.ExitCode -eq 0) {
            return [pscustomobject]@{ Exe = $command.Source; Prefix = $candidate.Prefix }
        }
    }
    $names = ($Candidates | ForEach-Object { $_.Name }) -join ', '
    throw "Runtime not found for ${Label} (tried: $names)."
}

$node = Find-Runtime @(@{ Name = 'node'; Prefix = @() }) 'Node.js 18+'
$python = Find-Runtime @(
    @{ Name = 'python3'; Prefix = @() },
    @{ Name = 'python'; Prefix = @() },
    @{ Name = 'py'; Prefix = @('-3') }
) 'Python 3.8+'
$nodePrefix = @($node.Prefix + @($mjsPath))
$pyPrefix = @($python.Prefix + @($pyPath))

# Runs both tools with the same args; returns their captured results.
function Invoke-Both([string[]]$ToolArgs) {
    return [pscustomobject]@{
        Node = Invoke-Tool $node.Exe ($nodePrefix + $ToolArgs)
        Python = Invoke-Tool $python.Exe ($pyPrefix + $ToolArgs)
    }
}

$script:failures = New-Object System.Collections.Generic.List[string]
function Assert-True($Condition, $Message) {
    if (-not $Condition) { $script:failures.Add($Message) }
}

# Load fixtures: each line describes one file (name + content) + expected result.
$fixtures = @()
foreach ($line in Get-Content -LiteralPath $fixturesPath -Encoding UTF8) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $fixtures += , ($line | ConvertFrom-Json)
}
if ($fixtures.Count -eq 0) { throw "No fixtures found in $fixturesPath" }

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
function Write-Fixtures([string]$Root, [object[]]$Items) {
    foreach ($fx in $Items) {
        $dest = Join-Path $Root ($fx.name -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
        [System.IO.File]::WriteAllText($dest, [string]$fx.content, $utf8NoBom)
    }
}

# Two temp trees: all fixtures (has failures) and clean subset (all valid).
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("wt-healthcheck-" + [System.Guid]::NewGuid().ToString('N'))
$tempClean = Join-Path ([System.IO.Path]::GetTempPath()) ("wt-healthcheck-clean-" + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
New-Item -ItemType Directory -Force -Path $tempClean | Out-Null
try {
    Write-Fixtures $tempRoot $fixtures
    $cleanFixtures = @($fixtures | Where-Object { $_.expect_ok })
    Write-Fixtures $tempClean $cleanFixtures

    $expFailed = @($fixtures | Where-Object { -not $_.expect_ok }).Count
    $expOk = @($fixtures | Where-Object { $_.expect_ok }).Count

    # === Block 1: full dir scan (has failures -> exit 1), per-file + summary ===
    $r = Invoke-Both @($tempRoot)
    Assert-True ($r.Node.ExitCode -eq 1) "full-scan: node exit $($r.Node.ExitCode), expected 1"
    Assert-True ($r.Python.ExitCode -eq 1) "full-scan: python exit $($r.Python.ExitCode), expected 1"
    Assert-True ($r.Node.StdOut -ceq $r.Python.StdOut) "full-scan: node and python stdout differ"
    Assert-True ($r.Node.StdErr -eq '') "full-scan: node unexpected stderr: $($r.Node.StdErr.TrimEnd())"
    Assert-True ($r.Python.StdErr -eq '') "full-scan: python unexpected stderr: $($r.Python.StdErr.TrimEnd())"

    $byFile = @{}
    $summary = $null
    foreach ($outLine in ($r.Node.StdOut -split "`n")) {
        $trimmed = $outLine.Trim()
        if ($trimmed -eq '') { continue }
        $obj = $trimmed | ConvertFrom-Json
        if ($obj.PSObject.Properties.Name -contains 'summary') { $summary = $obj.summary } else { $byFile[$obj.file] = $obj }
    }
    Assert-True ($null -ne $summary) "full-scan: missing summary line"
    if ($null -ne $summary) {
        Assert-True ($summary.scanned -eq $fixtures.Count) "summary.scanned $($summary.scanned), expected $($fixtures.Count)"
        Assert-True ($summary.failed -eq $expFailed) "summary.failed $($summary.failed), expected $expFailed"
        Assert-True ($summary.ok -eq $expOk) "summary.ok $($summary.ok), expected $expOk"
    }
    foreach ($fx in $fixtures) {
        $obj = $byFile[$fx.name]
        if ($null -eq $obj) { Assert-True $false "full-scan: missing result for $($fx.name)"; continue }
        Assert-True ([bool]$obj.ok -eq [bool]$fx.expect_ok) "$($fx.name): ok=$($obj.ok), expected $($fx.expect_ok)"
        Assert-True ($obj.kind -eq $fx.kind) "$($fx.name): kind=$($obj.kind), expected $($fx.kind)"
        $expLine = if ($null -eq $fx.expect_line) { $null } else { [int]$fx.expect_line }
        $actLine = if ($null -eq $obj.line) { $null } else { [int]$obj.line }
        Assert-True ($actLine -eq $expLine) "$($fx.name): line=$actLine, expected $expLine"
    }

    # === Block 2: clean subset -> exit 0 ===
    $rc = Invoke-Both @($tempClean)
    Assert-True ($rc.Node.ExitCode -eq 0) "clean: node exit $($rc.Node.ExitCode), expected 0"
    Assert-True ($rc.Python.ExitCode -eq 0) "clean: python exit $($rc.Python.ExitCode), expected 0"
    Assert-True ($rc.Node.StdOut -ceq $rc.Python.StdOut) "clean: node and python stdout differ"

    # === Block 3: single-file mode (file field == basename) ===
    $oneFile = Join-Path $tempClean 'valid.json'
    $rs = Invoke-Both @($oneFile)
    Assert-True ($rs.Node.ExitCode -eq 0) "single-file: node exit $($rs.Node.ExitCode), expected 0"
    Assert-True ($rs.Node.StdOut -ceq $rs.Python.StdOut) "single-file: node and python stdout differ"
    $sfLine = (($rs.Node.StdOut -split "`n") | Where-Object { $_.Trim() -ne '' })[0]
    $sf = $sfLine | ConvertFrom-Json
    Assert-True ($sf.file -eq 'valid.json') "single-file: file=$($sf.file), expected valid.json"
    Assert-True ($sf.kind -eq 'json') "single-file: kind=$($sf.kind), expected json"
    Assert-True ([bool]$sf.ok -eq $true) "single-file: ok=$($sf.ok), expected true"

    # === Block 4: missing path -> exit 1 + stderr, byte-identical ===
    $rm = Invoke-Both @((Join-Path $tempRoot 'does-not-exist'))
    Assert-True ($rm.Node.ExitCode -eq 1) "missing-path: node exit $($rm.Node.ExitCode), expected 1"
    Assert-True ($rm.Python.ExitCode -eq 1) "missing-path: python exit $($rm.Python.ExitCode), expected 1"
    Assert-True ($rm.Node.StdErr.Trim() -ne '') "missing-path: node produced no stderr"
    Assert-True ($rm.Node.StdErr -ceq $rm.Python.StdErr) "missing-path: node and python stderr differ"

    # === Block 5: --help -> exit 0 + non-empty stdout ===
    $rh = Invoke-Both @('--help')
    Assert-True ($rh.Node.ExitCode -eq 0) "help: node exit $($rh.Node.ExitCode), expected 0"
    Assert-True ($rh.Python.ExitCode -eq 0) "help: python exit $($rh.Python.ExitCode), expected 0"
    Assert-True ($rh.Node.StdOut.Trim() -ne '') "help: node produced no stdout"
    Assert-True ($rh.Python.StdOut.Trim() -ne '') "help: python produced no stdout"

    # === Block 6: unknown flag -> exit 1 + stderr, byte-identical ===
    $ru = Invoke-Both @('--bogus')
    Assert-True ($ru.Node.ExitCode -eq 1) "unknown-flag: node exit $($ru.Node.ExitCode), expected 1"
    Assert-True ($ru.Python.ExitCode -eq 1) "unknown-flag: python exit $($ru.Python.ExitCode), expected 1"
    Assert-True ($ru.Node.StdErr.Contains('--bogus')) "unknown-flag: node stderr does not name the bad flag: $($ru.Node.StdErr.TrimEnd())"
    Assert-True ($ru.Node.StdErr -ceq $ru.Python.StdErr) "unknown-flag: node and python stderr differ"

    if ($script:failures.Count -gt 0) {
        $script:failures | ForEach-Object { Write-Host "FAIL $_" }
        throw "Healthcheck contract test failed: $($script:failures.Count) failure(s) across $($fixtures.Count) fixtures + 6 blocks."
    }

    Write-Host "Healthcheck contract test passed: $($fixtures.Count) fixtures + 6 blocks (dir-scan/clean-exit0/single-file/missing-path/help/unknown-flag), node == python byte-identical."
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tempClean -Recurse -Force -ErrorAction SilentlyContinue
}
