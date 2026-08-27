$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { $failures.Add($Message) }
}

Write-Host 'Validating PowerShell syntax...'
Get-ChildItem -LiteralPath $repo -Recurse -Filter '*.ps1' |
    Where-Object { $_.FullName -notlike '*\runs\*' } |
    ForEach-Object {
        $tokens = $null
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile(
            $_.FullName, [ref]$tokens, [ref]$errors
        )
        foreach ($error in $errors) {
            $failures.Add("PowerShell parse error in $($_.FullName): $($error.Message)")
        }
    }

Write-Host 'Validating package contracts...'
$required = @(
    'README.md', 'LICENSE', 'DISTRIBUTING.md',
    'organize-batch/README.md', 'organize-batch/SKILL.md',
    'organize-batch/brief.md', 'organize-batch/conventions.md',
    'repo-scout/README.md', 'repo-scout/repo-scout.md',
    'context-tax-reminder/README.md', 'context-tax-reminder/context-tax-reminder.ps1',
    'context-tax-reminder/settings-snippet.json',
    'blind-test-protocol/README.md', 'blind-test-protocol/PROTOCOL.md',
    'blind-test-protocol/render-dense.ps1', 'blind-test-protocol/compare-truth.ps1'
)
foreach ($relative in $required) {
    Assert-True (Test-Path -LiteralPath (Join-Path $repo $relative)) "Missing required file: $relative"
}

$skill = Get-Content -Raw -LiteralPath (Join-Path $repo 'organize-batch/SKILL.md')
Assert-True ($skill -match '(?ms)^---\s*\r?\n.*?^name:\s*organize-batch\s*$.*?^description:\s*.+?^---\s*$') `
    'organize-batch/SKILL.md is missing valid name/description frontmatter.'

$agent = Get-Content -Raw -LiteralPath (Join-Path $repo 'repo-scout/repo-scout.md')
foreach ($field in 'name', 'description', 'tools', 'model') {
    Assert-True ($agent -match "(?m)^${field}:\s*.+$") "repo-scout agent is missing frontmatter field: $field"
}

try {
    Get-Content -Raw -LiteralPath (Join-Path $repo 'context-tax-reminder/settings-snippet.json') |
        ConvertFrom-Json | Out-Null
} catch {
    $failures.Add("settings-snippet.json is invalid JSON: $($_.Exception.Message)")
}

Write-Host 'Validating documentation links and public boundaries...'
Get-ChildItem -LiteralPath $repo -Recurse -Filter '*.md' | ForEach-Object {
    $markdown = Get-Content -Raw -LiteralPath $_.FullName
    foreach ($match in [regex]::Matches($markdown, '\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value.Trim()
        if ($target -match '^(https?://|mailto:|#)') { continue }
        $pathOnly = ($target -split '#', 2)[0]
        if (-not $pathOnly) { continue }
        $resolved = Join-Path $_.DirectoryName ([uri]::UnescapeDataString($pathOnly))
        Assert-True (Test-Path -LiteralPath $resolved) "Broken relative link in $($_.FullName): $target"
    }

    foreach ($privatePath in 'C:\Users\Crucible', 'D:\brand', 'D:\distributed-skills') {
        Assert-True (-not $markdown.Contains($privatePath)) "Private absolute path in $($_.FullName): $privatePath"
    }
}

Write-Host 'Running blind-test utility smoke test...'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("distributed-skills-" + [guid]::NewGuid())
try {
    $runDir = Join-Path $tempRoot 'blind'
    & (Join-Path $repo 'blind-test-protocol/render-dense.ps1') -OutDir $runDir | Out-Host
    foreach ($name in 'dense-A-12px.png', 'dense-B-8px.png', 'truth-A.txt', 'truth-B.txt') {
        Assert-True (Test-Path -LiteralPath (Join-Path $runDir $name)) "Renderer did not create $name"
    }

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
        (Join-Path $repo 'blind-test-protocol/compare-truth.ps1') `
        -Truth (Join-Path $runDir 'truth-A.txt') -Read (Join-Path $runDir 'truth-A.txt')
    Assert-True ($LASTEXITCODE -eq 0) "Comparator smoke test exited $LASTEXITCODE instead of 0."

    Write-Host 'Running hook fixture smoke test...'
    $transcript = Join-Path $tempRoot 'transcript.jsonl'
    $hookCopy = Join-Path $tempRoot 'context-tax-reminder.ps1'
    Copy-Item -LiteralPath (Join-Path $repo 'context-tax-reminder/context-tax-reminder.ps1') `
        -Destination $hookCopy
    '{"type":"assistant","message":{"model":"claude-opus-5","usage":{"input_tokens":110000,"cache_creation_input_tokens":1000,"cache_read_input_tokens":2000,"output_tokens":1000}}}' |
        Set-Content -LiteralPath $transcript -Encoding utf8
    $payload = @{ transcript_path = $transcript; session_id = 'distribution-validation' } |
        ConvertTo-Json -Compress
    $hookJson = $payload | powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
        $hookCopy
    Assert-True ($LASTEXITCODE -eq 0) "Hook smoke test exited $LASTEXITCODE instead of 0."
    try {
        $hook = $hookJson | ConvertFrom-Json
        Assert-True ($hook.systemMessage -match '^>> Context: 114\.0k') 'Hook emitted an unexpected context reading.'
        Assert-True ($hook.hookSpecificOutput.hookEventName -eq 'UserPromptSubmit') `
            'Hook emitted an unexpected event name.'
    } catch {
        $failures.Add("Hook did not emit valid JSON: $($_.Exception.Message)")
    }
} finally {
    if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}

if ($failures.Count) {
    Write-Error ("Distribution validation failed:`n- " + ($failures -join "`n- "))
    exit 1
}

Write-Host 'Distribution validation passed.'
