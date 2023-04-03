#1/bin/sh

# Welcome to the DS Clinet Install. 
# Note that this script does NOT uninstall. 
# For an effective and final uninstallation, 
# use 'rm -rf'.

# This script does the following:
#       1. Check the arguments passed and permisions
#       2. find space and create Install Dir
#       3. Asks the users for Compatability Mode
#       4. Pre Install Mode check if an install exist
#       5. Start Copying Files to the Install Dir
#       7. Post Install Mode
#       8. Copy installer log to log folder

#The Version and Year will be replace by the build.xml
VERSION="21.1.0.2758"
YEAR_RELEASE="2021"

CLIENT_EXT="Client.bin"
BIN_FILE_NAME="DS$YEAR_RELEASE$CLIENT_EXT"
ARGUMENT_OPTION="\nPlease Run : $BIN_FILE_NAME -- [-h] [-help] [-silent] [-is:log <filename>] [-P dsclient.installLocation=<path>] [Port@HostName]\n
            ............... -h, -help - this help.\n
            ............... -silent - install the product in silent mode.\n
            ............... -is:log - installation log file.\n
            ............... -P dsclient.installLocation - installation directory for LicensePack and Discovery Studio.\n
            ...............  Port@HostName -  port and hostname of the licence server."

shopt -s expand_aliases
alias echoe="echo -e"

DS_CLIENT_NAME="DiscoveryStudio$YEAR_RELEASE"
WELCOME_NOTE="=============================================================\n 
                Welcome to BIOVIA Discovery Studio Client $YEAR_RELEASE Installation. \n \n 
                BIOVIA Discovery Studio $YEAR_RELEASE \n 
                Dassault Systèmes \n 
                https://www.3ds.com/products-services/biovia\n============================================================="
CONSOLE_ARG=""
SILENT_ARG=""
LOG_ARG=""
PORT_AT_HOST_ARG=""
OTHER_ARGS=""
INSTALL_DIR_ARG=""
CONSOLE_MODE="y"
CURRENT_DIR=$(pwd)
SILENT_MODE="n"
LOG_FILE="dsclientinstall.log"
#LOG_FILE_NAME="/tmp/$LOG_FILE"
if [[ -z "$TMPDIR" ]]; then
  LOG_FILE_NAME="/tmp/$LOG_FILE"
else
  LOG_FILE_NAME="$TMPDIR/$LOG_FILE"
fi
INSTALL_DIR=
DEFAULT_INSTALL_DIR="$HOME/BIOVIA/$DS_CLIENT_NAME"
THREE_OPTION_LIST="\nType the number associated with your choice: \n\n     [1] Yes \n     [2] No \n     [3] Cancel "
TWO_OPTION_LIST="\nType the number associated with your choice: \n\n     [1] Yes \n     [2] No \n"
DS_MESSAGE="BIOVIA $DS_CLIENT_NAME "
VERBOSE="--verbose"
DESKTOP_PATH="$HOME/Desktop"
DESKTOP_FILE_NAME="discoverystudio$YEAR_RELEASE.desktop"
PREVIOUS_INSTALL=""

createDeskTopFileContent(){
        DESKTOP_SHORTCUT_FILE_CONSTENT="[Desktop Entry]\nEncoding=UTF-8\nVersion=1.0\nType=Application\nPath=$1\nExec=$1/bin/$DS_CLIENT_NAME\nIcon=$1/share/PluginDescriptors/Icons/Container/appicon.png\nTerminal=false\nName=Discovery Studio $YEAR_RELEASE Client\nGenericName=$DS_CLIENT_NAME\nComment=BIOVIA Discovery Studio $YEAR_RELEASE\nCategories=GTK;GNOME;Utility;\n"
}

splitString(){
    STRING_TO_SPLIT=$1
    IFS=$2 read -a SPLIT_ARRAY <<< "${STRING_TO_SPLIT}"
}

