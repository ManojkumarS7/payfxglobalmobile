Add-Type -AssemblyName System.IO.Compression
$raw = [System.IO.File]::ReadAllBytes("E:\payuni\payglobal.pdf")
$rawString = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($raw)

$results = @()
$streamMatches = [regex]::Matches($rawString, 'stream[\r\n]([\s\S]*?)[\r\n]?endstream')

foreach ($m in $streamMatches) {
    $streamData = $m.Groups[1].Value
    $streamBytes = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($streamData)
    
    if ($streamBytes.Length -lt 10) { continue }
    
    try {
        $ms = New-Object System.IO.MemoryStream(,$streamBytes[2..($streamBytes.Length-1)])
        $ds = New-Object System.IO.Compression.DeflateStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
        $outMs = New-Object System.IO.MemoryStream
        $ds.CopyTo($outMs)
        $text = [System.Text.Encoding]::ASCII.GetString($outMs.ToArray())
        $ds.Close()
        $outMs.Close()
        
        if ($text -match 'BT[\s\S]*?ET') {
            $results += $text
        }
    } catch { }
}

$results -join "`n"
