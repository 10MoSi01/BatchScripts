:: Project Name: BatchScripts
:: File: adb-wireless-pair.bat
:: License: Sustainable Use License (SUL), Version 1.0
:: Author: 10MoSi01
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

:: This script was created to somewhat automate the process of manually estabilishing
:: wireless debugging connection between a physical android devices and your development
:: pc.
:: The need to manually connect a device arose when Android Studio failed to pair
:: or find the device on the same network.

:: Usage
:: This file should be ran with admin privilages!
::
:: Path to adb's directory can be assigned/supplied in multiple ways:
::     1. supllied as the first command line parameter.
::     2. assign "adbDir" variable of this script
::     3. script can be ran from adb's directory so "cd" points to it
::     4. provide as input when asked during runtime

:: Troubleshooting
::     1. Make sure that both devices are connected to the same network
::     2. Make sure the IP:PORT provided is correct and is in correct order without any spaces in or around.
::     3. Try disabling MAC randomization for both the android and the development devices.
::         Newer devices usually comes with this setting turned on by default.
::     4. Make sure both devices are discoverable on the network
::         For windows, this can easily be done by setting the network profile type to private
::         or by enabling it the first time when connecting to the network.
::     5. Close Android-Studio, and let the script restart adb when prompted.


@echo off

:: --------------------------------
:: Variables
:: --------------------------------

:: Clear variables
set adbDir="G:\Android\android-sdk\platform-tools"
set adbExe=adb.exe
set adb=
set ipPort=
set pairCode=
set newIpPort=
set androidStudioExe=studio64.exe

:: Env
:: see [https://developer.android.com/tools/variables]
set ADB_TRACE=

:: --------------------------------
:: Initial Setup
:: --------------------------------
:SetupADB
:: Find adb.exe
if exist %adbDir%\%adbExe% (
    :: Script variable
    echo [i] Using %adbExe% at %adbDir%...
    set adb=%adbDir%\%adbExe%
    goto RestartADB
) else if exist %~1\%adbExe% (
    :: Command line argument
    echo [i] Using %adbExe% at %~1...
    set adb=%~1\%adbExe%
    goto RestartADB
) else if exist %cd%\%adbExe% (
    :: Current directory
    echo [i] Using %adbExe% at %cd%...
    set adb=%cd%\%adbExe%
    goto RestartADB
) else (
    :: Not found
    echo [i] Adb not found! Please provide adb's directory path...
    set /p adbDir="[+] adb directory: "
    goto SetupADB
)


:: --------------------------------
:: Restarts ADB
:: Its always a good idea.
:: --------------------------------
:RestartADB
echo.
set /p restartADB="[+] Restart adb? (y/[n]): "
if "%restartADB%"=="" (
    echo [i] Skip restarting adb...
    goto Pair
)
if not "%restartADB%"=="y" if not "%restartADB%"=="Y" (
    echo [i] Skip restarting adb...
    goto Pair
)

echo [i] Restarting adb...

:: Kill adb
echo [i] Killing adb server...
%adb% kill-server
echo [i] Stopping winnat service...
net stop winnat

:: Wait for Android Studio to start adb
FOR /F "tokens=1" %%x IN ('tasklist /NH /FI "IMAGENAME eq %androidStudioExe%"') DO (
    if "%%x"=="%androidStudioExe%" (
        echo [i] Waiting for Android Studio to start ADB daemon...
        timeout /t 2 /nobreak > nul

        :: Check if Android Stdio has started adb by finding the adb.exe process
        FOR /F "tokens=1" %%x IN ('tasklist /NH /FI "IMAGENAME eq %adbExe%"') DO (
            if "%%x"=="%adbExe%" (
                echo [i] Assuming Android Studio has started ADB daemon...
                :: break the loop
                goto Pair
            )
        )

        echo [!] Android Studio failed to start ADB daemon, starting manually...
        :: break the loop
        goto ManualStartAdb
    )
)

:: Manually start adb
:ManualStartAdb
echo [i] Starting winnat service...
net start winnat
echo [i] Starting adb server...
%adb% start-server

:: Done
echo [i] adb has been restarted!


:: --------------------------------
:: Pairs a wireless device
:: --------------------------------

:Pair
echo.
:: Prompt for IP:Port and Pair Code
echo [i] Navigate to (Developer Options > Wireless Debugging > Pair device with pairing code)
set /p ipPort="[+] Enter IP:PORT: "
set /p pairCode="[+] Enter Pair Code: "

:: Pairing the device
echo [i] Pairing device...
%adb% pair %ipPort% %pairCode%
if errorlevel 1 (
    echo [!] Pairing failed!
    :: Wait a second and then continue
    timeout /t 1 /nobreak>nul

    :: Fixes/Troubleshoot
    :: see [https://stackoverflow.com/questions/33316006/adb-error-error-protocol-fault-couldnt-read-status-invalid-argument]
    echo [i] Kindly double-check if the ip:port and pair code entered are correct.
    echo [i] If the input provided was correct, common fixes and troubleshooting can be tries...
    set /p tryFixesAndTroubleshooters="[+] Try common fixes and troubleshooting steps? ([y]/n)"
    if "%tryFixesAndTroubleshooters%"=="" if "%tryFixesAndTroubleshooters%"=="y" if "%tryFixesAndTroubleshooters%"=="Y" (
        goto CommonFixesAndTroubleshooting
    ) else (
        echo [i] Skip common fixes and troubleshooting steps...
        echo.
        echo [i] Please check your inputs and try again.
        goto Pair
    )

)


:: --------------------------------
:: Connects to a wireless device
:: after pairing
:: --------------------------------

:Connect
echo.
:: Prompt for re-entering IP:Port if necessary
echo [i] If the IP Addr or PORT has changed, reenter.
echo     Otherwise, press Enter to use the previous IP:Port.
set /p newIpPort="[+] Re-enter IP:Port (optional, read the notice above): "
if "%newIpPort%"=="" set newIpPort=%ipPort%

:: Establishing connection for wireless debugging
echo [i] Establishing connection, initializing wireless debugging...
%adb% connect %newIpPort%
if errorlevel 1 (
    echo [!] Connection failed!
    :: Wait a second and then continue
    timeout /t 1 /nobreak>nul    
    echo.
    echo [i] Please double-check the IP:Port and try again...
    goto Connect
)
goto ExitSuccess


:: --------------------------------
:: Common Fixes and Troubleshooting
:: --------------------------------

:CommonFixesAndTroubleshooting

:: Restart netsh PortProxy interface
set /p resetPortProxy="[+] Reset PortProxy? (y/[n]) : "
if "%resetPortProxy%"=="y" if "%resetPortProxy%"=="Y" (
    echo [i] Resetting port-proxy interface...
    netsh interface portproxy reset
) else (
    echo [i] Skip reset port-proxy...
)

:: Enable adb verbose track stack
set /p enableAdbTraceAll="[+] Enable adb trace all? ([y]/n)"
if "%enableAdbTraceAll%"=="" if "%enableAdbTraceAll%"=="y" if "%enableAdbTraceAll%"=="Y" (
    set ADB_TRACE=all
) else (
    echo [i] Skip enable adb trace all...
)

:: Continue
goto RestartADB


:: --------------------------------
:: Exit
:: --------------------------------

:ExitSuccess
echo.
echo [i] Wireless debugging setup completed successfully.
pause
exit

:ExitFailure
echo.
echo [!] Wireless debugging setup failed!
pause
exit