DoPrompt()
{
    PROMPT=$1
    PROMPTDEFAULT=$2
    RESTRICTION=$3
    TAKENULL=$4 
    INPUTLOOP=1
    INPUT=
    while [ $INPUTLOOP -gt 0 ]; do
        echoe "$PROMPT"
        echo -n ">>>"
        if [ -n "$PROMPTDEFAULT" ]; then
            echo -n "["
            echo -n "$PROMPTDEFAULT"
            echo -n "]"
        fi
        #read -e INPUT
        read -p " " INPUT
        if [ -z "$INPUT" -a -n "$PROMPTDEFAULT" ]; then
            INPUT=$PROMPTDEFAULT
        fi
        INPUTLOOP=0

        if [ -n "$RESTRICTION" ]; then
            echo $INPUT | grep -E "$RESTRICTION" > /dev/null 2>>$LOG_FILE_NAME   
            GREPRESULT=$?
            if [[ -n $TAKENULL ]]  &&  [[ -z $INPUT ]] ; then #check if we can take null inputs from user 
                INPUT=1
            elif [ $GREPRESULT -gt 0 ]; then
                echoe "==================================================\nRetry input: [$INPUT] is INVALID"
                INPUT=
                INPUTLOOP=1
            fi
            
        fi
    done
}

logMessage(){
    if [ -n "$1" ] ; then
        echoe "$(date '+%Y %b %d %H:%M') [INFO]  --> $1" >> $LOG_FILE_NAME 
    elif [ -n "$2" ]; then 
        echoe "$(date '+%Y %b %d %H:%M') [ERROR] --> $2" >> $LOG_FILE_NAME 
    fi
}

ExiteInstall(){

    if [ $2 -eq 0 ] ; then 
        echoe "$1\nCheck log file [ $LOG_FILE_NAME ] for more information. Return code: $2" | tee -a $LOG_FILE_NAME
        # no need of clean Up
        exit 0
    else 
        cleanUpOnFailed
        echoe "$1\n. Return code: $2" 
        exit $2
    fi 

}

checkIfPathHasDisStudio(){

        echo "${INSTALL_DIR}" | grep "\/${DS_CLIENT_NAME}$" > /dev/null
        if [ $? -eq 0 ]; then
                logMessage "found $DS_CLIENT_NAME inside the file path : $INSTALL_DIR"
                PATH_CHECK="0";
        else 
                logMessage "cannot find $DS_CLIENT_NAME inside the file path : $INSTALL_DIR"
                PATH_CHECK="1";
        fi

        # SIZE_OF_FILE_PATH=${#INSTALL_DIR}
        # if [ $SIZE_OF_FILE_PATH -gt 19 ] || [ $SIZE_OF_FILE_PATH -eq 19 ] ; then
        #     LAST_10_CHAR=$(echo $INSTALL_DIR | tail -c 20)
        #     if [[ $LAST_10_CHAR == *"DiscoveryStudio"* ]] ; then 
        #         logMessage "found DiscoveryStudio inside the file path : $INSTALL_DIR"
        #         PATH_CHECK="0";
        #     else
        #          PATH_CHECK="1";
        #     fi 
        # else 
        #      PATH_CHECK="1";
        # fi
}

#Check if the required Information needed for the script to run is present
getInstallDir(){

#Check if Home Dir exist and has permitions to install, if not get the Install Dir from the User.
if [ -d $HOME ] && [ -w $HOME ] && [ $SILENT_MODE = "n" ]; then
    DoPrompt  "\n$DS_MESSAGE install location. \nDestination Directory ==> $DEFAULT_INSTALL_DIR \nDo you wish to install to this location ? $THREE_OPTION_LIST" "1" "^[0-3]+$" "TAKENULL"

    if [ $INPUT -eq 1 ] || [ $INPUT -eq 0 ] ; then  
         echoe "\n\n$DS_MESSAGE will be installed in the following location: $DEFAULT_INSTALL_DIR"
         INSTALL_DIR=$DEFAULT_INSTALL_DIR
         # mkdir -p $VERBOSE "$INSTALL_DIR" >> $LOG_FILE_NAME 2>> $LOG_FILE_NAME
         
    elif [ $INPUT -eq 2 ] ; then
        
        while [  -z  $INSTALL_DIR ] ; do
             DoPrompt  "\nEnter destination directory to install: " "" "^(/[^/ ]*)+/?$" ""
             INSTALL_DIR="$INPUT"           
             DoPrompt  "\n$DS_MESSAGE will be installed in the following location: \n$INSTALL_DIR $TWO_OPTION_LIST" "1" "[1-2]+$" "TAKENULL"        
             if [  $INPUT -eq 1 ] ; then
                if [ -d $INSTALL_DIR ] ; then
                    if [ ! -w $INSTALL_DIR ] ; then                 
                            ExiteInstall "Please check if directory exist or set the File permission to write and execute directory: $INSTALL_DIR" 1                       
                    fi
                 else
                    mkdir -p $VERBOSE "$INSTALL_DIR" >> $LOG_FILE_NAME 2>> $LOG_FILE_NAME  
                 fi
             else 
                INSTALL_DIR=
             fi        
        done   
    else
        ExiteInstall "User cancelled installation" 1
    fi    
fi    

}

