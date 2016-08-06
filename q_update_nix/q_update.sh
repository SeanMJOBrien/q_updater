#!/bin/sh
# ported to bash by meaglyn June 2014.

# --henesua-- 2014 june 26
## change the value of ROOTDIR to reflect your own directory structure

# credit where credit is due
## meaglyn shared this script with henesua because henesua could only figure out half of it
## it is the bash script version of the windows batch file of the original Q_Updater
## niv was helpful in innumerable ways with this as well
## check out his awesome nwn-lib written in ruby. https://github.com/niv/nwn-lib
## try these magic words in your command line if you have ruby: sudo gem install nwn-lib

# most of the comments after this point are relics of the windows batch script


# This is a batch file that utilizes a couple of common, free utilities to mimic
# an automatic updater/downloader system common to MMOs and other games.  This
# allows a NWN persistant world to customize it's content and not require the
# players to manually download and update their files all the time.  All they have
# to do is run this and it will automatically update the HAKs and connect to the
# server.  You don't even have to browse for the server to connect to!

# REGULAR
# This is for players as it just updates the update HAK instead of every HAK.
# You'll need to use the update_full.bat to get the core HAKs.  Your server admin
# should move the update content to their final destination and refresh the core
# haks on a periodic basis (monthly?), at which case you would have your players
# rerun the full update batch file.

# Brian Chung <brianc at bioware dot com> 2008-03-30

# The programs used are:
#
# rsync   - http://rsync.samba.org/
#           Grabbed v2.6.6 protocol version 29 from http://www.cygwin.com/ and extracting
#           only the bare necessities for the environment: rsync.exe, cygwin1.dll, and cygpopt-0.dll
# erf     - http://nwvault.ign.com/View.php?view=Other.Detail&id=279 (by roboius of DLA)

# Set the IP or domain name of the server to connect to, we assume they'd have
# rsync server set up on the same host.
# For some advanced stuff, we could look at passing the server IP to this batch
# file and have it intercept the normal nwmain.exe call?
#
# Obviously, feel free to change it to suit the needs of your NWN PW server!
SERVERHOST=148.251.86.81
# SET SERVERHOST=neverwintervault.org
SERVERURL=http://neverwintervault.org

RSYNC=/usr/bin/rsync

ROOTDIR=`pwd`

# If you have erf installed else where change this
# if you are using one of the other erf packing tools then this does not need to change.
ERF=${ROOTDIR}/erf-1.2/src/erf

# This is used on the HAK filenames to keep them separated from other servers.
# Try to keep odd symbols like [ ] out of this and keep it short to like 2-4 characters
HAKPREFIX=q
HAKDIR=q_production
NOHAK=nohak
NODOWNLOAD=nodownload

# This is if your PW requires certain things to load into the /nwn/override for character creation
# Set to "y" if there is, it will get stored in /nwn/override_HAKPREFIX and moved to the normal
# /nwn/override when running nwmain.exe, and revert back afterwards.
# OVERRIDE=y

FORCE=0

if [ "${1}x" = "forcex" ] ; then
FORCE=1
fi


echo ------------------------------------------------------------------------------
echo ------------------------------------------------------------------------------
echo        NWN Updater for ${HAKPREFIX}
echo ------------------------------------------------------------------------------
echo ------------------------------------------------------------------------------

# TODO - code to make sure we are in the directory we should be.
# this is redundant...
cd ${ROOTDIR}

STAGEDIR=${ROOTDIR}/stage
DSTHAKDIR=${STAGEDIR}/hak

if [ ! -d "${ROOTDIR}/logs" ] ; then 
    mkdir  "${ROOTDIR}/logs"
fi
#IF NOT EXIST logs MKDIR logs

# should clean this up if it exists?
if [ ! -d "${STAGEDIR}" ] ; then 
    mkdir  "${STAGEDIR}"
fi

if [ ! -d "${DSTHAKDIR}" ] ; then 
    mkdir  "${DSTHAKDIR}"
fi




echo .
# First check we're in the rsync folder off the root NWN folder else continue with the
# updating.  We could do some fancy nwn.ini checking for the correct paths and such, but
# honestly, how many people really go around changing where their /nwn/hak/ folder is located?
#IF NOT EXIST ..\nwmain.exe GOTO NONWN
# Else...
#echo NWMAIN.EXE found, continuing with updates...
#echo NWMAIN.EXE found, continuing with updates... > logs/updater.log

