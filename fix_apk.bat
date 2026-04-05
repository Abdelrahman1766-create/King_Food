@echo off
echo Fixing APK issue...

REM Build APK
flutter build apk --debug

REM Copy APK to Flutter expected location
if exist "android\app\build\outputs\apk\debug\app-debug.apk" (
    echo APK found, copying to Flutter expected location...
    if not exist "build\app\outputs\flutter-apk" mkdir "build\app\outputs\flutter-apk"
    copy "android\app\build\outputs\apk\debug\app-debug.apk" "build\app\outputs\flutter-apk\app-debug.apk"
    echo APK copied successfully!
    
    REM Install on device
    adb -s 330022f0e4597591 install -r "build\app\outputs\flutter-apk\app-debug.apk"
    
    REM Start app
    adb -s 330022f0e4597591 shell am start -n com.example.king_food/com.example.king_food.MainActivity
    
    echo App installed and started!
) else (
    echo APK not found!
)

pause
