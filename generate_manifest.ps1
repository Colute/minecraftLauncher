$folderPath = 'Z:\sborka\main'
$outputJson = Join-Path $folderPath 'manifest.json'
$baseUrlRaw = 'https://raw.githubusercontent.com/Colute/minecraftLauncher/main'
$baseUrlLfs = 'https://media.githubusercontent.com/media/Colute/minecraftLauncher/main'
$defaultVersion = '1.19.2-fabric-0.18.4'

Write-Host 'Примеры форматов версий:' -ForegroundColor Yellow
Write-Host '  Forge:    1.20.1-forge-47.4.28' -ForegroundColor DarkGray
Write-Host '  Fabric:   fabric-loader-0.18.4-1.19.2' -ForegroundColor DarkGray
Write-Host '  NeoForge: 1.20.1-neoforge-47.1.84' -ForegroundColor DarkGray
Write-Host ''

$inputVersion = Read-Host 'Введите версию модлоадера'
if ([string]::IsNullOrWhiteSpace($inputVersion)) {
    $modpackVersion = $defaultVersion
} else {
    $modpackVersion = $inputVersion
}

Write-Host 'Scanning modpack folder...' -ForegroundColor Cyan
$excludeRegex = '\\\.(fabric|mixin\.out|git)\\|\\(logs|saves|modernfix|backups|fancymenu_data|emojiful|fancymenu_setups|downloads)\\'
$files = Get-ChildItem -Path $folderPath -Recurse -File | Where-Object { 
    $_.Extension -ne '.bat' -and 
    $_.Extension -ne '.ps1' -and 
    $_.Name -ne 'manifest.json' -and 
    $_.Name -ne '.gitignore' -and 
    $_.Name -ne 'update.zip' -and 
    $_.Name -ne 'version.txt' -and 
    $_.FullName -notmatch $excludeRegex 
}

$fileList = @()
$sha256 = [System.Security.Cryptography.SHA256]::Create()

foreach ($file in $files) {
    $full = $file.FullName
    $rel = $full.Substring($folderPath.Length).TrimStart([char]92, [char]47).Replace([char]92, [char]47)
    Write-Host "Обработка: $rel" -ForegroundColor DarkGray
    
    $hash = ''
    $attempts = 3
    while ($attempts -gt 0) {
        try {
            $stream = [System.IO.File]::Open($full, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            $hashBytes = $sha256.ComputeHash($stream)
            $stream.Close()
            $hash = ([BitConverter]::ToString($hashBytes) -replace '-','').ToLower()
            break
        } catch {
            $attempts--
            if ($stream) { $stream.Close() }
            if ($attempts -eq 0) {
                Write-Host "ОШИБКА ЧТЕНИЯ ХЕША: $rel" -ForegroundColor Red
            } else {
                Start-Sleep -Milliseconds 100
            }
        }
    }
    
    $encodedRel = ($rel -split '/' | ForEach-Object { [System.Uri]::EscapeDataString($_).Replace('+', '%20') }) -join '/'
    $currentBaseUrl = if ($rel.StartsWith('mods/')) { $baseUrlLfs } else { $baseUrlRaw }
    
    $fileList += [PSCustomObject]@{
        path = $rel
        hash = $hash
        url = ('{0}/{1}' -f $currentBaseUrl, $encodedRel)
    }
}

$sha256.Dispose()
$manifest = [PSCustomObject]@{
    version = $modpackVersion
    files = $fileList
}

$jsonOutput = $manifest | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($outputJson, $jsonOutput, [System.Text.UTF8Encoding]::new($false))
Write-Host 'Done! Manifest generated successfully.' -ForegroundColor Green