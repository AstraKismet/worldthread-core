[CmdletBinding()]
param(
    [string]$PackagePath = 'dist/worldthread-solo-adventure-template',
    [string]$OutputDirectory = 'artifacts'
)

$ErrorActionPreference = 'Stop'
$utf8Strict = [System.Text.UTF8Encoding]::new($false, $true)

# Decode failures are reported as UTF-8 errors; IO failures surface as themselves.
function Read-Utf8Strict([string]$Path) {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    try {
        return $utf8Strict.GetString($bytes)
    } catch [System.Text.DecoderFallbackException] {
        throw "File is not valid UTF-8: $Path"
    }
}

function Assert-File([string]$RelativePath) {
    $path = Join-Path $PackagePath $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing required file: $RelativePath"
    }
}

if (-not (Test-Path -LiteralPath $PackagePath -PathType Container)) {
    throw "Package directory not found: $PackagePath"
}
# .NET file APIs resolve relative paths against the process CWD, which does not
# follow Set-Location; pin the package path to an absolute path up front.
$PackagePath = (Resolve-Path -LiteralPath $PackagePath).Path

$manifestPath = Join-Path $PackagePath 'template.json'
Assert-File 'template.json'
try {
    $manifest = Read-Utf8Strict $manifestPath | ConvertFrom-Json
} catch {
    throw "Unable to parse template.json: $($_.Exception.Message)"
}

$semVer = '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$'
if ([string]::IsNullOrWhiteSpace($manifest.version) -or $manifest.version -notmatch $semVer) {
    throw "template.json version must be SemVer: $($manifest.version)"
}

$expectedName = Split-Path -Leaf (Resolve-Path -LiteralPath $PackagePath)
if ($manifest.name -ne $expectedName) {
    throw "Manifest name ($($manifest.name)) must match package directory ($expectedName)."
}

@(
    'README.md', 'LICENSE', 'template.json', 'ADDING-RULEBOOKS.md',
    'THIRD-PARTY-NOTICES.md', 'game/session-brief.md', 'extras/README.md',
    'protocol/PLAYBOOK.md', 'protocol/DATA-SCHEMA.md',
    'protocol/RAG-PROTOCOL.md', 'protocol/VOICE-PROTOCOL.md',
    'protocol/adapters/FILE-WORKSPACE.md',
    'game/templates/narrators/gentle-guide.md',
    'game/templates/narrators/balanced-weaver.md',
    'game/templates/narrators/stormkeeper.md',
    'game/templates/narrators/README.md',
    'game/templates/narrators/STYLE-EXTRACTION-TEMPLATE.md',
    'game/templates/starter-state/character.json',
    'game/templates/starter-state/world.json',
    'game/templates/starter-state/logs/events.jsonl',
    'game/templates/starter-state/summaries/current.md',
    'game/reference/scenarios/fog-ferry-opening.md',
    'game/reference/characters/lin-yao.md',
    'game/reference/rules/lightweight-rulings.md',
    'game/reference/setting/fog-ferry.md',
    'game/private/director/fronts/fog-ferry.json',
    'game/private/director/hook-market.md',
    'examples/fog-ferry-first-turn.md',
    'examples/narrator-style-extracted-example.md',
    'tools/dice.mjs',
    'tools/dice.py',
    'tools/dice.fixtures.jsonl',
    'tools/convert-rulebook-prompt.md',
    'tools/extract-narrator-style-prompt.md'
) | ForEach-Object { Assert-File $_ }

$forbiddenDirectories = @('game/state', 'game/rag', '.git')
foreach ($relativePath in $forbiddenDirectories) {
    if (Test-Path -LiteralPath (Join-Path $PackagePath $relativePath)) {
        throw "Package must not contain: $relativePath"
    }
}

$forbiddenExtensions = @('.wav', '.mp3', '.m4a', '.webm', '.pem', '.key', '.pfx', '.p12')
$forbiddenNames = @('.env', 'id_rsa', 'id_ed25519', 'credentials.json')
$textExtensions = @('.md', '.json', '.jsonl', '.txt', '.mjs', '.py')
$files = Get-ChildItem -LiteralPath $PackagePath -Recurse -File
foreach ($file in $files) {
    if ($file.Extension.ToLowerInvariant() -in $textExtensions -or $file.Name -eq 'LICENSE') {
        [void](Read-Utf8Strict $file.FullName)
    }
    if ($file.Extension.ToLowerInvariant() -in $forbiddenExtensions -or $file.Name -in $forbiddenNames) {
        throw "Package contains a non-distributable file: $($file.FullName)"
    }
}

foreach ($jsonFile in $files | Where-Object Extension -eq '.json') {
    try {
        Read-Utf8Strict $jsonFile.FullName | ConvertFrom-Json | Out-Null
    } catch {
        throw "Unable to parse JSON: $($jsonFile.FullName); $($_.Exception.Message)"
    }
}

# Check local relative Markdown links. Web, mail, and anchor links are excluded.
foreach ($markdownFile in $files | Where-Object Extension -eq '.md') {
    $content = Read-Utf8Strict $markdownFile.FullName
    foreach ($match in [regex]::Matches($content, '\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value.Trim()
        if ($target -match '^(https?://|mailto:|#)' -or $target -match '^<') { continue }
        $targetPath = ($target -split '#', 2)[0]
        if ([string]::IsNullOrWhiteSpace($targetPath)) { continue }
        $resolvedTarget = Join-Path $markdownFile.DirectoryName $targetPath
        if (-not (Test-Path -LiteralPath $resolvedTarget)) {
            throw "Markdown link target does not exist: $($markdownFile.FullName) -> $target"
        }
    }
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$zipPath = Join-Path $OutputDirectory "$expectedName-v$($manifest.version).zip"
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
Compress-Archive -Path $PackagePath -DestinationPath $zipPath -CompressionLevel Optimal

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $zipPath))
try {
    $prefix = "$expectedName/"
    foreach ($entry in $archive.Entries) {
        $entryName = $entry.FullName -replace '\\', '/'
        if (-not $entryName.StartsWith($prefix)) {
            throw "ZIP must have one root directory named ${expectedName}: $entryName"
        }
        if ($entryName -match '(^|/)(\.git|game/state|game/rag)(/|$)' -or $entryName -match '\.(wav|mp3|m4a|webm)$') {
            throw "ZIP contains forbidden content: $entryName"
        }
    }
} finally {
    $archive.Dispose()
}

Write-Host "Validation passed: $expectedName v$($manifest.version)"
Write-Host "Package created: $zipPath"
