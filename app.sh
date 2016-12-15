#!/bin/bash

# --- CONFIG ---
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASH_VERSION_TESTED="3.2.57"

FILE_AUTH="authenticate.txt"
FILE_MENU="menu.txt"
FILE_EXCLUDE="exclude.txt"
REMOTE="$DIR/remote-test"

# --- SETUP PATHS ---
RSYNC="/usr/bin/rsync"
CAFFE="/usr/bin/caffeinate -s" # use to keep computer alive when working for a long time
CALL="$CAFFE $RSYNC --verbose --recursive --delete --update --progress --archive --exclude-from $EXCLUDE"

# --- VARIABLES ---
declare AUTH_USER
declare AUTH_PASS
declare -a MENU_MAIN
declare -a MENU_OPERATIONS
declare -a PROJECT_SOURCE
declare -a PROJECT_TARGET

# --- HELPERS ---
function version_gt() {
	#TODO sort -V does't work on OSX
	test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1";
}
function command_exists () { type "$1" &> /dev/null ;}
function header() {
	echo ''
	echo '  /$$$$$$$                                         /$$                    /$$$$$$                            '
	echo ' | $$__  $$                                       | $$                   /$$__  $$                           '
	echo ' | $$  \ $$/$$$$$$  /$$$$$$ /$$ /$$$$$$  /$$$$$$$/$$$$$$  /$$$$$$$      | $$  \__//$$   /$$/$$$$$$$  /$$$$$$$'
	echo ' | $$$$$$$/$$__  $$/$$__  $|__//$$__  $$/$$_____|_  $$_/ /$$_____/      |  $$$$$$| $$  | $| $$__  $$/$$_____/'
	echo ' | $$____| $$  \__| $$  \ $$/$| $$$$$$$| $$       | $$  |  $$$$$$        \____  $| $$  | $| $$  \ $| $$      '
	echo ' | $$    | $$     | $$  | $| $| $$_____| $$       | $$ /$\____  $$       /$$  \ $| $$  | $| $$  | $| $$      '
	echo ' | $$    | $$     |  $$$$$$| $|  $$$$$$|  $$$$$$$ |  $$$$/$$$$$$$/      |  $$$$$$|  $$$$$$| $$  | $|  $$$$$$$'
	echo ' |__/    |__/      \______/| $$\_______/\_______/  \___/|_______/        \______/ \____  $|__/  |__/\_______/'
	echo '                      /$$  | $$                                                   /$$  | $$                  '
	echo '                     |  $$$$$$/                                                  |  $$$$$$/                  '
	echo '                      \______/                                                    \______/                   '
	echo ''
}


# --- CHECKS ---
function check_bash() {
	#TODO check bash min-version?
	#if ! version_gt $BASH_VERSION_TESTED $BASH_VERSION; then
	#	echo "Your computer isn't supported. Please update the operating system."
	#	exit
	#fi
	echo "TODO: check bash version, sort -V doesn't work in osx"
	# Check if osx system
	case "$OSTYPE" in
		darwin*)  #we are happy
		 ;;
	  *)        echo "Must be running on OSX" ; exit;;
	esac

}


function check_requirements() {
	if ! command_exists $RSYNC; then
		echo -e "rsync doesn't exist on computer.";
	fi
	if ! command_exists $CAFFE; then
		echo -e "caffeinate doesn't exist on computer.";
	fi
}


function check_files() {
	#check for authenticate file
	if [ ! -f $FILE_AUTH ]; then
    echo "File not found!"
		#TODO Create file
		echo "username="$'\n'"password=" >> $FILE_AUTH
		exit
	fi
	#read authenticate file
	declare -i c
	c=0
	while IFS= read -r line; do
		IFS='=' read -ra obj <<< "$line"
		if (($c == "0")); then
			#username
			if [ -z "${obj[1]}" ]; then
				echo "You must enter username in $FILE_AUTH"
				echo "If you have issues authenticate, delete the file and run this script again."
				exit
			fi
			AUTH_USER="${obj[1]}"
		fi
		if (($c == "1")); then
			#password
			if [ -z "${obj[1]}" ]; then
				echo "You must enter password in $FILE_AUTH"
				echo "If you have issues authenticate, delete the file and run this script again."
				exit
			fi
			AUTH_PASS="${obj[1]}"
		fi
		c=$c+1
	done <$FILE_AUTH
	#grab remote files so we have latest
	rsync --update "$REMOTE/config" $DIR
}


function create_menus() {
	#operations for project
	MENU_OPERATIONS=(
      "Get latest from remote"
			"Show changes from remote"
			"Send latest from me to remote"
      "Show changes from me to remote"
      "Return to main menu"
  )
	#projects to choose from
	declare -i c;	c=0
	declare -a t; declare -a s; declare -a d;
	while IFS= read -r line; do
		IFS=',' read -ra obj <<< "$line"
		#TODO 2d array nicer than 3 arrays!
		eval "t+=\"${obj[0]}\""
		eval "s+=\"${obj[1]}\""
		eval "d+=\"${obj[2]}\""
	done <$FILE_MENU
	t+="Quit" #add quit
	MENU_MAIN=($t)
	PROJECT_SOURCE=($s)
	PROJECT_TARGET=($d)
}


function main_menu
{
	#clear
	#header
	PS3="Select project: "
	select option; do # in "$@" is the default
		if [ "$REPLY" -eq "$#" ];
		then
			echo "Exiting..."
			break;
		elif [ 1 -le "$REPLY" ] && [ "$REPLY" -le $(($#-1)) ];
		then
			# $REPLY = index
			# $option = text
			echo "You selected $option which is option $REPLY"
			SELETED_PROJECT_TITLE=${MENU_MAIN[$REPLY]}
			SELETED_PROJECT_SOURCE=${PROJECT_SOURCE[$REPLY]}
			SELETED_PROJECT_TARGET=${PROJECT_TARGET[$REPLY]}
			echo "Sel title $SELETED_PROJECT_TITLE"
			echo "Sel source $SELETED_PROJECT_SOURCE"
			echo "Sel target $SELETED_PROJECT_TARGET"
			project_menu "${MENU_OPERATIONS[@]}" "$SELETED_PROJECT_TITLE" "$SELETED_PROJECT_SOURCE" "$SELETED_PROJECT_TARGET"
			break;
		else
			echo "Incorrect Input: Select a number 1-$#"
		fi
	done
}

function project_menu
{

	#clear
	#header
	echo "Project: $2"
	PS3="Project operations: "

	#@FIX WHY IS MAIN_MENU SHOWING HERE????

	select option; do # in "$@" is the default
		if [ "$REPLY" -eq "$#" ];
		then
			main_menu "${MENU_MAIN[@]}"
			break;
		elif [ 1 -le "$REPLY" ] && [ "$REPLY" -le $(($#-1)) ];
		then
			if (($REPLY == "1")); then
				echo "Get latest"
				#TODO create folder if doesn't exist?
				#$CALL "${2}" "$HOME/MyCompany/${3}";
			elif (($REPLY == "2")); then
				echo "Show server changes"
				#$CALL --dry-run "${2}" "$HOME/MyCompany/${3}";
			elif (($REPLY == "3")); then
				echo "Send latest"
				#$CALL "$HOME/MyCompany/${3}" "${2}";
			elif (($REPLY == "4")); then
				echo "Show my changes"
				#$CALL --dry-run "$HOME/MyCompany/${3}" "${2}";
			fi
		else
			echo "Incorrect Input: Select a number 1-$#"
		fi
	done
}


clear
header

check_bash
check_requirements
check_files
create_menus

main_menu "${MENU_MAIN[@]}"
