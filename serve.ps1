# BalikinGo - Lightweight Local HTTP Server with Auto-Notification & Sync
$candidatePorts = @(8088, 8089, 8090, 8091, 8092, 8080)
$port = 8088

# Dapatkan IP LAN / Wi-Fi lokal yang aktif (Status = Up)
$activeAdapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" }
$activeIndices = if ($activeAdapters) { $activeAdapters.InterfaceIndex } else { @() }
$ips = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { 
    $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" -and 
    ($activeIndices.Count -eq 0 -or $activeIndices -contains $_.InterfaceIndex)
} | Select-Object -ExpandProperty IPAddress)

$primaryIp = if ($ips -and $ips.Count -gt 0) { $ips[0] } else { "127.0.0.1" }
$wifiProfile = (Get-NetConnectionProfile -ErrorAction SilentlyContinue | Select-Object -First 1).Name
if (-not $wifiProfile) { $wifiProfile = "Wi-Fi Lokal" }

$listener = $null
$started = $false

# Cari port yang bebas dari daftar candidatePorts
foreach ($p in $candidatePorts) {
    # 1. Coba wildcard *
    $testListener = New-Object System.Net.HttpListener
    try {
        $testListener.Prefixes.Add("http://*:$p/")
        $testListener.Start()
        $listener = $testListener
        $port = $p
        $started = $true
        break
    } catch {
        $testListener.Close()
    }

    # 2. Coba wildcard +
    $testListener = New-Object System.Net.HttpListener
    try {
        $testListener.Prefixes.Add("http://+:$p/")
        $testListener.Start()
        $listener = $testListener
        $port = $p
        $started = $true
        break
    } catch {
        $testListener.Close()
    }

    # 3. Coba localhost & 127.0.0.1
    $testListener = New-Object System.Net.HttpListener
    try {
        $testListener.Prefixes.Add("http://localhost:$p/")
        $testListener.Prefixes.Add("http://127.0.0.1:$p/")
        $testListener.Start()
        $listener = $testListener
        $port = $p
        $started = $true
        break
    } catch {
        $testListener.Close()
    }
}

if (-not $started -or $null -eq $listener) {
    Write-Host "Gagal memulai server di semua port yang dicoba ($($candidatePorts -join ', '))." -ForegroundColor Red
    exit 1
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   BalikinGo - Server HP Android & Sinkronisasi Desktop   " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Port Server Aktif: $port" -ForegroundColor Green
Write-Host "Nama Jaringan / Wi-Fi: $wifiProfile" -ForegroundColor Magenta
Write-Host "Pastikan HP dan Laptop terhubung ke Wi-Fi / Hotspot yang SAMA." -ForegroundColor White
Write-Host ""
Write-Host "Buka di HP Android Anda (Ketik alamat atau Scan QR Code di web):" -ForegroundColor Green
foreach ($ip in $ips) {
    Write-Host "  -> http://${ip}:$port/" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Buka di Browser Laptop / Desktop:" -ForegroundColor Green
Write-Host "  -> http://localhost:$port/" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tips di HP: Buka menu Chrome (titik tiga) -> Pilih 'Tambahkan ke Layar Utama'" -ForegroundColor DarkCyan
Write-Host "Tekan Ctrl + C di jendela ini untuk menghentikan server." -ForegroundColor DarkGray
Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray

$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }

# Folder data bersama untuk sinkronisasi antar perangkat
$dataDir = Join-Path $root "data"
if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
}
$dbFile = Join-Path $dataDir "db.json"

# In-memory status & antrean notifikasi real-time
$global:dbVersion = 1
$global:notifCounter = 0
$global:notifications = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))

if (Test-Path $dbFile) {
    try {
        $rawContent = [System.IO.File]::ReadAllText($dbFile, [System.Text.Encoding]::UTF8)
        $parsed = $rawContent | ConvertFrom-Json
        if ($parsed.v) { $global:dbVersion = [int]$parsed.v }
    } catch {}
}

