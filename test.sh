#!/bin/bash

# PRINT HELLO
clear
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

# --- SETUP PATHS ---
RSYNC="/usr/bin/rsync"
CAFFE="/usr/bin/caffeinate -s" # use to keep computer alive when working for a long time
CALL="$CAFFE $RSYNC --verbose --recursive --delete --update --progress --archive --exclude-from $EXCLUDE"

#REM SOURCE="~/testSource/*"
#SOURCE="/Volumes/gemensam\$/Filmer/*"
#DESTINATION="~/testDest"


# --- CONFIG ---
BASH_VERSION_TESTED="3.2.57"

FILE_AUTH="authenticate.txt"
FILE_MENU="menu.txt"
FILE_MENU_REMOTE="menu-remote.txt"
FILE_EXCLUDE="exclude.txt"
FILE_EXCLUDE_REMOTE="exclude-remote.txt"


# --- HELPERS ---
function version_gt() {
	#TODO sort -V does't work on OSX
	test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1";
}
function command_exists () { type "$1" &> /dev/null ;}

# --- CHECKS ---
function check_bash() {
	#TODO check bash min-version?
	#if ! version_gt $BASH_VERSION_TESTED $BASH_VERSION; then
	#	echo "Your computer isn't supported. Please update the operating system."
	#	exit
	#fi
	echo "TODO: check bash version, sort -V doesn't work in osx"
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
	#TODO check if stuff we need exists?
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
			#TODO how to get this to global??
			eval "declare -r AUTH_USER=\"${obj[1]}\""
		fi
		if (($c == "1")); then
			#password
			if [ -z "${obj[1]}" ]; then
				echo "You must enter password in $FILE_AUTH"
				echo "If you have issues authenticate, delete the file and run this script again."
				exit
			fi
			#TODO how to get this to global??
			declare -r AUTH_PASS="${obj[1]}"
		fi
		c=$c+1
	done <$FILE_AUTH

	#grab remote files

	FILE_EXCLUDE
	
}



declare -a optionsMain; #Main menu options


#echo "$BASH_VERSION $BASH_VERSION_TESTED"
check_bash
check_requirements
check_files

echo "user $AUTH_USER pass $AUTH_PASS" #WE WANT IT GLOBAL!
exit



create_menu_array() {
	echo "build menu array"
	echo "build array"
	declare -i b
	b=0

	while IFS= read -r line; do
		echo ""
		echo "loop file"

		IFS=',' read -ra obj <<< "$line"
		echo "menu item object ${obj[@]}"
		eval "${1}[$b]=(${obj[@]})"
		b=$b+1
	done <$FILENAME
	b=$b+1
	#eval "${1}+=(\"Quit\")"
}

#mapfile -t resb <<< "$(create_menu_array)" "optionsArr"
create_menu_array optionsArr
echo "done"
#echo ${optionsArr[@]}
#echo ${optionsArr[0][1]}
echo ""
#echo ${optionsArr[0][@]}
#echo $optionsArr

for i in "${optionsArr[@]}"
do
   :
   # do whatever on $i
	 ##echo "first "$i
	 for j in "${i[@]}"
	 do
	    :
	    # do whatever on $i
	 	 echo "print "$i
	 done

done
