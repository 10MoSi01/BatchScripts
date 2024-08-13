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
:: Full license text available at [https://github.com/10MoSi01/BatchScripts/blob/main/LICENSE].


:: --------
:: Info
:: --------
:: This script was created to manually pair and/or connect
:: an android device after Android Studio fails to do so.


:: --------
:: Usage
:: --------
:: This file should be ran with admin privilages!
::
:: Path to adb's directory can be assigned/supplied in multiple ways:
::     1. supllied as the first command line parameter.
::     2. assign "adbDir" variable of this script
::     3. script can be ran from adb's directory so "cd" points to it
::     4. provide as input when asked during runtime


:: --------
:: Troubleshooting
:: --------
::     1. Make sure the script is run with admin privilages.
::     2. Make sure that both devices are connected to the same network
::     3. Make sure the IP:PORT provided is correct and is in correct order without any spaces in or around.
::     4. Try disabling MAC randomization for both the android and the development devices.
::         Newer devices usually comes with this setting turned on by default.
::     5. Make sure both devices are discoverable on the network
::         For windows, this can easily be done by setting the network profile type to private
::         or by enabling it the first time when connecting to the network.
::     6. Close Android-Studio, and let the script restart adb when prompted.
:: --------
:: Additionally methods to try
:: --------
::     1. Disable and then re-enable wireless debugging on android device.
::         Maybe repeat this step several times until the system updates IP:Port.
::     2. Disconnect and then re-connect to the network.
::     3. Incase the android system isn't displaying the updated ip:port,
::        try reopening the settings app.


@echo off

:: --------------------------------
:: Variables
:: --------------------------------

:: Clear variables
set adbDir="G:\Android\android-sdk\platform-tools"
set adbExe=adb.exe
set adb=
set initialMethodChoice=
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

:: Locate adb.exe
:FindADB
if exist %adbDir%\%adbExe% (
    :: Script variable
    echo [i] Using %adbExe% at %adbDir%...
    set adb=%adbDir%\%adbExe%
    goto InitialMethodSelection
) else if exist %~1\%adbExe% (
    :: Command line argument
    echo [i] Using %adbExe% at %~1...
    set adb=%~1\%adbExe%
    goto InitialMethodSelection
) else if exist %cd%\%adbExe% (
    :: Current directory
    echo [i] Using %adbExe% at %cd%...
    set adb=%cd%\%adbExe%
    goto InitialMethodSelection
) else (
    :: Not found
    echo [i] Adb not found! Please provide adb's directory path...
    set /p adbDir="[+] adb directory: "
    goto FindADB
)


:: --------------------------------
:: Initial method selection
:: --------------------------------

:InitialMethodSelection
echo.
echo [i] What to do?
echo     [1] Pair and connect a new device
echo     [2] Connect already paired device

:InitialMethodSelectionSubBloc
set /p initialMethodChoice="[+] Select an operation: "

if "%initialMethodChoice%"=="1" (
    goto RestartADB
) else if "%initialMethodChoice%"=="2" (
    goto Connect
) else (
    echo [i] Invalid choice!
    goto InitialMethodSelectionSubBloc
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
if /i "%restartADB%"=="n" (
    echo [i] Skip restarting adb...
    goto Pair
)
:: continue on to Kill adb...

:: Kill adb
echo [i] Killing adb server...
%adb% kill-server
echo [i] Stopping winnat service...
net stop winnat

:: Wait for Android Studio to start adb
FOR /F "tokens=1" %%x IN ('tasklist /NH /FI "IMAGENAME eq %androidStudioExe%"') DO (
    if "%%x"=="%androidStudioExe%" (
        echo [i] Waiting for Android Studio to start ADB daemon...
        
        :: Wait a while and then continue
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
echo [i] Navigate to (Developer Options ^> Wireless Debugging ^> Pair device with pairing code)
set /p ipPort="[+] Enter IP:PORT: "
set /p pairCode="[+] Enter Pair Code: "

:: Pairing the device
echo [i] Pairing device...
%adb% pair %ipPort% %pairCode%
if errorlevel 1 (
    echo [!] Pairing failed!

    :: Wait a second and then continue
    timeout /t 1 /nobreak>nul

    echo.
    echo [i] Try make sure these requirements are met:
    echo     1. Make sure the script is run with admin privilages.
    echo     2. Make sure that both devices are connected to the same network
    echo     3. Make sure the IP:PORT provided is correct and is in correct order without any spaces in or around.
    echo     4. Try disabling MAC randomization for both the android and the development devices.
    echo         Newer devices usually comes with this setting turned on by default.
    echo     5. Make sure both devices are discoverable on the network
    echo         For windows, this can easily be done by setting the network profile type to private
    echo         or by enabling it the first time when connecting to the network.
    echo     6. Close Android-Studio, and let the script restart adb when prompted.

    echo.
    echo [i] Additionally try these methods:
    echo     1. Disable and then re-enable wireless debugging on android device.
    echo         Maybe repeat this step several times until the system updates IP:Port.
    echo     2. Disconnect and then re-connect to the network.
    echo     3. Incase the android system isn't displaying the updated ip:port,
    echo        try reopening the settings app.
    
    echo.

    :: Fixes/Troubleshoot
    :: see [https://stackoverflow.com/questions/33316006/adb-error-error-protocol-fault-couldnt-read-status-invalid-argument]
    echo [i] Kindly double-check if the ip:port and pair code entered are correct.
    echo [i] If the input provided was correct and the issue still persits,
    echo     common fixes and troubleshooting can be tried...
    set /p tryFixesAndTroubleshooters="[+] Try common fixes and troubleshooting steps? ([y]/n): "
    if "%tryFixesAndTroubleshooters%"=="" (
        goto CommonPairFixesAndTroubleshooting
    ) else if /i "%tryFixesAndTroubleshooters%"=="y" (
        goto CommonPairFixesAndTroubleshooting
    ) else (
        echo [i] Skip common fixes and troubleshooting steps...
        echo.
        echo [i] Please check your inputs and try again.
        goto Pair
    )

) else (
    echo [i] Device paired successfully!
)


:: --------------------------------
:: Connects to a wireless device
:: after pairing
:: --------------------------------

:Connect
echo.
:: Prompt for re-entering IP:Port if necessary
if "%initialMethodChoice%"=="1" (
    :: Pairing and connecting to a new device
    echo [i] If the IP Addr or PORT has changed, reenter.
    echo     Otherwise, press Enter to use the previous IP:Port.
    set /p newIpPort="[+] Re-enter IP:Port (optional, read the notice above): "
    if "%newIpPort%"=="" (
        echo [i] Reusing pair IP:Port %ipPort%...
        set newIpPort=%ipPort%
    )
) else (
    :: Connecting to a previously paired device
    setlocal enabledelayedexpansion
    set /p newIpPort="[+] Enter IP:Port : "
    @REM if "%newIpPort%"=="" (
    if "!newIpPort!"=="" (
        echo [i] Invalid input!
        goto Connect
    )
)

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
) else (
    goto ExitSuccess
)


:: --------------------------------
:: Common Fixes and Troubleshooting
:: --------------------------------

:CommonPairFixesAndTroubleshooting

:: Restart netsh PortProxy interface
set /p resetPortProxy="[+] Reset PortProxy? ([y]/n) : "
if "%resetPortProxy%"=="" (
    goto ResetPortProxy
) else if /i "%resetPortProxy%"=="y" (
    goto ResetPortProxy
) else (
    echo [i] Skip reset port-proxy...
    goto EnableAdbTraceAll
)

:ResetPortProxy
echo [i] Resetting port-proxy interface...
netsh interface portproxy reset

:: Enable adb verbose track stack
:EnableAdbTraceAll
set /p enableAdbTraceAll="[+] Enable adb trace all? ([y]/n)"
if "%enableAdbTraceAll%"=="" (
    echo [i] Enabling adb trace all...
    set ADB_TRACE=all
) else if /i "%enableAdbTraceAll%"=="y" (
    echo [i] Enabling adb trace all...
    set ADB_TRACE=all
) else (
    echo [i] Skip enable adb trace all...
)

:: Continue
::  Common Fixes and Troubleshooting is
::  only executed when Pair fails and
::  restarting adb is both 1). part of
::  the troubleshooting and 2). continues
::  the script execution flow into Pair.
goto RestartADB


:: --------------------------------
:: Exit
:: --------------------------------

:ExitSuccess
echo.
echo [i] Wireless debugging setup completed successfully.
pause
goto NoExitEnd

:ExitFailure
echo.
echo [!] Wireless debugging setup failed!
pause
goto NoExitEnd

:NoExitEnd
:: If the script is ran through a command prompt or shell,
:: we don't want to close it by calling exit
:: exit
echo.
