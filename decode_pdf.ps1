Add-Type -AssemblyName System.IO.Compression

$bytes = [System.IO.File]::ReadAllBytes("E:\payuni\payglobal.pdf")
$rawString = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($bytes)

# Find and decompress all streams
$streamPattern = 'stream\r?\n([\s\S]*?)\r?\nendstream'
$matches = [regex]::Matches($rawString, $streamPattern)

$allDecompressed = @()
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
        $allDecompressed += $decompressed
        $ds.Close()
        $outMs.Close()
        $ms.Close()
    } catch { }
}

# Find ToUnicode CMap
$cmapContent = ""
foreach ($d in $allDecompressed) {
    if ($d -match 'beginbfchar' -or $d -match 'CIDInit') {
        $cmapContent = $d
        break
    }
}

# Build character mapping
$charMap = @{}
if ($cmapContent -ne "") {
    Write-Host "Found ToUnicode CMap"
    
    # Parse bfchar entries: <sourcecode> <destcode>
    $bfcharMatches = [regex]::Matches($cmapContent, '<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>')
    foreach ($bm in $bfcharMatches) {
        $src = $bm.Groups[1].Value
        $dst = $bm.Groups[2].Value
        $charMap[$src] = $dst
    }
    Write-Host "Loaded $($charMap.Count) character mappings"
}

# Now decode text content
$output = @()
foreach ($d in $allDecompressed) {
    if ($d -match 'BT') {
        # Extract hex strings like <0048> or regular strings
        $hexMatches = [regex]::Matches($d, '<([0-9A-Fa-f]+)>')
        foreach ($hm in $hexMatches) {
            $hex = $hm.Groups[1].Value
            $decoded = ""
            for ($i = 0; $i -lt $hex.Length; $i += 4) {
                if ($i + 4 -le $hex.Length) {
                    $code = $hex.Substring($i, 4)
                    if ($charMap.ContainsKey($code)) {
                        $unicodeHex = $charMap[$code]
                        try {
                            $unicodeChar = [char][Convert]::ToInt32($unicodeHex, 16)
                            $decoded += $unicodeChar
                        } catch { $decoded += "?" }
                    } else {
                        try {
                            $unicodeChar = [char][Convert]::ToInt32($code, 16)
                            $decoded += $unicodeChar
                        } catch { $decoded += "?" }
                    }
                }
            }
            if ($decoded.Length -gt 0 -and $decoded -match '[A-Za-z]') {
                $output += $decoded
            }
        }
    }
}

$result = $output -join " "
$result | Out-File "E:\payuni\pdf_decoded.txt" -Encoding UTF8
Write-Host "=== DECODED TEXT ==="
Write-Host $result
