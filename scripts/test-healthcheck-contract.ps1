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

# Marks a temp tree as a package root. The leak exemption is judged relative to the
# first ancestor holding template.json, so blocks that assert exemption must place
# one; blocks that assert NO exemption must not.
function Write-Manifest([string]$Root) {
    New-Item -ItemType Directory -Force -Path $Root | Out-Null
    [System.IO.File]::WriteAllText(
        (Join-Path $Root 'template.json'),
        '{"name":"worldthread-core","version":"0.0.0"}',
        $utf8NoBom)
}

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
        $expLeak = if ($null -eq $fx.expect_leak) { $null } else { [string]$fx.expect_leak }
        $actLeak = if ($null -eq $obj.leak) { $null } else { [string]$obj.leak }
        Assert-True ($actLeak -eq $expLeak) "$($fx.name): leak=$actLeak, expected $expLeak"
    }

    # === Block 2: clean subset -> exit 0 ===
    $rc = Invoke-Both @($tempClean)
    Assert-True ($rc.Node.ExitCode -eq 0) "clean: node exit $($rc.Node.ExitCode), expected 0"
    Assert-True ($rc.Python.ExitCode -eq 0) "clean: python exit $($rc.Python.ExitCode), expected 0"
    Assert-True ($rc.Node.StdOut -ceq $rc.Python.StdOut) "clean: node and python stdout differ"

    # === Block 2b: private-dir exemption (leak markers allowed under game/private/) ===
    # A tree ending in game/private must skip the private-marker check entirely:
    # private files legitimately mention host-log / campaign-arc etc.
    #
    # The exemption is judged relative to the PACKAGE ROOT (first ancestor holding
    # template.json), not the absolute path -- so this temp tree must be a real
    # package or the base falls back to the scan root and nothing is exempt.
    # Writing template.json here is the point of the block, not a workaround.
    $leakFixtures = @($fixtures | Where-Object { $null -ne $_.expect_leak })
    Assert-True ($leakFixtures.Count -gt 0) "no leak fixtures found; private-exemption block would be vacuous"
    $privRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("wt-healthcheck-priv-" + [System.Guid]::NewGuid().ToString('N'))
    $privTarget = Join-Path (Join-Path $privRoot 'game') 'private'
    New-Item -ItemType Directory -Force -Path $privTarget | Out-Null
    Write-Manifest $privRoot
    try {
        Write-Fixtures $privTarget $leakFixtures
        # Only fixtures whose sole defect is a leak marker; parse-valid ones must now pass.
        $parseOkLeaks = @($leakFixtures | Where-Object { $_.parse_ok })
        Assert-True ($parseOkLeaks.Count -gt 0) "no parse-clean leak fixtures; private-exempt assertions would be vacuous"
        $badLineLeaks = @($leakFixtures | Where-Object { -not $_.parse_ok })
        Assert-True ($badLineLeaks.Count -gt 0) "no unparseable leak fixtures; exemption-vs-parse assertions would be vacuous"
        $rp = Invoke-Both @($privTarget)
        Assert-True ($rp.Node.StdOut -ceq $rp.Python.StdOut) "private-exempt: node and python stdout differ"
        $rpByFile = @{}
        foreach ($outLine in ($rp.Node.StdOut -split "`n")) {
            $t = $outLine.Trim()
            if ($t -eq '') { continue }
            $o = $t | ConvertFrom-Json
            if (-not ($o.PSObject.Properties.Name -contains 'summary')) { $rpByFile[$o.file] = $o }
        }
        # Exemption must only disable the leak check; parse failures still surface.
        foreach ($fx in $badLineLeaks) {
            $o = $rpByFile[$fx.name]
            Assert-True ($null -ne $o) "private-exempt: missing result for $($fx.name)"
            if ($null -ne $o) {
                Assert-True (-not [bool]$o.ok) "private-exempt: $($fx.name) ok=$($o.ok), expected false (parse failure still detected)"
                $expL = if ($null -eq $fx.expect_line) { $null } else { [int]$fx.expect_line }
                $actL = if ($null -eq $o.line) { $null } else { [int]$o.line }
                Assert-True ($actL -eq $expL) "private-exempt: $($fx.name) line=$actL, expected $expL"
                Assert-True ($null -eq $o.leak) "private-exempt: $($fx.name) leak=$($o.leak), expected null"
            }
        }
        $expRpExit = if ($badLineLeaks.Count -gt 0) { 1 } else { 0 }
        Assert-True ($rp.Node.ExitCode -eq $expRpExit) "private-exempt: node exit $($rp.Node.ExitCode), expected $expRpExit"
        Assert-True ($rp.Python.ExitCode -eq $expRpExit) "private-exempt: python exit $($rp.Python.ExitCode), expected $expRpExit"
        foreach ($fx in $parseOkLeaks) {
            $lineObj = ($rp.Node.StdOut -split "`n" | Where-Object { $_.Trim() -ne '' } | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { $_.file -eq $fx.name })
            Assert-True ($null -ne $lineObj) "private-exempt: missing result for $($fx.name)"
            Assert-True ([bool]$lineObj.ok) "private-exempt: $($fx.name) ok=$($lineObj.ok), expected true (leak check skipped)"
            Assert-True ($null -eq $lineObj.leak) "private-exempt: $($fx.name) leak=$($lineObj.leak), expected null"
        }
        # Same fixtures outside game/private must still be flagged.
        $outRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("wt-healthcheck-pub-" + [System.Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Force -Path $outRoot | Out-Null
        try {
            Write-Fixtures $outRoot $parseOkLeaks
            $ro = Invoke-Both @($outRoot)
            Assert-True ($ro.Node.ExitCode -eq 1) "private-exempt control: node exit $($ro.Node.ExitCode), expected 1"
            Assert-True ($ro.Node.StdOut -ceq $ro.Python.StdOut) "private-exempt control: node and python stdout differ"
        } finally {
            Remove-Item -LiteralPath $outRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    } finally {
        Remove-Item -LiteralPath $privRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Fixtures whose ONLY defect is a leak marker (parse-clean): used by the blocks below
    # to assert leak detection without parse failures muddying the exit code.
    $leakOnly = @($fixtures | Where-Object { $null -ne $_.expect_leak -and $_.parse_ok })
    Assert-True ($leakOnly.Count -gt 0) "no parse-clean leak fixtures; blocks 2c/2d would be vacuous"

    # === Block 2c: a package unpacked under an ancestor named "tools" is STILL checked ===
    # Regression guard for the privacy false negative fixed in this round. The pre-fix
    # implementation matched the ABSOLUTE path against '/tools/', so a package placed under
    # any directory literally named "tools" had its entire tree silently exempted
    # (ok:true, exit 0) with no visible sign -- a green light with no leak check performed.
    # Judging the exemption relative to the package root (template.json) removes that.
    $ancRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("wt-healthcheck-anc-" + [System.Guid]::NewGuid().ToString('N'))
    $ancPkg = Join-Path (Join-Path $ancRoot 'tools') 'pkg'
    $ancTarget = Join-Path (Join-Path $ancPkg 'game') 'state'
    New-Item -ItemType Directory -Force -Path $ancTarget | Out-Null
    Write-Manifest $ancPkg
    try {
        Write-Fixtures $ancTarget $leakOnly
        $ra = Invoke-Both @($ancTarget)
        Assert-True ($ra.Node.ExitCode -eq 1) "tools-ancestor: node exit $($ra.Node.ExitCode), expected 1 (leak must NOT be exempted by an ancestor dir named tools)"
        Assert-True ($ra.Python.ExitCode -eq 1) "tools-ancestor: python exit $($ra.Python.ExitCode), expected 1"
        Assert-True ($ra.Node.StdOut -ceq $ra.Python.StdOut) "tools-ancestor: node and python stdout differ"
        $raByFile = @{}
        foreach ($outLine in ($ra.Node.StdOut -split "`n")) {
            $t = $outLine.Trim()
            if ($t -eq '') { continue }
            $o = $t | ConvertFrom-Json
            if (-not ($o.PSObject.Properties.Name -contains 'summary')) { $raByFile[$o.file] = $o }
        }
        foreach ($fx in $leakOnly) {
            $o = $raByFile[$fx.name]
            Assert-True ($null -ne $o) "tools-ancestor: missing result for $($fx.name)"
            if ($null -ne $o) {
                Assert-True (-not [bool]$o.ok) "tools-ancestor: $($fx.name) ok=$($o.ok), expected false"
                Assert-True ([string]$o.leak -ceq [string]$fx.expect_leak) "tools-ancestor: $($fx.name) leak=$($o.leak), expected $($fx.expect_leak)"
            }
        }
    } finally {
        Remove-Item -LiteralPath $ancRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    # === Block 2cc: an exempt-looking directory BELOW the package root is not exempt ===
    # The exemption is anchored at the package root: game/private/, tools/ and
    # example-campaign/ are exempt only as direct children of it. A player-created
    # game/state/tools/ is inside the player-writable area and must still be checked --
    # matching the segment at any depth would silently exempt exactly the wrong place.
    $depRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("wt-healthcheck-dep-" + [System.Guid]::NewGuid().ToString('N'))
    $depTarget = Join-Path (Join-Path (Join-Path $depRoot 'game') 'state') 'tools'
    New-Item -ItemType Directory -Force -Path $depTarget | Out-Null
    Write-Manifest $depRoot
    try {
        Write-Fixtures $depTarget $leakOnly
        $rd = Invoke-Both @((Join-Path (Join-Path $depRoot 'game') 'state'))
        Assert-True ($rd.Node.ExitCode -eq 1) "nested-exempt-name: node exit $($rd.Node.ExitCode), expected 1 (game/state/tools/ is player-writable, not the package tools dir)"
        Assert-True ($rd.Python.ExitCode -eq 1) "nested-exempt-name: python exit $($rd.Python.ExitCode), expected 1"
        Assert-True ($rd.Node.StdOut -ceq $rd.Python.StdOut) "nested-exempt-name: node and python stdout differ"
        $rdByFile = @{}
        foreach ($outLine in ($rd.Node.StdOut -split "`n")) {
            $t = $outLine.Trim()
            if ($t -eq '') { continue }
            $o = $t | ConvertFrom-Json
            if (-not ($o.PSObject.Properties.Name -contains 'summary')) { $rdByFile[$o.file] = $o }
        }
        Assert-True ($rdByFile.Count -eq $leakOnly.Count) "nested-exempt-name: got $($rdByFile.Count) file results, expected $($leakOnly.Count)"
        foreach ($fx in $leakOnly) {
            $o = $rdByFile["tools/$($fx.name)"]
            Assert-True ($null -ne $o) "nested-exempt-name: missing result for tools/$($fx.name)"
            if ($null -ne $o) {
                Assert-True (-not [bool]$o.ok) "nested-exempt-name: tools/$($fx.name) ok=$($o.ok), expected false"
                Assert-True ([string]$o.leak -ceq [string]$fx.expect_leak) "nested-exempt-name: tools/$($fx.name) leak=$($o.leak), expected $($fx.expect_leak)"
            }
        }
    } finally {
        Remove-Item -LiteralPath $depRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    # === Block 2d: example-campaign/ exemption (shipped sample director material) ===
    # example-campaign/ holds the packaged sample's director material, which legitimately
    # names campaign-arc / hook-market / fronts. It gets the same treatment as
    # game/private/ (PLAYBOOK〈狀態健檢〉).
    $exRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("wt-healthcheck-ex-" + [System.Guid]::NewGuid().ToString('N'))
    $exTarget = Join-Path (Join-Path $exRoot 'example-campaign') 'private-director'
    New-Item -ItemType Directory -Force -Path $exTarget | Out-Null
    Write-Manifest $exRoot
    try {
        Write-Fixtures $exTarget $leakOnly
        $re = Invoke-Both @($exTarget)
        Assert-True ($re.Node.ExitCode -eq 0) "example-campaign-exempt: node exit $($re.Node.ExitCode), expected 0"
        Assert-True ($re.Python.ExitCode -eq 0) "example-campaign-exempt: python exit $($re.Python.ExitCode), expected 0"
        Assert-True ($re.Node.StdOut -ceq $re.Python.StdOut) "example-campaign-exempt: node and python stdout differ"
        # Index by file name and then assert per fixture, so a regression that produces
        # FEWER result lines fails loudly instead of silently running fewer assertions.
        $exByFile = @{}
        foreach ($outLine in ($re.Node.StdOut -split "`n")) {
            $t = $outLine.Trim()
            if ($t -eq '') { continue }
            $o = $t | ConvertFrom-Json
            if (-not ($o.PSObject.Properties.Name -contains 'summary')) { $exByFile[$o.file] = $o }
        }
        Assert-True ($exByFile.Count -eq $leakOnly.Count) "example-campaign-exempt: got $($exByFile.Count) file results, expected $($leakOnly.Count)"
        foreach ($fx in $leakOnly) {
            $o = $exByFile[$fx.name]
            Assert-True ($null -ne $o) "example-campaign-exempt: missing result for $($fx.name)"
            if ($null -ne $o) {
                Assert-True ([bool]$o.ok) "example-campaign-exempt: $($fx.name) ok=$($o.ok), expected true"
                Assert-True ($null -eq $o.leak) "example-campaign-exempt: $($fx.name) leak=$($o.leak), expected null"
            }
        }
    } finally {
        Remove-Item -LiteralPath $exRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    # === Block 2e: existing-but-empty path is distinguishable from a missing path ===
    # Missing path -> exit 1 + stderr (Block 4). Existing path with nothing scannable ->
    # exit 0 and summary.scanned == 0, so blind automation can tell the two apart.
    $emptyRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("wt-healthcheck-empty-" + [System.Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $emptyRoot | Out-Null
    try {
        $rz = Invoke-Both @($emptyRoot)
        Assert-True ($rz.Node.ExitCode -eq 0) "empty-dir: node exit $($rz.Node.ExitCode), expected 0"
        Assert-True ($rz.Python.ExitCode -eq 0) "empty-dir: python exit $($rz.Python.ExitCode), expected 0"
        Assert-True ($rz.Node.StdOut -ceq $rz.Python.StdOut) "empty-dir: node and python stdout differ"
        Assert-True ($rz.Node.StdErr -eq '') "empty-dir: node unexpected stderr: $($rz.Node.StdErr.TrimEnd())"
        $zLines = @(($rz.Node.StdOut -split "`n") | Where-Object { $_.Trim() -ne '' })
        Assert-True ($zLines.Count -eq 1) "empty-dir: expected exactly 1 output line (summary), got $($zLines.Count)"
        if ($zLines.Count -ge 1) {
            $zObj = $zLines[0] | ConvertFrom-Json
            Assert-True ($zObj.PSObject.Properties.Name -contains 'summary') "empty-dir: sole line is not the summary"
            if ($zObj.PSObject.Properties.Name -contains 'summary') {
                Assert-True ($zObj.summary.scanned -eq 0) "empty-dir: summary.scanned $($zObj.summary.scanned), expected 0"
                Assert-True ($zObj.summary.failed -eq 0) "empty-dir: summary.failed $($zObj.summary.failed), expected 0"
            }
        }
    } finally {
        Remove-Item -LiteralPath $emptyRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

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

    # === Block 3b: single-file mode resolves the exemption base from the file's own dir ===
    # Single-file mode takes a different code path for the base (the file's parent dir, not
    # the scan root). Without this block nothing asserts that path: Block 3 scans a fixture
    # with no markers in a tree with no template.json, so the exemption result cannot change
    # any of its assertions.
    $sfRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("wt-healthcheck-sf-" + [System.Guid]::NewGuid().ToString('N'))
    $sfPkg = Join-Path (Join-Path $sfRoot 'tools') 'pkg'
    $sfPriv = Join-Path (Join-Path (Join-Path $sfPkg 'game') 'private') 'director'
    $sfState = Join-Path (Join-Path $sfPkg 'game') 'state'
    New-Item -ItemType Directory -Force -Path $sfPriv | Out-Null
    New-Item -ItemType Directory -Force -Path $sfState | Out-Null
    Write-Manifest $sfPkg
    try {
        $sfFx = $leakOnly[0]
        Write-Fixtures $sfPriv @($sfFx)
        Write-Fixtures $sfState @($sfFx)
        # Exempt: the named file sits under game/private/ relative to the package root.
        $rp1 = Invoke-Both @((Join-Path $sfPriv $sfFx.name))
        Assert-True ($rp1.Node.ExitCode -eq 0) "single-file-exempt: node exit $($rp1.Node.ExitCode), expected 0"
        Assert-True ($rp1.Node.StdOut -ceq $rp1.Python.StdOut) "single-file-exempt: node and python stdout differ"
        $sf1 = (($rp1.Node.StdOut -split "`n") | Where-Object { $_.Trim() -ne '' })[0] | ConvertFrom-Json
        Assert-True ([bool]$sf1.ok) "single-file-exempt: ok=$($sf1.ok), expected true"
        Assert-True ($null -eq $sf1.leak) "single-file-exempt: leak=$($sf1.leak), expected null"
        # Not exempt: same package sits under an ancestor named tools, but the file is in
        # game/state/ relative to the package root -- the ancestor must not exempt it.
        $rp2 = Invoke-Both @((Join-Path $sfState $sfFx.name))
        Assert-True ($rp2.Node.ExitCode -eq 1) "single-file-checked: node exit $($rp2.Node.ExitCode), expected 1"
        Assert-True ($rp2.Node.StdOut -ceq $rp2.Python.StdOut) "single-file-checked: node and python stdout differ"
        $sf2 = (($rp2.Node.StdOut -split "`n") | Where-Object { $_.Trim() -ne '' })[0] | ConvertFrom-Json
        Assert-True (-not [bool]$sf2.ok) "single-file-checked: ok=$($sf2.ok), expected false"
        Assert-True ([string]$sf2.leak -ceq [string]$sfFx.expect_leak) "single-file-checked: leak=$($sf2.leak), expected $($sfFx.expect_leak)"
    } finally {
        Remove-Item -LiteralPath $sfRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

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
    # The two HELP texts document the same contract and must not drift. Only the first
    # line (the usage line) legitimately differs -- it names the tool being invoked.
    $nodeHelpBody = ($rh.Node.StdOut -split "`n", 2)[1]
    $pyHelpBody = ($rh.Python.StdOut -split "`n", 2)[1]
    Assert-True ($nodeHelpBody -ceq $pyHelpBody) "help: node and python help bodies differ beyond the usage line"

    # === Block 6: unknown flag -> exit 1 + stderr, byte-identical ===
    $ru = Invoke-Both @('--bogus')
    Assert-True ($ru.Node.ExitCode -eq 1) "unknown-flag: node exit $($ru.Node.ExitCode), expected 1"
    Assert-True ($ru.Python.ExitCode -eq 1) "unknown-flag: python exit $($ru.Python.ExitCode), expected 1"
    Assert-True ($ru.Node.StdErr.Contains('--bogus')) "unknown-flag: node stderr does not name the bad flag: $($ru.Node.StdErr.TrimEnd())"
    Assert-True ($ru.Node.StdErr -ceq $ru.Python.StdErr) "unknown-flag: node and python stderr differ"

    if ($script:failures.Count -gt 0) {
        $script:failures | ForEach-Object { Write-Host "FAIL $_" }
        throw "Healthcheck contract test failed: $($script:failures.Count) failure(s) across $($fixtures.Count) fixtures + 12 blocks."
    }

    # "identical" here means the UTF-8-decoded stdout/stderr strings compare equal under
    # -ceq, not a raw byte comparison; both tools force UTF-8 and python writes bytes to
    # avoid CRLF translation, so the practical coverage is the same.
    Write-Host "Healthcheck contract test passed: $($fixtures.Count) fixtures + 12 blocks (dir-scan/clean-exit0/private-exempt/tools-ancestor/nested-exempt-name/example-campaign-exempt/empty-dir/single-file/single-file-base/missing-path/help/unknown-flag), node == python identical (UTF-8 decoded)."
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tempClean -Recurse -Force -ErrorAction SilentlyContinue
}