sleep 2

echo .
echo ----------------------------------------
echo Update mode : Normal

# Check if the directory exists
if [ ! -d ${ROOTDIR}/${HAKPREFIX} ] ; then 
    echo.
    echo ${ROOTDIR}/${HAKPREFIX} doesn\'t exist, creating...
    echo ${ROOTDIR}/${HAKPREFIX} doesn\'t exist, creating... >> logs/updater.log
    mkdir  ${ROOTDIR}/${HAKPREFIX}
fi

# Sync the base directories
# -d, --dirs                  transfer directories without recursing
echo rsync -d --max-size=4 ${SERVERHOST}::${HAKDIR}/* ${ROOTDIR}/${HAKPREFIX}
rsync -d --max-size=4 ${SERVERHOST}::${HAKDIR}/* ${ROOTDIR}/${HAKPREFIX}


# Cycle every subdirectory and sync it from the main root.
echo .
cd  ${ROOTDIR}/${HAKPREFIX}

for i in *
do 
    if [ ! -d  $i ] ; then 
	continue
    fi

    #  do not download the 'nodownload' directory
    if [ $i = ${NODOWNLOAD} ] ; then 
	continue
    fi

    echo Syncing  ${ROOTDIR}/${HAKPREFIX}/$i
    echo Syncing ${ROOTDIR}/${HAKPREFIX}/$i >> ../logs/updater.log
        # -r          recursive directories
        # -u          skip files that are newer on the receiver
        # -t          preserve times
        # -i          output a change-summary for all updates
        # --progress  Display progress in file downloads, we log this so we know if something's been updated for that HAK
        # --delete    delete files that don't exist on the remote server, keep the dir clear
        # --log-file="%%D.log" output to log file, update rsync so we can skip the piping and display progress to the user 
         echo ${RSYNC} -r -u -t -i --compress --progress --delete --log-file="${i}.log" --exclude=*\.[eE][xX][eE] --exclude=*\.[dD][lL][lL] ${SERVERHOST}::${HAKDIR}/${i} . 
        ${RSYNC} -r -u -t -i --compress --progress --delete --log-file="${i}.log" --exclude=*\.[eE][xX][eE] --exclude=*\.[dD][lL][lL] ${SERVERHOST}::${HAKDIR}/${i} . 2>> ../logs/updater.log
        if [ $? -ne 0 ] ; then 
	    #IF ERRORLEVEL 5 GOTO TIMEOUT
	    echo Connection to ${SERVERHOST} failed, aborting...
	    echo Connection to ${SERVERHOST} failed, aborting... >> ../logs/updater.log
	    #cd ${ROOTDIR}
	    exit 1
	fi
done

echo .
# Next, cycle every log file and check if its filesize is larger than 200 bytes (padding due to any header info in the log).
# More than 200 bytes indicates that something was downloaded.  This separation is used because if a directory had an
# update, we only need to pack that one HAK up, instead of forcing a pack on every HAK, every time even if nothing was
# changed.

for i in *.log 
do 
    # should not happen
    if [ -d  $i ] ; then 
	continue
    fi

    # echo DEBUG: %%D = %%~zD bytes
    echo ... >> ../logs/updater.log
    cat $i >> ../logs/${i}
    FILESIZE=$(stat -c%s "$i")
    FNAME=`echo $i | awk -F"." '{print $1}'`
 
    # COPY %%D ..\logs\
    if [ ${FORCE} -eq 1 -o ${FILESIZE} -ge 200 ] ;   then
        #IF %%~nD==%NOHAK% (
	if [ ${FNAME} = ${NOHAK} ] ; then 
	   cd  ${NOHAK}
	   # go into the subdirectories to prevent stuff from being moved into the NWN root directory
	   #FOR /D %%F IN (*) DO (
	   echo Processing ${NOHAK} directory
	   for f in * 
	   do 
	       echo Processing directory $f
	       echo Copying ${NOHAK}/${f} to ${STAGEDIR}/$f >> ${ROOTDIR}/logs/updater.log
	       # specify the file(type)(s) to be excluded from copying in the q_updater/executable.set
	       if [ ! -d  ${STAGEDIR}/$f ] ; then
		   mkdir  ${STAGEDIR}/$f
	       fi
	       cd $f
	       tar -cf - -X  ${ROOTDIR}/executable.set . | (cd  ${STAGEDIR}/$f && tar -xf -)
	       cd ..
	       #cp $f/*  ${STAGEDIR}/$f/.  /E /Y /EXCLUDE:..\..\executable.set
	   done
	   cd ..

	else
	#IF NOT %%~nD==%NOHAK% (
	    HAKNAME=${HAKPREFIX}_${FNAME}.hak
            echo Packing ${HAKNAME}
            echo Packing ${HAKNAME} >> ..\logs\updater.log
            # Delete the old HAK
	    rm -f ${DSTHAKDIR}/${HAKNAME}

            # Erf up the contents and subdirectories
            # Set the text fields in the HAK so we know which HAK it is supposed to be, as well as when it was last updated and for what server
            # %%~nD = file/folder name (no extension)
            # %DATE%, %TIME% = current date and time
	    cd ${FNAME}

	    # --henesua-- 2014 june 26
	    # since this is linux you have your choice of tools select erf, nwn-erf, or erfpack.pl
	    # erf is default, but the best choice is niv's nwn-erf which actually catches files longer than 16 characters, and as such would probably not even allow comments as ridiculously and needlessly long as this one
	    # erf is fine - it correctly handles the directories and spaces in names using the command below.
	    # the other two may not handle spaces correctly.

            # --henesua-- 2014 june 26
	    # the erf tool needs to be installed. i put mine in /usr/local/bin
	    # Comment this out if using one of the other tools
	    find . -type f  -print0 | while IFS=$'\n' read -r -d '' file; do  echo \"$file\" ; done | xargs -s 393216 ${ERF} -c ${DSTHAKDIR}/${HAKNAME}

	    # --henesua-- 2014 june 26
	    # elven/niv's ruby tools for nwn https://github.com/niv/nwn-lib
	    # http://forum.bioware.com/topic/434537-elvens-nwn-lib/
	    # currently this tool tries to add a folder it finds within a directory as a file
	    # niv is working on a solution
	    # Uncomment this line below (and comment out the erf line above)
	    # nwn-erf -Hcf ${DSTHAKDIR}/${HAKNAME} `find . -type f`

	    # --henesua-- 2014 june 26
	    # kivinen's perl tools for nwn http://www.kivinen.iki.fi/nwn/downloads.html
	    # Uncomment this line below (and comment out the erf line above)
	    # erfpack.pl -v -H -o ${DSTHAKDIR}/${HAKNAME} `find . -type f`

            #dir /s/n/b/a-d %%~nD | ..\erf.exe -c --stdin ..\..\hak\%HAKPREFIX%_%%~nD.hak 2>> ..\logs\updater.log
	    cd ..

	    DATE=`date`
            echo  "NWN ${HAKPREFIX} - ${FNAME} from ${SERVERURL}: Updated on ${DATE}"

            if [ -f  ${DSTHAKDIR}/${HAKNAME} ] ; then
                echo created   ${DSTHAKDIR}/${HAKNAME} successfully
                echo created  ${DSTHAKDIR}/${HAKNAME} successfully >> ..\logs\updater.log
            else
                echo Failed to create   ${DSTHAKDIR}/${HAKNAME}
                echo Failed to create  ${DSTHAKDIR}/${HAKNAME}  >> ..\logs\updater.log
            fi
        fi
    else 
	if [ ${FNAME} = ${NOHAK} ] ; then 
        #IF %%~nD==%NOHAK% (
            echo No changes needed, non-erf files not modified
            echo No changes needed, non-erf files not modified >> ..\logs\updater.log
        else
            echo No changes needed,  ${HAKPREFIX}_${FNAME}.hak not modified
            echo No changes needed,  ${HAKPREFIX}_${FNAME}.hak not modified >> ..\logs\updater.log
	fi
    fi
done

# now handled by nohak subdirectory Update TLK
# echo.
# echo Syncing %HAKPREFIX%/*.tlk
# ..\rsync.exe -r -u -t -i --progress --delete --log-file="%%D.log" %SERVERHOST%::%HAKDIR%/*.tlk . 2>> ..\logs\updater.log
# COPY *.tlk ..\..\tlk


# Clean up, delete the log files
rm *.log

# Back to the main updater directory
cd ..
