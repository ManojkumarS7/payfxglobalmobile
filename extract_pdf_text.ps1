Add-Type -AssemblyName System.IO.Compression

$bytes = [System.IO.File]::ReadAllBytes("E:\payuni\payglobal.pdf")
$rawString = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($bytes)

$streamPattern = 'stream\r?\n([\s\S]*?)\r?\nendstream'
$matches = [regex]::Matches($rawString, $streamPattern)

Write-Host "Found $($matches.Count) streams to process"

$allText = @()
$processedCount = 0

foreach ($m in $matches) {
    $streamData = $m.Groups[1].Value
    $streamBytes = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($streamData)
    
    if ($streamBytes.Length -lt 10) { continue }
    
    try {
        $deflatedBytes = $streamBytes[2..($streamBytes.Length-1)]
        $ms = New-Object System.IO.MemoryStream(,$deflatedBytes)
        $ds = New-Object System.IO.Compression.DeflateStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
        $outMs = New-Object System.IO.MemoryStream
        $ds.CopyTo($outMs)
        $decompressed = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($outMs.ToArray())
        
        if ($decompressed -match 'BT') {
            $processedCount++
            $textMatches = [regex]::Matches($decompressed, '\(([^\)\\]*(?:\\.[^\)\\]*)*)\)')
            foreach ($tm in $textMatches) {
                $text = $tm.Groups[1].Value -replace '\\(.)', '$1'
                if ($text.Length -gt 1) {
                    $allText += $text
                }
            }
        }
        
        $ds.Close()
        $outMs.Close()
        $ms.Close()
    } catch {
        # Skip failed streams
    }
}

Write-Host "Processed $processedCount text streams"
Write-Host "Extracted $($allText.Count) text fragments"

$result = $allText -join ""
$result | Out-File "E:\payuni\pdf_text_output.txt" -Encoding UTF8

Write-Host "Output saved to pdf_text_output.txt"
Write-Host ""
Write-Host "=== EXTRACTED TEXT ==="
Write-Host $result
