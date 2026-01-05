New-Item -ItemType Directory -Force -Name "dist\tmp"
New-Item -ItemType Directory -Force -Name "out"

# windows setup
# Get-ChildItem -Recurse -File -Path "dist" -Filter "*windows-setup.exe" | Copy-Item -Destination "dist\tmp\hiddify-next-setup.exe" -ErrorAction SilentlyContinue
# Compress-Archive -Force -Path "dist\tmp\hiddify-next-setup.exe",".github\help\mac-windows\*.url" -DestinationPath "out\hiddify-windows-x64-setup.zip"
Get-ChildItem -Recurse -File -Path "dist" -Filter "*windows-setup.exe" | Copy-Item -Destination "out\Hiddify-Windows-Setup-x64.exe" -ErrorAction SilentlyContinue
Get-ChildItem -Recurse -File -Path "dist" -Filter "*windows.msix" | Copy-Item -Destination "out\Hiddify-Windows-Setup-x64.msix" -ErrorAction SilentlyContinue


# windows portable
# 确保 libcore 文件已复制到构建输出目录
if (Test-Path "libcore\bin") {
    Write-Host "Copying libcore files to build directory..."
    $libcoreFiles = Get-ChildItem -Path "libcore\bin" -File
    foreach ($file in $libcoreFiles) {
        $destPath = "build\windows\x64\runner\Release\$($file.Name)"
        Copy-Item $file.FullName -Destination $destPath -Force
        Write-Host "✓ Copied $($file.Name)"
    }
}

xcopy "build\windows\x64\runner\Release" "dist\tmp\hiddify-next" /E/H/C/I/Y
xcopy ".github\help\mac-windows\*.url" "dist\tmp\hiddify-next" /E/H/C/I/Y
Compress-Archive -Force -Path "dist\tmp\hiddify-next" -DestinationPath "out\Hiddify-Windows-Portable-x64.zip" -ErrorAction SilentlyContinue

Remove-Item -Path "$HOME\.pub-cache\git\cache\flutter_circle_flags*" -Force -Recurse -ErrorAction SilentlyContinue

echo "Done"