$mime = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".webmanifest" = "application/manifest+json; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $urlPath = $request.Url.LocalPath
        if ($urlPath -eq "/" -or [string]::IsNullOrWhiteSpace($urlPath)) {
            $urlPath = "/index.html"
        }

        # 1. Handle CORS Preflight OPTIONS
        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
            $response.OutputStream.Close()
            $response.Close()
            continue
        }

        # 2. Endpoint: /api/network-info
        if ($urlPath -eq "/api/network-info") {
            $urlList = @()
            foreach ($oneIp in $ips) {
                $urlList += "http://${oneIp}:${port}/"
            }
            if ($urlList.Count -eq 0) {
                $urlList += "http://localhost:${port}/"
            }

            $infoObj = @{
                ip = $primaryIp
                ips = @($ips)
                port = $port
                wifi = $wifiProfile
                url = "http://${primaryIp}:${port}/"
                urls = $urlList
            } | ConvertTo-Json -Depth 4 -Compress
            $infoBytes = [System.Text.Encoding]::UTF8.GetBytes($infoObj)
            $response.ContentType = "application/json; charset=utf-8"
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Cache-Control", "no-cache")
            $response.ContentLength64 = $infoBytes.Length
            $response.OutputStream.Write($infoBytes, 0, $infoBytes.Length)
            $response.StatusCode = 200
            $response.OutputStream.Close()
            $response.Close()
            continue
        }

        # 3. Endpoint: /api/sync (Realtime status & notifikasi untuk HP & Desktop)
        if ($urlPath -eq "/api/sync") {
            $since = 0
            if ($request.QueryString["since"]) {
                [int]::TryParse($request.QueryString["since"], [ref]$since) | Out-Null
            }

            $newEvents = @()
            foreach ($item in $global:notifications) {
                if ($item.id -gt $since) {
                    $newEvents += $item
                }
            }

            $syncObj = @{
                v = $global:dbVersion
                time = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                events = @($newEvents)
            } | ConvertTo-Json -Depth 6 -Compress

            $syncBytes = [System.Text.Encoding]::UTF8.GetBytes($syncObj)
            $response.ContentType = "application/json; charset=utf-8"
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")
            $response.ContentLength64 = $syncBytes.Length
            $response.OutputStream.Write($syncBytes, 0, $syncBytes.Length)
            $response.StatusCode = 200
            $response.OutputStream.Close()
            $response.Close()
            continue
        }

        # 4. Endpoint: /api/notify (Kirim event notifikasi peminjaman/pengembalian)
        if ($urlPath -eq "/api/notify" -and $request.HttpMethod -eq "POST") {
            $encoding = if ($request.ContentEncoding) { $request.ContentEncoding } else { [System.Text.Encoding]::UTF8 }
            $reader = New-Object System.IO.StreamReader($request.InputStream, $encoding)
            $body = $reader.ReadToEnd()
            $reader.Close()

            $notifEvent = $null
            try {
                $notifEvent = $body | ConvertFrom-Json
            } catch {}

            if ($notifEvent) {
                $global:notifCounter = $global:notifCounter + 1
                $notifEvent | Add-Member -MemberType NoteProperty -Name "id" -Value $global:notifCounter -Force
                $notifEvent | Add-Member -MemberType NoteProperty -Name "time" -Value ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) -Force
                
                $global:notifications.Add($notifEvent) | Out-Null
                
                while ($global:notifications.Count -gt 100) {
                    $global:notifications.RemoveAt(0)
                }
                
                $global:dbVersion = $global:dbVersion + 1
            }

            $retObj = @{ ok = $true; id = $global:notifCounter; v = $global:dbVersion } | ConvertTo-Json -Compress
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($retObj)
            $response.ContentType = "application/json; charset=utf-8"
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")
            $response.ContentLength64 = $bytes.Length
            $response.StatusCode = 200
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.OutputStream.Close()
            $response.Close()
            continue
        }

        # 5. Endpoint: /api/db (Sinkronisasi database antar perangkat)
        if ($urlPath -eq "/api/db") {
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")
            
            if ($request.HttpMethod -eq "GET") {
                if (Test-Path $dbFile) {
                    $bytes = [System.IO.File]::ReadAllBytes($dbFile)
                    $response.ContentType = "application/json; charset=utf-8"
                    $response.ContentLength64 = $bytes.Length
                    $response.StatusCode = 200
                    $response.OutputStream.Write($bytes, 0, $bytes.Length)
                } else {
                    $emptyObj = '{"ok":false,"empty":true}'
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($emptyObj)
                    $response.ContentType = "application/json; charset=utf-8"
                    $response.ContentLength64 = $bytes.Length
                    $response.StatusCode = 200
                    $response.OutputStream.Write($bytes, 0, $bytes.Length)
                }
            } elseif ($request.HttpMethod -eq "POST") {
                $encoding = if ($request.ContentEncoding) { $request.ContentEncoding } else { [System.Text.Encoding]::UTF8 }
                $reader = New-Object System.IO.StreamReader($request.InputStream, $encoding)
                $body = $reader.ReadToEnd()
                $reader.Close()

                if (-not [string]::IsNullOrWhiteSpace($body)) {
                    $global:dbVersion = $global:dbVersion + 1
                    try {
                        # Tulis versi server terbaru ke dalam db.json agar konsisten setelah restart
                        $parsedDb = $body | ConvertFrom-Json
                        $parsedDb.v = $global:dbVersion
                        $savedJson = $parsedDb | ConvertTo-Json -Depth 20 -Compress
                        [System.IO.File]::WriteAllText($dbFile, $savedJson, [System.Text.Encoding]::UTF8)
                    } catch {
                        [System.IO.File]::WriteAllText($dbFile, $body, [System.Text.Encoding]::UTF8)
                    }
                }

                $retObj = @{ ok = $true; v = $global:dbVersion } | ConvertTo-Json -Compress
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($retObj)
                $response.ContentType = "application/json; charset=utf-8"
                $response.ContentLength64 = $bytes.Length
                $response.StatusCode = 200
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
            $response.OutputStream.Close()
            $response.Close()
            continue
        }

        # 6. Static files
        $cleanPath = $urlPath.TrimStart("/").Replace("/", [System.IO.Path]::DirectorySeparatorChar)
        $filePath = [System.IO.Path]::Combine($root, $cleanPath)

        if ([System.IO.File]::Exists($filePath)) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { "application/octet-stream" }
            
            $response.ContentType = $contentType
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Cache-Control", "no-cache")

            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentLength64 = $bytes.Length
            if ($request.HttpMethod -ne "HEAD") {
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
            $response.StatusCode = 200
        } else {
            $response.StatusCode = 404
            $err = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
            $response.ContentLength64 = $err.Length
            if ($request.HttpMethod -ne "HEAD") {
                $response.OutputStream.Write($err, 0, $err.Length)
            }
        }
        $response.OutputStream.Close()
        $response.Close()
    } catch {
        # Abaikan error koneksi tertutup mendadak
    }
}
