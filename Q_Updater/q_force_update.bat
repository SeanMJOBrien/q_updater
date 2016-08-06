@ECHO OFF

REM This is a batch file that utilizes a couple of common, free utilities to mimic
REM an automatic updater/downloader system common to MMOs and other games.  This
REM allows a NWN persistant world to customize it's content and not require the
REM players to manually download and update their files all the time.  All they have
REM to do is run this and it will automatically update the HAKs and connect to the
REM server.  You don't even have to browse for the server to connect to!

REM REGULAR
REM This is for players as it just updates the update HAK instead of every HAK.
REM You'll need to use the update_full.bat to get the core HAKs.  Your server admin
REM should move the update content to their final destination and refresh the core
REM haks on a periodic basis (monthly?), at which case you would have your players
REM rerun the full update batch file.

REM Brian Chung <brianc at bioware dot com> 2008-03-30

REM The programs used are:
REM
REM rsync   - http://rsync.samba.org/
REM           Grabbed v2.6.6 protocol version 29 from http://www.cygwin.com/ and extracting
REM           only the bare necessities for the environment: rsync.exe, cygwin1.dll, and cygpopt-0.dll
REM erf     - http://nwvault.ign.com/View.php?view=Other.Detail&id=279 (by roboius of DLA)

REM Set the IP or domain name of the server to connect to, we assume they'd have
REM rsync server set up on the same host.
REM For some advanced stuff, we could look at passing the server IP to this batch
REM file and have it intercept the normal nwmain.exe call?
REM
REM Obviously, feel free to change it to suit the needs of your NWN PW server!
SET SERVERHOST=148.251.86.81
REM SET SERVERHOST=neverwintervault.org
SET SERVERURL=http://neverwintervault.org

REM This is used on the HAK filenames to keep them separated from other servers.
REM Try to keep odd symbols like [ ] out of this and keep it short to like 2-4 characters
SET HAKPREFIX=q
SET HAKDIR=q_production
SET NOHAK=nohak
SET NODOWNLOAD=nodownload

REM This is if your PW requires certain things to load into the /nwn/override for character creation
REM Set to "y" if there is, it will get stored in /nwn/override_HAKPREFIX and moved to the normal
REM /nwn/override when running nwmain.exe, and revert back afterwards.
REM SET OVERRIDE=y


ECHO ------------------------------------------------------------------------------
ECHO ------------------------------------------------------------------------------
ECHO        NWN Updater for %HAKPREFIX%
ECHO ------------------------------------------------------------------------------
ECHO ------------------------------------------------------------------------------

IF NOT EXIST logs MKDIR logs

ECHO.
REM First check we're in the rsync folder off the root NWN folder else continue with the
REM updating.  We could do some fancy nwn.ini checking for the correct paths and such, but
REM honestly, how many people really go around changing where their /nwn/hak/ folder is located?
IF NOT EXIST ..\nwmain.exe GOTO NONWN
REM Else...
ECHO NWMAIN.EXE found, continuing with updates...
ECHO NWMAIN.EXE found, continuing with updates... > logs\updater.log

PAUSE

ECHO.
ECHO ----------------------------------------
ECHO Update mode : Normal

REM Check if the directory exists
IF NOT EXIST %HAKPREFIX% (
    ECHO.
    ECHO /nwn/updater/%HAKPREFIX%/ doesn't exist, creating...
    ECHO /nwn/updater/%HAKPREFIX%/ doesn't exist, creating... >> logs\updater.log
    MKDIR %HAKPREFIX%
)

