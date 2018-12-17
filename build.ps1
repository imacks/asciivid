$payloadPath = Join-Path $PSScriptRoot -ChildPath 'src/ascii-vid-frames.txt'
if (-not (Test-Path $payloadPath -PathType Leaf))
{
	throw "File not found: $payloadPath"
}

# Compression!
$payload = Get-Content -Path $payloadPath -Raw
$payloadBin = [System.Text.Encoding]::ASCII.GetBytes($payload)
$memStream = New-Object System.IO.MemoryStream
$gzipStream = New-Object System.IO.Compression.GZipStream($memStream, [System.IO.Compression.CompressionMode]"Compress")
$gzipStream.Write($payloadBin, 0, $payloadBin.Length)
$gzipStream.Close()
$payloadCompressBin = $memStream.ToArray()
$gzipStream.Dispose()
$memStream.Dispose()
$payloadCompressBase64 = [System.Convert]::ToBase64String($payloadCompressBin)

# Script template
$tmplPath = Join-Path $PSScriptRoot -ChildPath 'src/delivery-template.ps1'
if (-not (Test-Path $tmplPath -PathType Leaf))
{
	throw "File not found: $tmplPath"
}

$output = Get-Content -Path $tmplPath -Raw
$output = $output.Replace('{{ payload }}', $payloadCompressBase64)
$outputPath = Join-Path $PSScriptRoot -ChildPath 'dist/output.ps1'
$outputDir = Split-Path $outputPath -Parent
if (-not (Test-Path $outputDir))
{
    md $outputDir | Out-Null
}
$output | Set-Content -Path $outputPath -Encoding Ascii

Get-Item $outputPath
