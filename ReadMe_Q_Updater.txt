Project Q Updater v2.0

This version of the Updater include an alternate .BAT file that is configured to 
force installation of ALL Q content when the file is executed. It should resolve 
any issues people are experiencing with the updater.

Confirmed working on Win 7, Win 8, and Win 8.1

NOTE: The updater does not work using Wine CMD (version 1,4) on Ubuntu 12.04


************************************
INSTALLATION - Over Previous Updater
************************************

1. Unzip the contents of this archive to a folder on your desktop.

2. Delete the /q and /logs folders from the newly created folder.

3. Copy or move the remaining files to the Q_Updater directory in you NWN 
   installation.
   
WARNING: DO NOT DELETE THE /q or /logs FOLDERS FROM YOUR INSTALLATION
         (c:/NeverwinterNights/NWN/Q_Updater). Doing so will force the
         Updater to download ALL Q content again!


*******************************
INSTALLATION - New Installation
*******************************
 
1. Unzip the contents of this archive to the main folder of your NWN installation
   (c:/NeverwinterNights/NWN/)


*******************
RUNNING THE UPDATER
*******************

1. Double click q_update_v20.bat to run the Updater.

2. If you are experiencing issues with the Updater not updating or removing haks,
   use q_force_update.bat instead to download the latest content and update your
   Q installation.