cpFiles(){
    LOG_CP_MESSAGE="Copying $(find $2 -type f | wc -l) files to $3"
    echoe "$LOG_CP_MESSAGE Please wait... " | tee -a $LOG_FILE_NAME
    cp $VERBOSE $1 $2 $3 >> $LOG_FILE_NAME 2>>$LOG_FILE_NAME
}

callExecute(){
    #$1 -> script 
    #$2 -> arguments
    #$3 -> avoid chanaling the install log to a file  

    logMessage "Started Executing $1 $2 " ""

    if [[ -n $3 ]] ; then 
        $1 $2 | tee -a $LOG_FILE_NAME
    else 
        $1 $2 >>$LOG_FILE_NAME 2>> $LOG_FILE_NAME
    fi
    EXEC_OUT=$?
    if ! [[ $EXEC_OUT -eq 0  ]] ; then 
        logMessage "" "Unable to call Execute : [$1 $2] ERROR Code Returned : $EXEC_OUT ."
    else
        logMessage "Completed Execution of  : [$1 $2]  Returned Code : $EXEC_OUT ." ""
    fi 

}
removeCommand(){
    logMessage "Removing components : $2" ""
    rm $1 $2 >> $LOG_FILE_NAME 2>> $LOG_FILE_NAME
}

preInstall(){
    cd $INSTALL_DIR
    if [[ $PREVIOUS_INSTALL = 'y' ]] ; then 
        #callExecute "$INSTALL_DIR/bin/DiscoveryStudio2021" "-nosplash -re"
        logMessage "Removing old Discovery Studio Client at $INSTALL_DIR" ""
        removeCommand "-rfv" "./*"
        #removeCommand "-rfv" "./Logs/summary.log ./Logs/log.txt ./share/modeler/bin ./share/modeler/examples ./share/modeler/modlib/modeller"
    else 
        mkdir -p $VERBOSE "$INSTALL_DIR/Logs" >> $LOG_FILE_NAME 2>> $LOG_FILE_NAME
    fi 
    cd $CURRENT_DIR

}


postInstall(){
    cd $INSTALL_DIR
    mkdir -p $VERBOSE "$INSTALL_DIR/Logs" >> $LOG_FILE_NAME 2>> $LOG_FILE_NAME 
    
    CONSOLE_ARG="-console"
    SILENT_ARG="-silent"

    if [[ $SILENT_MODE = "y" ]] ; then 
        SILENT_ARG="-silent"
        CONSOLE_ARG=""
    fi
    NORMALIZE_DIR=$(readlink -m $INSTALL_DIR/../)
    INSTALL_DIR_ARG="-P licensepack.installLocation=$NORMALIZE_DIR"

    echo "Calling LicensePack Installer " | tee -a $LOG_FILE_NAME
    #callExecute "./lp_installer/lp_setup_linux.sh" " -- -console $SILENT_ARG $INSTALL_DIR_ARG  -V PRODUCT_LP_FILE=$INSTALL_DIR/share/license/data/lp_location $PORT_AT_HOST_ARG $EXTRA_ARGS" "-force"

    # Important Note : if you are using license pack 7.x then remove the "--" in the arg below or else if license pack 20.xx add the "--" in the arguments
    callExecute "./lp_installer/lp_setup_linux.sh" "-- $CONSOLE_ARG $SILENT_ARG $INSTALL_DIR_ARG  -V PRODUCT_LP_FILE=$INSTALL_DIR/share/license/data/lp_location $PORT_AT_HOST_ARG $EXTRA_ARGS" "-force"


    cpFiles "--preserve=mode" "./share/license/data/DiscoveryStudio/tempdata.dat" "./share/license/data/tempdata.dat"
    cd $INSTALL_DIR/bin
    shortCutCreater "../lib/launcher.sh" "$DS_CLIENT_NAME"
    cd $INSTALL_DIR
    
    createDeskTopFileContent "$INSTALL_DIR" 
    
    logMessage "Creating ShortCut for DS Client Shortcut at : $DESKTOP_PATH/$DESKTOP_FILE_NAME and $HOME/.local/share/applications/$DESKTOP_FILE_NAME" ""
    
    if [[  -d $DESKTOP_PATH ]] ; then 
        echoe "$DESKTOP_SHORTCUT_FILE_CONSTENT" > "$DESKTOP_PATH/$DESKTOP_FILE_NAME" 2>> $LOG_FILE_NAME
        callExecute "chmod" "755 $DESKTOP_PATH/$DESKTOP_FILE_NAME"
        echoe "$DESKTOP_SHORTCUT_FILE_CONSTENT" >  "$HOME/.local/share/applications/$DESKTOP_FILE_NAME" 2>> $LOG_FILE_NAME
    else 
        echoe "$DESKTOP_SHORTCUT_FILE_CONSTENT" > "$NORMALIZE_DIR/$DESKTOP_FILE_NAME" 2>> $LOG_FILE_NAME
        echo "Desktop directory [ $DESKTOP_PATH ] not found, cannot create a Desktop Icon over Desktop, but create a icon at the install directory [ $NORMALIZE_DIR/$DESKTOP_FILE_NAME ]  " | tee -a $LOG_FILE_NAME
        
    fi 
    
    
    #Changing Mode to 755 for all 
    #callExecute "chmod" "755 -R *"

    if [ "$EUID" -eq 0 ] ; then 
        logMessage "Registering desktop file in application command: $DESKTOP_PATH/$DESKTOP_FILE_NAME " ""
        desk_cmd=$(desktop-file-install "$DESKTOP_PATH/$DESKTOP_FILE_NAME")
        $desk_cmd  >>$LOG_FILE_NAME 2>> $LOG_FILE_NAME
    fi

    callExecute "chmod" "755 -R *"
    cd $CURRENT_DIR
}

