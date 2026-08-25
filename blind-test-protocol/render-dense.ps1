# Renders a page of realistic-looking text to two PNGs at two different densities, and
# writes the exact values it drew to a truth file you must not open until after the test.
#
# The point is the BLIND part: the values are randomized at render time, so nobody -
# not you, not the model - knows them in advance. Whatever the model reads back can be
# checked against ground truth that could not have leaked into its answer.
#
# Run it, hand the PNGs to the AI, ask for the exact values, THEN diff. See PROTOCOL.md.

param(
    # Each run writes to its own timestamped folder beside this script, so re-running
    # never overwrites an earlier run's evidence.
    [string]$OutDir = (Join-Path $PSScriptRoot ("runs\" + (Get-Date -Format 'yyyy-MM-dd-HHmm')))
)

Add-Type -AssemblyName System.Drawing

New-Item -ItemType Directory -Force $OutDir | Out-Null

function New-Hex([int]$n) {
    -join (1..$n | ForEach-Object { '0123456789abcdef'[(Get-Random -Maximum 16)] })
}

function New-DenseImage {
    param(
        [string]$ImagePath,
        [string]$TruthPath,
        [double]$FontPx,
        [string]$Label
    )

    $W = 1120; $H = 1120; $margin = 8

    $bmp = New-Object System.Drawing.Bitmap($W, $H)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::White)
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $font = New-Object System.Drawing.Font("Consolas", [single]$FontPx, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $fmt = [System.Drawing.StringFormat]::GenericTypographic

    $probe = $g.MeasureString(("M" * 100), $font, 100000, $fmt)
    $charW = $probe.Width / 100
    $lineH = [Math]::Ceiling($font.GetHeight($g))
    $cols = [Math]::Floor(($W - 2 * $margin) / $charW)
    $rows = [Math]::Floor(($H - 2 * $margin) / $lineH)

    # ---- randomized ground-truth facts (written to truth file only, never echoed) ----
    $snapId   = New-Hex 12
    $checksum = New-Hex 16
    $total    = (Get-Random -Minimum 1000 -Maximum 9999)
    $totalFmt = "{0:N0}" -f $total
    $revenue  = "{0}.{1:D2}" -f (Get-Random -Minimum 100 -Maximum 999), (Get-Random -Minimum 0 -Maximum 99)
    $mm = "{0:D2}" -f (Get-Random -Minimum 1 -Maximum 12)
    $dd = "{0:D2}" -f (Get-Random -Minimum 1 -Maximum 28)
    $date = "2026-$mm-$dd"
    $ids = @(); for ($i = 1; $i -le 10; $i++) { $ids += (New-Hex 12) }

    $truth = @()
    $truth += "SNAPSHOT-ID=$snapId"
    $truth += "DATE=$date"
    $truth += "TOTAL-PROMPTS=$totalFmt"
    $truth += "REVENUE=`$$revenue"
    $truth += "CHECKSUM=$checksum"
    for ($i = 1; $i -le 10; $i++) { $truth += ("ID-{0:D2}={1}" -f $i, $ids[$i-1]) }
    Set-Content -Path $TruthPath -Value $truth -Encoding ascii

    # ---- filler generator (corpus-snapshot flavored) ----
    $verbs = @("verify","refactor","summarize","triage","deploy","audit","rename","migrate","benchmark","document")
    # Filler project names. Swap these for your own if you want the image to look like
    # your material - it changes nothing about the test, only what the page reads like.
    $projs = @("api-gateway","billing","web-client","scheduler","data-import","auth-service","reporting","infra")
    $outcomes = @("done","blocked","deferred","merged","reverted","flaky","verified","pending")
    $sb = New-Object System.Text.StringBuilder
    $n = 0
    while ($sb.Length -lt ($rows * $cols * 2)) {
        $n++
        $v = $verbs[(Get-Random -Maximum $verbs.Count)]
        $p = $projs[(Get-Random -Maximum $projs.Count)]
        $o = $outcomes[(Get-Random -Maximum $outcomes.Count)]
        $lat = Get-Random -Minimum 40 -Maximum 900
        $tok = Get-Random -Minimum 200 -Maximum 9000
        [void]$sb.Append("Prompt $n" + ": operator asked to $v $p; outcome $o; latency ${lat}ms; tokens $tok. ")
    }
    $filler = $sb.ToString()

    # ---- assemble lines: facts on dedicated lines, filler chunked to column width ----
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("=== CORPUS SNAPSHOT EXPORT [$Label] ===")
    $lines.Add("SNAPSHOT-ID: $snapId   DATE: $date")
    $lines.Add("")

    $fillerPos = 0
    function Take-Filler([int]$count) {
        $script:chunk = $filler.Substring($script:fillerPos, $count)
        $script:fillerPos += $count
        return $script:chunk
    }
    $script:fillerPos = 0

    $factRowStart = [Math]::Floor($rows / 2) - 7
    while ($lines.Count -lt $factRowStart) {
        $lines.Add($filler.Substring($script:fillerPos, $cols)); $script:fillerPos += $cols
    }
    $lines.Add("--- EXACT-VALUE BLOCK ---")
    for ($i = 1; $i -le 10; $i++) {
        $lines.Add(("ID-{0:D2}: {1}" -f $i, $ids[$i-1]))
    }
    $lines.Add("--- END EXACT-VALUE BLOCK ---")
    while ($lines.Count -lt ($rows - 3)) {
        $lines.Add($filler.Substring($script:fillerPos, $cols)); $script:fillerPos += $cols
    }
    $lines.Add("TOTAL-PROMPTS: $totalFmt   REVENUE: `$$revenue")
    $lines.Add("CHECKSUM: $checksum")
    $lines.Add("=== END OF SNAPSHOT EXPORT [$Label] ===")

    # ---- draw ----
    $brush = [System.Drawing.Brushes]::Black
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $y = $margin + ($i * $lineH)
        if ($y + $lineH -gt $H) { break }
        $g.DrawString($lines[$i], $font, $brush, [single]$margin, [single]$y, $fmt)
    }
    $bmp.Save($ImagePath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose(); $font.Dispose()

    $totalChars = ($lines | Measure-Object -Property Length -Sum).Sum
    $imgTokens = [Math]::Ceiling($W * $H / 750)
    [pscustomobject]@{
        Label       = $Label
        FontPx      = $FontPx
        Cols        = $cols
        Rows        = $rows
        Lines       = $lines.Count
        Chars       = $totalChars
        ImageTokens = $imgTokens
        CharsPerImgToken = [Math]::Round($totalChars / $imgTokens, 2)
        EstTextTokens = [Math]::Round($totalChars / 4)
        EstDensityVsText = [Math]::Round(($totalChars / 4) / $imgTokens, 2)
    }
}

$a = New-DenseImage -ImagePath "$OutDir\dense-A-12px.png" -TruthPath "$OutDir\truth-A.txt" -FontPx 12 -Label "A"
$b = New-DenseImage -ImagePath "$OutDir\dense-B-8px.png"  -TruthPath "$OutDir\truth-B.txt" -FontPx 8.5 -Label "B"
$a, $b | Format-Table -AutoSize
"Run output: $OutDir"
