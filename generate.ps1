$folderPath = $PSScriptRoot
$baseUrl = "https://raw.githubusercontent.com/Colute/minecraftLauncher/main"

$minecraftVersion = Read-Host "Enter Minecraft version (e.g. 1.20.1)"
$loader = Read-Host "Enter mod loader (forge / fabric)"
$packVersion = Read-Host "Enter pack version (e.g. 1.0)"

Write-Host "Scanning folder and calculating SHA-256..." -ForegroundColor Cyan

# Получаем ТОЛЬКО файлы (без папок) и сразу исключаем generate.ps1 и manifest.json
$files = Get-ChildItem -Path $folderPath -Recurse -File | Where-Object { 
    $_.Name -ne "manifest.json" -and $_.Name -ne "generate.ps1" 
}

$manifestFiles = @()

foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($folderPath.Length + 1).Replace("\", "/")
    
    # Считаем хэш только для реальных файлов
    $hashObj = Get-FileHash -Path $file.FullName -Algorithm SHA256
    if ($hashObj -and $hashObj.Hash) {
        $hash = $hashObj.Hash.ToLower()
        $size = $file.Length
        $url = "$baseUrl/$relativePath"

        $manifestFiles += [PSCustomObject]@{
            Path = $relativePath
            Hash = $hash
            Size = $size
            Url  = $url
        }
    }
}

$manifest = [PSCustomObject]@{
    Version          = $packVersion
    MinecraftVersion = $minecraftVersion
    Loader           = $loader
    Files            = $manifestFiles
}

$json = $manifest | ConvertTo-Json -Depth 10
Set-Content -Path (Join-Path $folderPath "manifest.json") -Value $json -Encoding utf8

Write-Host "Done! manifest.json generated successfully." -ForegroundColor Green
Read-Host "Press Enter to exit"