== A Few Words on the linux version of the Q updater ==
henesua 2014 june 26
henesua@gmail.com
Packaging and support for nwn-erf and erfpack.pl

meaglyn 2014 
meaglyn.nwn@gmail.com
updates to erf and q_update.sh scripting


=== NOTE ===
You will need to install an erf tool, and configure the script see below for details.


=== (LOOSELY DEFINED) DETAILS ===
q_update.sh is a Bash script. You must run it from within the directory it resides.

the script uses rsync which you should have or easily be able to get

it also does some erf packing which requires special, community made software.
You have three choices for this function:
erf	-- a tarball should have been included in the archive with the script
	- in the tarball is a source directory from which you can make erf.
	- my erf lives in /usr/local/bin. you should be able to simply move it from source to there
	- BUT each's environment may vary

nwn-erf -- elven/niv has an actively supported ruby gem for nwn
	- https://github.com/niv/nwn-lib
	- to install via command line if you have ruby: sudo gem install nwn-lib

erfpack.pl -- kivinen's perl tools for nwn http://www.kivinen.iki.fi/nwn/downloads.html


This tool is different from the windows update tool in that it works in a staging directory
under the expanded archive (Q_Updater_nix/stage). The directory structure under stage is the
same as under a NWN install directory. You can copy all the files into their appropriate places
under your install. 

If you want to install directly you may remove the stage directory (cd Q_Updater_nix; rm -rf stage)
and link to your install directory (ln -s <path to NWN> stage).  



=== COMMENTS ===
I've used all three, and included commands (currently commented out) for each in the script.
erf is the default. if you wish to switch to another, edit the script.

i prefer niv's work because it is still supported.
i caught a bug and he fixed it. woot!
niv's tool also catches bugs in q content (stuff with more than 16 characters)
	which we can give to pstemarie and he can fix the content


=== Building Erf ===

    Make sure you have basic the C development environment installed. For example gcc and glibc development packages 
    -unpack the archive 
    tar -xzf erf-1.2.tgz

    -build the tool
    cd erf-1.2/src
    make

    You may install this somewhere in your path if you wish. The q_update.sh script by default will look for it
    in the erf-1.2/src directory.

=== Running the updater ===

    From the archive directory simply run:
    	     ./q_update.sh 

    If you wish to force build all the haks you can add use:
         ./q_update.sh force

    Forcing is not needed the first time you run it if you are using a clean tree. 
