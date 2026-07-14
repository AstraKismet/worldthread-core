[CmdletBinding()]
param(
    [string]$PackagePath = 'dist/worldthread-solo-adventure-template'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $PackagePath -PathType Container)) {
    throw "Package directory not found: $PackagePath"
}
# .NET file APIs resolve relative paths against the process CWD, which does not
# follow Set-Location; pin the package path to an absolute path up front.
$PackagePath = (Resolve-Path -LiteralPath $PackagePath).Path

$fixturesPath = Join-Path $PackagePath 'tools/dice.fixtures.jsonl'
$mjsPath = Join-Path $PackagePath 'tools/dice.mjs'
$pyPath = Join-Path $PackagePath 'tools/dice.py'
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

$runners = @(
    @{ Label = 'node'; Exe = $node.Exe; Prefix = @($node.Prefix + @($mjsPath)) },
    @{ Label = 'python'; Exe = $python.Exe; Prefix = @($python.Prefix + @($pyPath)) }
)

$failures = New-Object System.Collections.Generic.List[string]
$caseCount = 0

# Golden-line fixtures: both tools must reproduce the recorded output exactly.
foreach ($line in Get-Content -LiteralPath $fixturesPath -Encoding UTF8) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $caseCount += 1
    $fixture = $line | ConvertFrom-Json
    $fixtureArgs = @($fixture.args)
    $caseName = "case $caseCount ($($fixtureArgs -join ' '))"

    foreach ($runner in $runners) {
        $run = Invoke-Tool $runner.Exe ($runner.Prefix + $fixtureArgs)
        if ($run.ExitCode -ne [int]$fixture.expect_exit) {
            $failures.Add("${caseName}: $($runner.Label) exit $($run.ExitCode), expected $($fixture.expect_exit)")
            continue
        }
        if ([int]$fixture.expect_exit -eq 0) {
            $actual = $run.StdOut.TrimEnd("`r", "`n")
            if ($actual -cne $fixture.expect_stdout) {
                $failures.Add("${caseName}: $($runner.Label) stdout mismatch`n  expected: $($fixture.expect_stdout)`n  actual:   $actual")
            }
            if ($run.StdErr -ne '') {
                $failures.Add("${caseName}: $($runner.Label) unexpected stderr: $($run.StdErr.TrimEnd())")
            }
        } else {
            $actual = $run.StdErr.TrimEnd("`r", "`n")
            if ($actual -cne $fixture.expect_stderr) {
                $failures.Add("${caseName}: $($runner.Label) stderr mismatch`n  expected: $($fixture.expect_stderr)`n  actual:   $actual")
            }
            if ($run.StdOut -ne '') {
                $failures.Add("${caseName}: $($runner.Label) unexpected stdout: $($run.StdOut.TrimEnd())")
            }
        }
    }
}

if ($caseCount -eq 0) {
    throw "No fixtures found in $fixturesPath"
}

# Live-roll shape check: unseeded output must keep the exact key order and a
# result consistent with rolls + modifier (values themselves are random).
$shapePattern = '^\{"formula":"2d6\+3","rolls":\[[1-6],[1-6]\],"modifier":3,"result":\d+,"source":"tool","rolled_at":"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z"\}$'
foreach ($runner in $runners) {
    $run = Invoke-Tool $runner.Exe ($runner.Prefix + @('2d6+3'))
    $actual = $run.StdOut.TrimEnd("`r", "`n")
    if ($run.ExitCode -ne 0) {
        $failures.Add("live roll: $($runner.Label) exit $($run.ExitCode): $($run.StdErr.TrimEnd())")
        continue
    }
    if ($actual -cnotmatch $shapePattern) {
        $failures.Add("live roll: $($runner.Label) output shape mismatch: $actual")
        continue
    }
    $parsed = $actual | ConvertFrom-Json
    $sum = ($parsed.rolls | Measure-Object -Sum).Sum + $parsed.modifier
    if ($parsed.result -ne $sum) {
        $failures.Add("live roll: $($runner.Label) result $($parsed.result) != rolls+modifier $sum")
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "FAIL $_" }
    throw "Dice contract test failed: $($failures.Count) failure(s) across $caseCount fixtures."
}

Write-Host "Dice contract test passed: $caseCount fixtures + live-roll shape check (node, python)."
