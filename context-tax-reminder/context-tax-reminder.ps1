# UserPromptSubmit hook: context-window readout + a /clear reminder.
#
# The problem it solves: a long session quietly gets expensive, and the moment your
# topic changes, every token of old context is tax with no value. Nobody remembers to
# clear at the right time - so this hands that rule to the machine. The hook detects no
# topic switch itself; that is the model's judgment. It keeps the rule salient deep into
# long sessions, where top-of-context instructions fade, and puts a real number on it.
#
# Two channels, deliberately split:
#   systemMessage      -> YOUR terminal. Fires EVERY prompt. The number and the band.
#   additionalContext  -> the MODEL's context. Silent below the first band, so a rule
#                         about frugality does not itself cost tokens on every turn.
# That split is the part worth stealing: Claude Code's own footer hint talks to you.
# This talks to the agent, so the agent can raise it when your prompt changes topic.
#
# BANDS - these are one operator's working numbers on a 1-million-token window, not a
# published spec. Retune them for how you actually work; they are the two constants at
# the top of the script:
#   under 100k   - normal working depth. Leave it alone; clearing costs more than it saves.
#   100k - 200k  - clear at the next natural stopping point.
#   over 200k    - the model leans on its own summaries instead of the actual files.
#                  Finish the thought you are in, then clear.
# The bands are absolute token counts, not fractions, so they hold whatever the window
# is - the nag never depends on the window being known. Only the percentage does.
#
# The token figure is the newest assistant record's `usage` block in the transcript
# - input + cache_creation + cache_read + output is what was resident on the last
# API call. If it cannot be read the hook stays silent rather than estimating.
#
# The window size is resolved DETERMINISTICALLY, never inferred from magnitude:
# the transcript records the live model ("claude-opus-5"), settings.json records
# the configured one ("opus[1m]"). Same family => the configured [1m] tag applies
# and the percentage is exact. Different family, or a recorded model change, and
# the window is genuinely unknown - so the percentage is DROPPED and the raw token
# count shown alone. A model change fires the notice exactly once, at the change.

$bandClearSoon = 100000      # enter the "clear at the next natural stopping point" band
$bandClearNow  = 200000      # enter the "finish the thought, then clear" band
$stateDir = Join-Path $PSScriptRoot 'state'

try {
    $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
    exit 0
}

$transcript = $payload.transcript_path
if (-not $transcript -or -not (Test-Path -LiteralPath $transcript)) { exit 0 }
$size = (Get-Item -LiteralPath $transcript).Length

function Read-TranscriptTail {
    # Transcripts run to tens of MB; a full parse would blow the 5s hook timeout.
    # The newest assistant record is at the end, so only the tail is read.
    param([string]$Path, [long]$Size)

    $tailBytes = [int][Math]::Min($Size, 1MB)
    if ($tailBytes -le 0) { return $null }
    $fs = $null
    try {
        $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open,
                                     [System.IO.FileAccess]::Read,
                                     [System.IO.FileShare]::ReadWrite)
        $null = $fs.Seek(-$tailBytes, [System.IO.SeekOrigin]::End)
        $buf = New-Object byte[] $tailBytes
        $read = $fs.Read($buf, 0, $tailBytes)
        $text = [System.Text.Encoding]::UTF8.GetString($buf, 0, $read)
    } catch {
        return $null
    } finally {
        if ($fs) { $fs.Dispose() }
    }

    $lines = $text -split "\r?\n"
    # When the tail is a slice, its first line is a fragment of a longer record.
    if ($tailBytes -lt $Size -and $lines.Count -gt 1) { $lines = $lines[1..($lines.Count - 1)] }

    $result = @{ Tokens = $null; Model = $null; ModelsSeen = @() }
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        $line = $lines[$i].Trim()
        if (-not $line -or $line -notmatch '"usage"') { continue }
        try { $o = $line | ConvertFrom-Json } catch { continue }
        $u = $o.message.usage
        if (-not $u) { continue }
        $sum = 0
        foreach ($f in 'input_tokens', 'cache_creation_input_tokens', 'cache_read_input_tokens', 'output_tokens') {
            $v = $u.$f
            if ($v -is [int] -or $v -is [long] -or $v -is [double]) { $sum += [long]$v }
        }
        if ($sum -le 0) { continue }
        $model = $o.message.model
        if ($null -eq $result.Tokens) { $result.Tokens = $sum; $result.Model = $model }
        if ($model -and $result.ModelsSeen -notcontains $model) { $result.ModelsSeen += $model }
    }
    return $result
}

