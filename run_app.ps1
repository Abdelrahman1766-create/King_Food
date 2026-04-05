# PowerShell script to fix APK issue and run app
Write-Host "Fixing APK issue..."

# Build APK
flutter build apk --debug

# Check if APK exists and copy to Flutter expected location
$apkPath = "android\app\build\outputs\apk\debug\app-debug.apk"
$flutterPath = "build\app\outputs\flutter-apk\app-debug.apk"

if (Test-Path $apkPath) {
    Write-Host "APK found, copying to Flutter expected location..."
    
    # Create directory if not exists
    $flutterDir = "build\app\outputs\flutter-apk"
    if (!(Test-Path $flutterDir)) {
        New-Item -ItemType Directory -Path $flutterDir -Force
    }
    
    # Copy APK
    Copy-Item $apkPath $flutterPath -Force
    Write-Host "APK copied successfully!"
    
    # Install on device
    $adbPath = "C:\Users\ihaba\AppData\Local\Android\Sdk\platform-tools\adb.exe"
    & $adbPath -s 330022f0e4597591 install -r $flutterPath
    
    # Start app
    & $adbPath -s 330022f0e4597591 shell am start -n com.example.king_food/com.example.king_food.MainActivity
    
    Write-Host "App installed and started!"
} else {
    Write-Host "APK not found!"
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
