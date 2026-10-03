<#
.SYNOPSIS
  Runs a command and records peak dedicated GPU memory (VRAM) while it runs.

.DESCRIPTION
  1. Samples idle dedicated GPU memory for -IdleSeconds before launching.
  2. Launches the command and samples every -IntervalMs until it exits.
  3. Reports idle, peak, and peak-minus-idle (the model's VRAM cost) for the
     GPU adapter whose usage rose the most (so an integrated GPU is ignored).
  4. Appends one row to results/vram_log.csv and saves the command's output
     to results/logs/<Label>.txt.

  Source: Windows performance counter "GPU Adapter Memory" / "Dedicated Usage",
  read through .NET PerformanceCounter (sub-millisecond reads, unlike Get-Counter,
  which blocks ~1 s per call). Close other GPU programs before running.

.EXAMPLE
  .\scripts\measure_vram.ps1 -Label f16 -Exe C:\path\llama-bench.exe `
    -Arguments '-m models\qwen2.5-3b-f16.gguf -ngl 99 -p 512 -n 128 -r 3'
#>
param(
    [Parameter(Mandatory)] [string] $Label,
    [Parameter(Mandatory)] [string] $Exe,
    [Parameter(Mandatory)] [string] $Arguments,
    [int] $IdleSeconds = 3,
    [int] $IntervalMs = 100
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$category = New-Object System.Diagnostics.PerformanceCounterCategory('GPU Adapter Memory')
$counters = $category.GetInstanceNames() | ForEach-Object {
    New-Object System.Diagnostics.PerformanceCounter('GPU Adapter Memory', 'Dedicated Usage', $_, $true)
}

function Read-Vram {
    # Returns @{ adapterName = bytes } for every GPU adapter.
    $h = @{}
    foreach ($c in $counters) { $h[$c.InstanceName] = [double]$c.NextValue() }
    $h
}

# --- 1. Idle baseline (mean over the idle window) ---
$idleSamples = @()
$end = (Get-Date).AddSeconds($IdleSeconds)
while ((Get-Date) -lt $end) { $idleSamples += , (Read-Vram); Start-Sleep -Milliseconds $IntervalMs }
$adapters = $idleSamples[0].Keys
$idle = @{}; $peak = @{}
foreach ($a in $adapters) {
    $idle[$a] = ($idleSamples | ForEach-Object { $_[$a] } | Measure-Object -Average).Average
    $peak[$a] = $idle[$a]
}

# --- 2. Run the command while polling ---
New-Item -ItemType Directory -Force "$root\results\logs" | Out-Null
$outFile = "$root\results\logs\$Label.txt"
$errFile = "$root\results\logs\$Label.stderr.txt"
$proc = Start-Process -FilePath $Exe -ArgumentList $Arguments -WorkingDirectory $root `
    -NoNewWindow -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
$null = $proc.Handle   # keep the handle so ExitCode is readable after exit
$n = 0
while (-not $proc.HasExited) {
    $cur = Read-Vram; $n++
    foreach ($a in $adapters) { if ($cur[$a] -gt $peak[$a]) { $peak[$a] = $cur[$a] } }
    Start-Sleep -Milliseconds $IntervalMs
}
$proc.WaitForExit()

# --- 3. Pick the adapter that rose the most, report ---
$gpu = $adapters | Sort-Object { $peak[$_] - $idle[$_] } -Descending | Select-Object -First 1
$idleGiB = $idle[$gpu] / 1GB; $peakGiB = $peak[$gpu] / 1GB; $deltaGiB = $peakGiB - $idleGiB

"{0,-12} {1}" -f 'label', $Label
"{0,-12} {1}" -f 'adapter', $gpu
"{0,-12} {1:N3} GiB" -f 'idle', $idleGiB
"{0,-12} {1:N3} GiB" -f 'peak', $peakGiB
"{0,-12} {1:N3} GiB  <- model VRAM cost (peak - idle)" -f 'delta', $deltaGiB
"{0,-12} {1} samples every ~{2} ms, exit code {3}" -f 'sampling', $n, $IntervalMs, $proc.ExitCode
"{0,-12} {1}" -f 'output', $outFile

# --- 4. Append to CSV ---
$csv = "$root\results\vram_log.csv"
if (-not (Test-Path $csv)) { 'timestamp,label,adapter,idle_gib,peak_gib,delta_gib,samples' | Out-File $csv -Encoding utf8 }
('{0},{1},{2},{3:N3},{4:N3},{5:N3},{6}' -f (Get-Date -Format s), $Label, $gpu, $idleGiB, $peakGiB, $deltaGiB, $n) |
    Out-File $csv -Append -Encoding utf8