REM Sync the base directories
REM -d, --dirs                  transfer directories without recursing
rsync.exe -d --max-size=4 %SERVERHOST%::%HAKDIR%/* %HAKPREFIX%


REM Cycle every subdirectory and sync it from the main root.
ECHO.
CD %HAKPREFIX%
FOR /D %%D in (*.*) DO (
    REM  do not download the 'nodownload' directory
    IF NOT %%D == %NODOWNLOAD% (
        ECHO Syncing %HAKPREFIX%/%%D...
        ECHO Syncing %HAKPREFIX%/%%D... >> ..\logs\updater.log
        REM -r          recursive directories
        rem -u          skip files that are newer on the receiver
        REM -t          preserve times
        REM -i          output a change-summary for all updates
        REM --progress  Display progress in file downloads, we log this so we know if something's been updated for that HAK
        REM --delete    delete files that don't exist on the remote server, keep the dir clear
        REM --log-file="%%D.log" output to log file, update rsync so we can skip the piping and display progress to the user
        ..\rsync.exe -r -u -t -i --compress --progress --delete --log-file="%%D.log" --exclude=*\.[eE][xX][eE] --exclude=*\.[dD][lL][lL] %SERVERHOST%::%HAKDIR%/%%D . 2>> ..\logs\updater.log
        IF ERRORLEVEL 5 GOTO TIMEOUT
    )
)

ECHO.
REM Next, cycle every log file and check if its filesize is larger than 200 bytes (padding due to any header info in the log).
REM More than 200 bytes indicates that something was downloaded.  This separation is used because if a directory had an
REM update, we only need to pack that one HAK up, instead of forcing a pack on every HAK, every time even if nothing was
REM changed.
FOR %%D IN (*.log) DO (
    REM ECHO DEBUG: %%D = %%~zD bytes
    ECHO ... >> ..\logs\updater.log
    TYPE %%D >> ..\logs\%%D
    REM COPY %%D ..\logs\
    IF %%~zD GTR 20 (
        IF %%~nD==%NOHAK% (
	   CD %NOHAK%
	   REM go into the subdirectories to prevent stuff from being moved into the NWN root directory
	   FOR /D %%F IN (*) DO (
	       ECHO %%F
	       ECHO Copying %NOHAK%\%%F to ..\..\%%F >> ..\..\logs\updater.log
	       REM specify the file(type)(s) to be excluded from copying in the q_updater/executable.set
	       XCOPY %%F\* ..\..\..\%%F /E /Y /EXCLUDE:..\..\executable.set
	   )
	   CD ..
	)
	IF NOT %%~nD==%NOHAK% (
            ECHO Packing /nwn/hak/%HAKPREFIX%_%%~nD.hak
            ECHO Packing /nwn/hak/%HAKPREFIX%_%%~nD.hak >> ..\logs\updater.log
            REM Delete the old HAK
            IF EXIST ..\..\hak\%HAKPREFIX%_%%~nD.hak DEL ..\..\hak\%HAKPREFIX%_%%~nD.hak

            REM Erf up the contents and subdirectories
            REM Set the text fields in the HAK so we know which HAK it is supposed to be, as well as when it was last updated and for what server
            REM %%~nD = file/folder name (no extension)
            REM %DATE%, %TIME% = current date and time
            dir /s/n/b/a-d %%~nD | ..\erf.exe -c --stdin ..\..\hak\%HAKPREFIX%_%%~nD.hak 2>> ..\logs\updater.log
            rem -zt "NWN %HAKPREFIX% - %%~nD" -zu "%SERVERURL%" -zc "Updated on %DATE% %TIME% - "
            IF EXIST ..\..\hak\%HAKPREFIX%_%%~nD.hak (
                ECHO created ..\hak\%HAKPREFIX%_%%~nD.hak successfully
                ECHO created ..\hak\%HAKPREFIX%_%%~nD.hak successfully >> ..\logs\updater.log
            )
            IF NOT EXIST ..\..\hak\%HAKPREFIX%_%%~nD.hak (
                ECHO Failed to create ..\hak\%HAKPREFIX%_%%~nD.hak
                ECHO Failed to create ..\hak\%HAKPREFIX%_%%~nD.hak >> ..\logs\updater.log
            )
        )
    )
    IF NOT %%~zD GTR 20 (
        IF %%~nD==%NOHAK% (
            ECHO No changes needed, ..\ambient\ not modified
            ECHO No changes needed, ..\ambient\ not modified >> ..\logs\updater.log
        )
	IF NOT %%~nD==%NOHAK% (
            ECHO No changes needed, ..\hak\%HAKPREFIX%_%%~nD.hak not modified
            ECHO No changes needed, ..\hak\%HAKPREFIX%_%%~nD.hak not modified >> ..\logs\updater.log
	)
    )
)

REM now handled by nohak subdirectory Update TLK
REM ECHO.
REM ECHO Syncing %HAKPREFIX%/*.tlk
REM ..\rsync.exe -r -u -t -i --progress --delete --log-file="%%D.log" %SERVERHOST%::%HAKDIR%/*.tlk . 2>> ..\logs\updater.log
REM COPY *.tlk ..\..\tlk


REM Clean up, delete the log files
DEL *.log

REM Back to the main updater directory
CD ..


GOTO END

:NONWN
ECHO NWMAIN.EXE not found, aborting...
ECHO NWMAIN.EXE not found, aborting... > logs\updater.log
ECHO please ensure that you have extracted the Q_updater directory directly to the NWN installation folder
GOTO END

:TIMEOUT
ECHO Connection to %SERVERHOST% failed, aborting...
ECHO Connection to %SERVERHOST% failed, aborting... >> ..\logs\updater.log
CD..
GOTO END

:END
PAUSE
REM EOF
