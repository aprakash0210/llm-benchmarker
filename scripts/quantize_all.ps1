<#
.SYNOPSIS
  Creates every quantized GGUF from the FP16 baseline and reports file sizes.

.DESCRIPTION
  Runs llama-quantize once per level, always from the same FP16 file (the only
  variable that changes is the quantization type). Saves each run's output to
  results/logs/quantize_<type>.txt and appends sizes to results/sizes.csv.

.EXAMPLE
  .\scripts\quantize_all.ps1
#>
param(
    [string] $Bin = 'C:\Users\ayush\OneDrive\Desktop\dev\llama.cpp-vulkan',
    [string] $Source = 'models\qwen2.5-3b-f16.gguf',
    [string[]] $Types = @('Q8_0', 'Q5_K_M', 'Q4_K_M', 'Q2_K')
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
New-Item -ItemType Directory -Force "$root\results\logs" | Out-Null

$srcBytes = (Get-Item $Source).Length
$csv = "$root\results\sizes.csv"
'quant,file,bytes,gib,pct_of_f16,reduction_pct,seconds' | Out-File $csv -Encoding utf8
('F16,{0},{1},{2:N3},100.0,0.0,' -f $Source, $srcBytes, ($srcBytes / 1GB)) | Out-File $csv -Append -Encoding utf8

foreach ($t in $Types) {
    $out = 'models\qwen2.5-3b-{0}.gguf' -f $t.ToLower()
    $sw = [Diagnostics.Stopwatch]::StartNew()
    # llama.cpp logs to stderr; under 'Stop', Windows PowerShell 5.1 would treat that as an error.
    $ErrorActionPreference = 'Continue'
    & "$Bin\llama-quantize.exe" $Source $out $t *> "$root\results\logs\quantize_$t.txt"
    $ErrorActionPreference = 'Stop'
    if ($LASTEXITCODE -ne 0) { throw "llama-quantize failed for $t (exit $LASTEXITCODE); see results\logs\quantize_$t.txt" }
    $sw.Stop()
    $bytes = (Get-Item $out).Length
    $pct = 100 * $bytes / $srcBytes
    '{0,-7} {1,14:N0} bytes  {2,6:N3} GiB  {3,5:N1}% of F16  ({4,4:N1}% smaller)  {5:N1}s' -f $t, $bytes, ($bytes / 1GB), $pct, (100 - $pct), $sw.Elapsed.TotalSeconds
    ('{0},{1},{2},{3:N3},{4:N1},{5:N1},{6:N1}' -f $t, $out, $bytes, ($bytes / 1GB), $pct, (100 - $pct), $sw.Elapsed.TotalSeconds) |
        Out-File $csv -Append -Encoding utf8
}
