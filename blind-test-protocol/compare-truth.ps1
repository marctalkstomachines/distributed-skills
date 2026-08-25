# Diffs what the model read against what was actually drawn.
#
# Both files are plain KEY=VALUE lines. The truth file is written by render-dense.ps1.
# The transcription file is whatever the model gave you back, saved in the same format -
# one KEY=VALUE per line, nothing else.
#
# Comparison is EXACT and case-sensitive on the value. That is the whole point: a hex ID
# that is off by one character is wrong, and the failure this test exists to catch is
# precisely the one that looks right.
#
#   .\compare-truth.ps1 -Truth runs\<stamp>\truth-A.txt -Read runs\<stamp>\transcription-A.txt
#
# Exit code is the number of mismatches, so you can gate a script on it. 0 = perfect read.

param(
    [Parameter(Mandatory)][string]$Truth,
    [Parameter(Mandatory)][string]$Read,
    # Print every field, not just the misses. Useful on camera; noisy otherwise.
    [switch]$All
)

function Read-Pairs([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "File not found: $Path" }
    $map = [ordered]@{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $t = $line.Trim()
        if (-not $t -or $t.StartsWith('#')) { continue }
        $eq = $t.IndexOf('=')
        # Values contain no '=' but may contain anything else, so split on the FIRST one.
        if ($eq -lt 1) { continue }
        $map[$t.Substring(0, $eq).Trim()] = $t.Substring($eq + 1).Trim()
    }
    return $map
}

$truthMap = Read-Pairs $Truth
$readMap  = Read-Pairs $Read

if ($truthMap.Count -eq 0) { Write-Error "No KEY=VALUE pairs found in $Truth"; exit 255 }

$miss = 0
$rows = foreach ($key in $truthMap.Keys) {
    $expected = $truthMap[$key]
    $got = if ($readMap.Contains($key)) { $readMap[$key] } else { $null }
    $status =
        if ($null -eq $got) { 'MISSING' }
        elseif ($got -ceq $expected) { 'ok' }
        else { 'WRONG' }
    if ($status -ne 'ok') { $miss++ }
    if ($All -or $status -ne 'ok') {
        [pscustomobject]@{ Field = $key; Truth = $expected; Read = $(if ($null -eq $got) { '(not reported)' } else { $got }); Status = $status }
    }
}

# Fields the model invented that were never on the page - a different failure from a misread,
# and worth seeing, so it is counted and shown separately rather than folded into the score.
$extra = @($readMap.Keys | Where-Object { -not $truthMap.Contains($_) })

$total = $truthMap.Count
$correct = $total - $miss

if ($rows) { $rows | Format-Table -AutoSize | Out-String | Write-Host }
if ($extra.Count) { Write-Host "Reported but never drawn: $($extra -join ', ')" }

Write-Host ("{0}/{1} exact." -f $correct, $total) -NoNewline
if ($miss -eq 0) { Write-Host " Clean read." } else { Write-Host (" {0} wrong or missing." -f $miss) }

# The line that matters. A wrong value the model flagged is a limitation; a wrong value it
# reported confidently is a trap, and the score alone cannot tell you which you got.
if ($miss -gt 0) {
    Write-Host ""
    Write-Host "Now go back and check: did the model WARN you about any of these?"
    Write-Host "The misses it flagged are a limitation. The ones it reported plainly are the finding."
}

exit $miss
