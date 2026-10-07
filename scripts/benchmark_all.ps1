<#
.SYNOPSIS
  Measures speed, VRAM, and perplexity for each quantized GGUF, same settings for all.

.DESCRIPTION
  For each quant type, in order:
    1. llama-bench -ngl 99 -p 512 -n 128 -r 3      (speed: pp512 and tg128, mean +- sd)
    2. scripts\measure_vram.ps1 around the same llama-bench command  (peak VRAM minus idle)
    3. llama-perplexity on the WikiText-2 test file, default settings (context 512)
  Raw output of every step goes to results\logs\<quant>_*.txt; one summary row per quant is
  appended to results\results.csv. Close other GPU programs before running.

.EXAMPLE
  .\scripts\benchmark_all.ps1
  .\scripts\benchmark_all.ps1 -Types Q4_K_M
#>
param(
    [string] $Bin = 'C:\Users\ayush\OneDrive\Desktop\dev\llama.cpp-vulkan',
    [string[]] $Types = @('Q8_0', 'Q5_K_M', 'Q4_K_M', 'Q2_K'),
    [string] $PplFile = 'data\wikitext-2-raw\wiki.test.raw'
)

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$logs = "$root\results\logs"
New-Item -ItemType Directory -Force $logs | Out-Null
$results = "$root\results\results.csv"
if (-not (Test-Path $results)) {
    'timestamp,quant,size_gib,vram_idle_gib,vram_peak_gib,vram_delta_gib,pp512_ts,pp512_sd,tg128_ts,tg128_sd,perplexity,ppl_stderr' |
        Out-File $results -Encoding utf8
}

foreach ($t in $Types) {
    $model = 'models\qwen2.5-3b-{0}.gguf' -f $t.ToLower()
    $benchArgs = "-m $model -ngl 99 -p 512 -n 128 -r 3"
    Write-Host "=== $t ===" -ForegroundColor Cyan

    # 1. Speed (csv output so we can parse it; stderr holds llama.cpp's log lines)
    $ErrorActionPreference = 'Continue'
    $raw = & "$Bin\llama-bench.exe" -m $model -ngl 99 -p 512 -n 128 -r 3 -o csv 2>$null
    $ErrorActionPreference = 'Stop'
    $raw | Out-File "$logs\${t}_bench.txt" -Encoding utf8
    $start = ($raw | Select-String -Pattern '^"?build_commit' | Select-Object -First 1).LineNumber
    if (-not $start) { throw "Could not find the csv header in llama-bench output for $t (see $logs\${t}_bench.txt)" }
    $rows = ($raw[($start - 1)..($raw.Count - 1)] -join "`n") | ConvertFrom-Csv
    $pp = $rows | Where-Object { $_.n_prompt -eq 512 -and $_.n_gen -eq 0 }
    $tg = $rows | Where-Object { $_.n_prompt -eq 0 -and $_.n_gen -eq 128 }
    $sizeGiB = [double](Get-Item $model).Length / 1GB

    # 2. VRAM (wraps the same llama-bench command)
    $ErrorActionPreference = 'Continue'
    & "$root\scripts\measure_vram.ps1" -Label "${t}_vram" -Exe "$Bin\llama-bench.exe" -Arguments $benchArgs | Out-Null
    $ErrorActionPreference = 'Stop'
    $v = Import-Csv "$root\results\vram_log.csv" | Where-Object { $_.label -eq "${t}_vram" } | Select-Object -Last 1

    # 3. Perplexity
    $ErrorActionPreference = 'Continue'
    & "$Bin\llama-perplexity.exe" -m $model -f $PplFile -ngl 99 *> "$logs\${t}_perplexity.txt"
    $ErrorActionPreference = 'Stop'
    $m = Select-String -Path "$logs\${t}_perplexity.txt" -Pattern 'Final estimate: PPL = ([\d.]+) \+/- ([\d.]+)' | Select-Object -Last 1
    if (-not $m) { throw "No perplexity result for $t (see $logs\${t}_perplexity.txt)" }
    $ppl = $m.Matches[0].Groups[1].Value; $err = $m.Matches[0].Groups[2].Value

    $line = '{0},{1},{2:F3},{3},{4},{5},{6:F2},{7:F2},{8:F2},{9:F2},{10},{11}' -f (Get-Date -Format s), $t, $sizeGiB,
        $v.idle_gib, $v.peak_gib, $v.delta_gib, [double]$pp.avg_ts, [double]$pp.stddev_ts, [double]$tg.avg_ts, [double]$tg.stddev_ts, $ppl, $err
    $line | Out-File $results -Append -Encoding utf8
    Write-Host $line
}