function Get-ModelFamily {
    # "claude-opus-5" -> opus ; "opus[1m]" -> opus ; unrecognized -> $null
    param([string]$Model)
    if (-not $Model) { return $null }
    $m = ($Model.ToLowerInvariant()) -replace '\[[^\]]*\]', ''
    foreach ($f in 'opus', 'sonnet', 'haiku', 'fable') {
        if ($m -match "(^|[^a-z])$f([^a-z]|`$)") { return $f }
    }
    return $null
}

function Format-Tokens {
    # Rounds DOWN, always. 99,999 must not render as "100.0k" - it would read as the
    # next band, and this number gets spoken on camera. Never overstate a count.
    param([long]$N)
    if ($N -ge 1000000) { return ('{0:n1}M' -f ([Math]::Floor($N / 100000) / 10)) }
    if ($N -ge 1000) { return ('{0:n1}k' -f ([Math]::Floor($N / 100) / 10)) }
    return "$N"
}

function Format-Band {
    # Band edges are round by construction - render them without decimal noise.
    param([long]$N)
    if ($N -ge 1000000) { return "$([Math]::Round($N / 1000000))M" }
    return "$([Math]::Round($N / 1000))k"
}

$tail = Read-TranscriptTail -Path $transcript -Size $size
if (-not $tail -or $null -eq $tail.Tokens) { exit 0 }
$tokens = [long]$tail.Tokens
$liveModel = $tail.Model

# --- configured model, from the settings file that owns it -------------------
# USERPROFILE is Windows-only; $HOME covers macOS/Linux. Without the guard this block
# writes two PowerShell binding errors to stderr on any machine where USERPROFILE is
# unset - the hook still works, but a hook that prints errors reads as broken.
$configuredModel = $null
$claudeHome = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
$settingsPath = if ($claudeHome) { Join-Path $claudeHome '.claude/settings.json' } else { $null }
if ($settingsPath -and (Test-Path -LiteralPath $settingsPath)) {
    try { $configuredModel = (Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json).model } catch { }
}

