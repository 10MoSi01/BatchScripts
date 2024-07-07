:: Project Name: BatchScripts
:: File: adb-wireless-pair.bat
:: License: Sustainable Use License (SUL), Version 1.0
:: Author: 10MoSo01
:: 
:: This file is part of BatchScripts.
:: 
:: You are free to view, use, and modify this file under the terms of the
:: Sustainable Use License (SUL), Version 1.0. You may not distribute,
:: repackage, or sell this file or any derivative works for any commercial purpose.
:: 
:: For more details, see the LICENSE file in the root directory of this project.
:: 
:: This software is provided "as is", without warranty of any kind.
:: 
:: Encouraged: Use in ways that contribute to social and environmental sustainability.
:: 
:: Full license text available at [link to your LICENSE file or website if applicable].


:: Usage
:: This file should be ran with admin privilages!
::
:: Path to adb's directory can be assigned/supplied in multiple ways:
::     1. supllied as the first command line parameter.
::     2. assign "adbDir" variable of this script
::     3. script can be ran from adb's directory so "cd" points to it
::     4. provide as input when asked during runtime


@echo off

:: Clear variables
set adbDir=
@REM set adbDir="G:\Android\android-sdk\platform-tools"
set adb=
set restartADB=
set ipPort=
set pairCode=
set newIpPort=
set androidStudioExe=studio64.exe

:: Initial Setup
:SetupADB
if exist %adbDir%\adb.exe (
    echo Using adb.exe at %adbDir%...
    set adb=%adbDir%\adb.exe
    goto RestartADB
) else if exist %~1\adb.exe (
    echo Using adb.exe at %~1...
    set adb=%~1\adb.exe
    goto RestartADB
) else if exist %cd%\adb.exe (
    echo Using adb.exe at %cd%...
    set adb=%cd%\adb.exe
    goto RestartADB
) else (
    echo "Adb not found! Please provide adb's the directory path..."
    set /p adbDir="adb directory: "
    goto SetupADB
)


:: --------------------------------
:: Restarts ADB
:: Its always a good idea.
:: --------------------------------
:RestartADB
echo.
set /p restartADB="Restart adb? (y/[n]): "
if "%restartADB%"=="" (
    echo Skip restarting adb...
    goto Pair
)
if not "%restartADB%"=="y" if not "%restartADB%"=="Y" (
    echo Skip restarting adb...
    goto Pair
)

echo Restarting adb...

:: Kill adb
%adb% kill-server
net stop winnat

:: Wait for Android Studio to start adb
FOR /F "tokens=1" %%x IN ('tasklist /NH /FI "IMAGENAME eq %androidStudioExe%"') DO (
    if "%%x"=="%androidStudioExe%" (
        echo Waiting for Android Studio to start ADB daemon...
        timeout /t 2 /nobreak > nul
        goto Pair
    )
)


:: Manually start adb
net start winnat
%adb% start-server
echo adb has been restarted!

:: --------------------------------
:: Pairs a wireless device
:: --------------------------------
:Pair
echo.
:: Prompt for IP:Port and Pair Code
echo "Navigate to (Developer Options > Wireless Debugging > Pair device with pairing code)"
set /p ipPort="Enter IP:PORT: "
set /p pairCode="Enter Pair Code: "

:: Pairing the device
echo Pairing device...
%adb% pair %ipPort% %pairCode%
if errorlevel 1 (
    echo Pairing failed. Please check your inputs and try again.
    goto Pair
)

:: --------------------------------
:: Connects to a wireless device
:: after pairing
:: --------------------------------
:Connect
echo.
:: Prompt for re-entering IP:Port if necessary
echo If the IP Addr or PORT has changed, reenter.
echo Otherwise, press Enter to use the previous IP:Port.
set /p newIpPort="Re-enter IP:Port (optional, read the notice above): "
if "%newIpPort%"=="" set newIpPort=%ipPort%

:: Establishing connection for wireless debugging
echo Establishing connection, initializing wireless debugging...
%adb% connect %newIpPort%
if errorlevel 1 (
    echo Connection failed. Please check your IP:Port and try again.
    goto Connect
)

echo.
echo Wireless debugging setup completed successfully.
pause
exit