checkFileSpace(){
    #NORMALIZE_DIR=$(readlink -m $INSTALL_DIR)

    NORMALIZE_DIR=$INSTALL_DIR
    
    checkIfPathHasDisStudio

    if  [ $PATH_CHECK -eq "1" ] ; then 
        NORMALIZE_DIR=$(readlink -m $INSTALL_DIR)
    fi


    if [[ -z $NORMALIZE_DIR ]]; then 
        ExiteInstall "Cannot read install directory path : $INSTALL_DIR " 1
    fi


    INSTALL_DIR=$NORMALIZE_DIR
    #du -sh ./client/ dir space
    #df -h $INSTALL_DIR --output=avail
    INSTALL_FOLDER_SIZE=$(du -sh $1 | grep -e 'M' -e 'G')

    #FREE_SPACE=$(df -h $2 --output=avail | grep -v 'Av')
    FILE_SPACE_MSG="Disk space required         :  $INSTALL_FOLDER_SIZE \nInstall directory           :  $INSTALL_DIR"
    logMessage "$FILE_SPACE_MSG" ""

    DoPrompt "$FILE_SPACE_MSG $TWO_OPTION_LIST" "1" "[1-2]+$" "TAKENULL"
    if [  $INPUT -eq 1 ] ; then
        logMessage "Install directory is set to  [$INSTALL_DIR]" ""
        if [[ -w $INSTALL_DIR ]] ; then 
            logMessage "The directory : $INSTALL_DIR already Exist" ""   
            if [[ -x "$INSTALL_DIR/bin/config_lp_location" ]] ; then 
                logMessage "Found Existing $DS_CLIENT_NAME installation at $INSTALL_DIR" ""  
                PREVIOUS_INSTALL="y"
            fi   
        else
            logMessage "Making directory : $INSTALL_DIR" ""
            mkdir -p $VERBOSE "$INSTALL_DIR" >> $LOG_FILE_NAME 2>> $LOG_FILE_NAME  
            if ! [[ -w $INSTALL_DIR ]] && [[ -x $INSTALL_DIR ]] ; then 
                    ExiteInstall "Sorry cannot create $INSTALL_DIR or permission not set" 1
            fi
        fi
    else 
       # echo "Please re-run the LicensePack installer: $INPUT"
        ExiteInstall "User cancelled installation" 1
    fi  

}
shortCutCreater(){
    #$1 --> Source File
    #$2 --> shortcut file name
   ln -s $VERBOSE $1 $2 >> $LOG_FILE_NAME 2>> $LOG_FILE_NAME
}