$liveFamily = Get-ModelFamily $liveModel
$confFamily = Get-ModelFamily $configuredModel
$window = if ($configuredModel -match '\[1m\]') { 1000000 } else { 200000 }
$windowKnown = ($liveFamily -and $confFamily -and $liveFamily -eq $confFamily)
# Most people never set "model" in settings.json, so say THAT rather than comparing the
# live model against an empty string - which is what the raw message did, and it reads
# as a bug on a first run.
$unknownReason =
    if ($windowKnown) { $null }
    elseif (-not $configuredModel) { "no `"model`" is set in your .claude/settings.json, so the window size cannot be derived - set one to get a percentage" }
    else { "the live model '$liveModel' does not match the configured '$configuredModel'" }
$unknownShort = if ($windowKnown) { $null } elseif (-not $configuredModel) { 'no model in settings.json' } else { 'model/settings mismatch' }
# A count above the resolved window falsifies it outright - never paper over that.
if ($windowKnown -and $tokens -gt $window) {
    $windowKnown = $false
    $unknownReason = "the count exceeds the $(Format-Tokens $window) window implied by the configured '$configuredModel', which falsifies it"
    $unknownShort = 'count exceeds the configured window'
}

# --- model-change detection: deterministic, and fires exactly once -----------
$modelChanged = $false
$previousModel = $null
if ($payload.session_id -and $liveModel) {
    try {
        if (-not (Test-Path -LiteralPath $stateDir)) {
            New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
        }
        $safeId = ($payload.session_id -replace '[^A-Za-z0-9\-]', '')
        $stateFile = Join-Path $stateDir "model-$safeId.txt"
        if (Test-Path -LiteralPath $stateFile) {
            $previousModel = (Get-Content -LiteralPath $stateFile -Raw).Trim()
            if ($previousModel -and $previousModel -ne $liveModel) { $modelChanged = $true }
        } elseif ($tail.ModelsSeen.Count -gt 1) {
            # No prior state, but the tail itself holds more than one model - the
            # switch happened before this hook first ran in the session.
            $previousModel = ($tail.ModelsSeen | Where-Object { $_ -ne $liveModel } | Select-Object -First 1)
            $modelChanged = $true
        }
        Set-Content -LiteralPath $stateFile -Value $liveModel -NoNewline
        Get-ChildItem -LiteralPath $stateDir -Filter 'model-*.txt' -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-14) } |
            Remove-Item -Force -ErrorAction SilentlyContinue
    } catch { }
}

# --- which band are we in ----------------------------------------------------
$band = if ($tokens -ge $bandClearNow) { 3 } elseif ($tokens -ge $bandClearSoon) { 2 } else { 1 }
$fill = Format-Tokens $tokens
$reading = if ($windowKnown) { "$fill / $(Format-Tokens $window) ($([math]::Round($tokens / $window * 100))%)" } else { "$fill tokens" }

# --- the operator's line: every prompt ---------------------------------------
# The line renders dim, directly under the prompt you just typed, and scrolls away in a
# second. A leading marker is the difference between an instrument and terminal exhaust.
#
# THE MARKER IS PURE ASCII ON PURPOSE. A unicode flag was tried first and reached the
# transcript as a literal '?'. It passed every local test - powershell.exe writes correct
# UTF-8 when its stdout is a file - but not the path Claude Code actually uses, where the
# child's stdout encoding falls back to the console codepage and anything above 0x7F is
# replaced. Change it if you like, but test it end to end: check your own transcript, not
# just what the script prints in a terminal. Those are two different encodings.
$marker = '>>'
switch ($band) {
    3 { $userLine = "$marker Context: $reading - past $(Format-Band $bandClearNow): finish the thought, then clear" }
    2 { $userLine = "$marker Context: $reading - clear at the next natural stopping point" }
    default { $userLine = "$marker Context: $reading" }
}
# The full reason goes to the model (below), which has room for it. Here it would swamp
# a readout whose whole job is to be scannable, so you get the short form.
if (-not $windowKnown) { $userLine += " - no % ($unknownShort)" }

# --- the model's line: only when a band or a model change says to speak ------
$cases = "If this prompt opens a new topic the conversation above does not serve, say so and recommend /clear now - a topic change makes even a light context all tax. If the task just finished, recommend it at this natural stopping point. Mid-burst, stay silent."
$noPct = if ($windowKnown) { "" } else { " The window is unknown because $unknownReason - report the raw count with NO percentage." }
$modelLine = $null

if ($modelChanged) {
    $modelLine = "MODEL CHANGE (deterministic, from the transcript): the live model changed from '$previousModel' to '$liveModel'. settings.json is configured for '$configuredModel', so the context-window size can no longer be derived from it and the percentage has been dropped. Tell the operator plainly that the model changed, report the raw count ($fill tokens) with NO percentage, and recommend he either update the configured model or accept a raw-count-only readout for the rest of this session. Do not estimate a window. The bands still apply: this session is in band $band."
} elseif ($band -eq 3) {
    $modelLine = "Context check - the session is at $reading, past the $(Format-Band $bandClearNow) band where the model starts leaning on its own summaries instead of the actual files. $cases Past this band, do not wait long: finish the thought in progress, then recommend clearing right away. State the figure when you raise it.$noPct"
} elseif ($band -eq 2) {
    $modelLine = "Context check - the session is at $reading, in the $(Format-Band $bandClearSoon)-$(Format-Band $bandClearNow) band. $cases State the figure when you raise it.$noPct"
}

$out = @{ systemMessage = $userLine }
if ($modelLine) {
    $out.hookSpecificOutput = @{
        hookEventName     = 'UserPromptSubmit'
        additionalContext = $modelLine
    }
}
$out | ConvertTo-Json -Depth 5 -Compress
