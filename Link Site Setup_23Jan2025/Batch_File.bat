@echo off

:: Ensure the script runs with administrative privileges
echo Checking for administrative privileges...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Please run this batch file as an administrator.
    pause
    exit /b
)
echo.

:: 1. Install the application silently
echo Running the application installer...
start /wait "" "%~dp0LinkSiteSetup.exe" /silent /norestart /tasks=!desktopicon
if %errorlevel% neq 0 (
    echo Application installation failed. Exiting.
    pause
    exit /b
)

:: 2. Create desktop shortcut manually
echo Creating desktop shortcut...
(
echo try ^{
echo     $desktop = [System.Environment]::GetFolderPath^("Desktop"^);
echo     $shortcutPath = Join-Path $desktop "Link Site.lnk";
echo     $wsh = New-Object -ComObject WScript.Shell;
echo     $shortcut = $wsh.CreateShortcut^($shortcutPath^);
echo     $shortcut.TargetPath = "C:\Program Files (x86)\Link Site\WindowsApp.exe";
echo     $shortcut.WorkingDirectory = "C:\Program Files (x86)\Link Site";
echo     $shortcut.IconLocation = "C:\Program Files (x86)\Link Site\WindowsApp.exe,0";
echo     $shortcut.Save^(^);
echo     Write-Output "Shortcut created successfully.";
echo ^} catch ^{
echo     Write-Output "Failed to create desktop shortcut: $_";
echo     exit 1;
echo ^}
) > CreateShortcut.ps1

echo Check whether a desktop shortcut has been created or not...
PowerShell -ExecutionPolicy Bypass -File CreateShortcut.ps1 > shortcut_debug.log 2>&1
if %errorlevel% neq 0 (
    echo Failed to create desktop shortcut. Check shortcut_debug.log for details.
    pause
) else (
    echo Desktop shortcut created successfully.
)
echo.

:: 3. Copy DLL to system32 folder
echo Copying DLL file to System32 folder based on OS architecture...
:: Detect if the system is 64-bit
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "dllSource=%~dp0win-x64\WebView2Loader.dll"
) else (
    set "dllSource=%~dp0win-x86\WebView2Loader.dll"
)
set "dllDestination=C:\Windows\System32\WebView2Loader.dll"

if exist "%dllSource%" (
    copy /y "%dllSource%" "%dllDestination%" >nul
    if %errorlevel% equ 0 (
        echo DLL file copied successfully from %dllSource%.
    ) else (
        echo Failed to copy the DLL file. Ensure you have the necessary permissions.
        pause
    )
) else (
    echo DLL file not found in the expected location: %dllSource%! Ensure it is in the same directory as this batch file.
    pause
)
echo.

:: Cleanup temporary files
if exist CreateShortcut.ps1 del CreateShortcut.ps1

:: Completion
echo Setup complete. Press any key to exit.
pause