checkSetUp(){
if [ $SILENT_MODE = "y" ] ; then
    if [ ! -z $INSTALL_DIR ] ; then 

        checkIfPathHasDisStudio

        if  [ $PATH_CHECK -eq "1" ] ; then 
            INSTALL_DIR=$(readlink -m $INSTALL_DIR/${DS_CLIENT_NAME})
        fi
        
        logMessage "Silent Mode is enabled. Running the install in silent mode will install $DS_CLIENT_NAME at $INSTALL_DIR" ""
      #  INSTALL_DIR=$(readlink -m $INSTALL_DIR/$DS_CLIENT_NAME)
        if [ ! -d $INSTALL_DIR ] ; then
             mkdir -p $VERBOSE "$INSTALL_DIR" >> $LOG_FILE_NAME 2>> $LOG_FILE_NAME

        else
          if [[ -x "$INSTALL_DIR/lib/launcher.sh" ]] ; then 
             logMessage "Found existing $DS_CLIENT_NAME Installation at $INSTALL_DIR" ""  
             PREVIOUS_INSTALL="y"
          fi 
        fi
        echo "You can monitor the $DS_CLIENT_NAME install log at: $LOG_FILE_NAME"
     else
        logMessage "" "Please pass in location arg [-P dsclient.installLocation=<path>] where to install while running the script in [-silent] "
        echoe $ARGUMENT_OPTION
        ExiteInstall "Please pass in location arg [-P dsclient.installLocation=<path>]" 1
    fi
else
    echoe $WELCOME_NOTE
fi
}

cleanUpOnFailed(){
 removeCommand "-rf" "$LOG_FILE_NAME"
    
}

cleanUp(){

cpFiles "" "$LOG_FILE_NAME" "$INSTALL_DIR/Logs/$LOG_FILE"
removeCommand "-rf" "$LOG_FILE_NAME"
LOG_FILE_NAME="$INSTALL_DIR/Logs/$LOG_FILE"
removeCommand "-rf" "$LOG_FILE_NAME/install_DSClient.sh"

}
## Trap Ctrl +  C actions
trap_ctrlc (){
    echo "User cancelled installation"
    cleanUpOnFailed 
    exit 2
}

#=======================================
# Start of Installation
#=======================================


echoe "$(date '+%Y %b %d %H:%M') Started Logging\n Current directory: $CURRENT_DIR" > $LOG_FILE_NAME

trap "trap_ctrlc" 2

while [[ $# -gt 0 ]]
do
arg="$1"
case $arg in
        "-silent")     
        SILENT_MODE="y"
        logMessage "Settings Silent Mode On" ""
        ;;
        "-help")     
            echoe $ARGUMENT_OPTION
            exit 1
        ;;
	"-h")
            echoe $ARGUMENT_OPTION
            exit 1
        ;;

        "-console")
        CONSOLE_MODE="y"
        logMessage "Settings Console Mode On" ""
        ;;
        "-is:tempdir")
        TEMP_DIR=$2
        logMessage "Tmp directory is set to $TEMP_DIR" ""
        shift
        ;;
        "-is:log")  
        echo "$(date '+%Y %b %d %H:%M') Started Logging" > $2  
        if [ -w $2 ] ; then 
             logMessage "Log File is being set To =>  $2 .\n Moving Logging to it." ""
             LOG_FILE_NAME=$2
             LOG_ARG="-is:log $LOG_FILE_NAME"  
             echoe "Arguments Passed $@" >>$LOG_FILE_NAME
        else
            logMessage "Unable to set Logging to  =>  $2 .\n because of file Permissions" ""
        fi     
        shift
        ;;
        "-P")
        if [ -n $2 ] ; then
            splitString $2 "="      
            if [ ! -z ${SPLIT_ARRAY[1]} ] ; then
                INSTALL_DIR=${SPLIT_ARRAY[1]}
                logMessage "Install Dir is set to  $INSTALL_DIR" ""
            fi
        fi
        ;;
        *@*)
            logMessage "LPPORTATHOST is set to: $arg" ""
            PORT_AT_HOST="$arg"
            PORT_AT_HOST_ARG="$PORT_AT_HOST"
        ;;
        "*")       
            EXTRA_ARGS="$EXTRA_ARGS $arg"
            logMessage "Unknown Arguments: $EXTRA_ARGS" ""
        ;;
        esac
shift
done

checkSetUp

if [[ $SILENT_MODE != "y" ]] ; then 
    getInstallDir
    checkFileSpace "." "$INSTALL_DIR"
fi

preInstall

if [[ ! -d $INSTALL_DIR ]] ; then 
    echoe "Cannot make directory Check Permissions: $INSTALL_DIR "
    ExiteInstall "Check directory : $INSTALL_DIR " 1
fi 

cpFiles "-R --preserve=mode" "./*" "$INSTALL_DIR"

echoe "=========================================\n\n"
postInstall


cleanUp
# to-do
#removeCommand "-rfv" "$CURRENT_DIR"
ExiteInstall "Completed installing  $DS_CLIENT_NAME at $INSTALL_DIR" 0


