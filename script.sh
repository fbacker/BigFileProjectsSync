#!/bin/bash

# --- CONFIG ---
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
bash_version_tested="3.2.57"
dir_company="$HOME/MyCompany" #files stored locally
file_auth="authenticate.txt" #username and password
file_menu="menu.txt"
file_exclude="exclude.txt"
#remote="$dir//Users/kidkic/Documents/REMOTE" #remote base path
remote="$HOME/Documents/REMOTE" #remote base path
remote_app="/Users/kidkic/Desktop/testscripts/BigFileProjectsSync/remote-test/syncapplication" #remote base path
remote_check="/Volumes/gemensam\$/Marknad/"
# --- SETUP PATHS ---
rsync="/usr/bin/rsync"
caffe="/usr/bin/caffeinate -s" # use to keep computer alive when working for a long time
call_move="$caffe $rsync --recursive --update --archive --exclude-from \"$dir/$file_exclude\" --progress"
call_test="$caffe $rsync --recursive --update --archive --exclude-from \"$dir/$file_exclude\" --dry-run --verbose "

# --- VARIABLES ---
declare window_width
declare auth_user
declare auth_pass
declare -a menu_main
declare -a menu_operations
declare -a project_source
declare -a project_target
window_width=45
c_normal=`echo "\033[m"`
c_menu=`echo "\033[36m"` #Blue
c_number=`echo "\033[33m"` #yellow
c_fgred=`echo "\033[41m"`
c_red=`echo "\033[31m"`
c_enter=`echo "\033[33m"`
c_line=`echo -e "${c_menu}**************************************************${c_normal}"` #width 50


debug_ignore_authenticate=true
debug_ignore_remote_check=false
debug_ignore_copy_files=true
debug_ignore_copy_program=true

# --- HELPERS ---
function version_gt() {
	#TODO sort -V does't work on OSX
	test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1";
}
function command_exists () { type "$1" &> /dev/null ;}
# Convert 8 bit r,g,b,a (0-255) to 16 bit r,g,b,a (0-65535) to set terminal background.
# r, g, b, a values default to 255
function set_bg () {
    r=${1:-255}
    g=${2:-255}
    b=${3:-255}
    a=${4:-255}
    r=$(($r * 256 + $r))
    g=$(($g * 256 + $g))
    b=$(($b * 256 + $b))
    a=$(($a * 256 + $a))
    osascript -e "tell application \"Terminal\" to set background color of window 1 to {$r, $g, $b, $a}"
}
# Convert 8 bit r,g,b,a (0-255) to 16 bit r,g,b,a (0-65535) to set terminal background.
# r, g, b, a values default to 255
function set_fg () {
    r=${1:-255}
    g=${2:-255}
    b=${3:-255}
    a=${4:-255}
    r=$(($r * 256 + $r))
    g=$(($g * 256 + $g))
    b=$(($b * 256 + $b))
    a=$(($a * 256 + $a))
    osascript -e "tell application \"Terminal\" to set normal text color of window 1 to {$r, $g, $b, $a}"
}
function set_font {
    osascript -e "tell application \"Terminal\" to set the font name of window 1 to \"$1\""
    osascript -e "tell application \"Terminal\" to set the font size of window 1 to $2"
}
function center {
	declare -i width; declare -i size; declare -i x
	width=window_width;
	size=$#1;
  x=$(($width/2-$size/2)) #TODO how to round.floor???
	for ((i=0; i < $x; i++)){ echo -n " "; }
	echo -e " $1"
}
function print_input_ready
{
	echo -e "${c_enter}Please enter a operation number and enter. ${c_normal}"
}
function check_path
{
	if [ ! -d "$1" ]; then
		echo -e $c_red"Path doesn't exists: $1"$c_normal
		echo -e $c_number"Fix paths and rerun the application"$c_normal
		exit
	fi
}
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
	echo ''
}


# --- CHECKS ---
function check_bash() {
	#TODO check bash min-version?
	#if ! version_gt $BASH_VERSION_TESTED $BASH_VERSION; then
	#	echo "Your computer isn't supported. Please update the operating system."
	#	exit
	#fi
	#echo "TODO: check bash version, sort -V doesn't work in osx"
	# Check if osx system
	case "$OSTYPE" in
		darwin*)  #we are happy
		 ;;
	  *)        echo "Must be running on OSX" ; exit;;
	esac

}


function check_requirements() {
	if ! command_exists $rsync; then
		echo -e "rsync doesn't exist on computer.";
	fi
	if ! command_exists $caffe; then
		echo -e "caffeinate doesn't exist on computer.";
	fi
}


function check_files() {

	if [ "$debug_ignore_authenticate" = false ]; then
		#check for authenticate file
		if [ ! -f $file_auth ]; then
	    echo "File not found!"
			#TODO Create file
			echo "username="$'\n'"password=" >> $file_auth
			echo -e $c_red"Authentication file $file_auth doesn't exist. It's now created. Please open it and enter username and password."$c_normal
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
					echo $c_red"You must enter username in $file_auth"$c_normal
					echo $c_red"If you have issues authenticate, delete the file and run this script again."$c_normal
					exit
				fi
				auth_user="${obj[1]}"
			fi
			if (($c == "1")); then
				#password
				if [ -z "${obj[1]}" ]; then
					echo $c_red"You must enter password in $file_auth"$c_normal
					echo $c_red"If you have issues authenticate, delete the file and run this script again."$c_normal
					exit
				fi
				auth_pass="${obj[1]}"
			fi
			c=$c+1
		done <$file_auth
	fi

	#check connection to remote location
	if [ ! -d "$remote_check" ] && [ "$debug_ignore_remote_check" = false ]; then
		echo -e $c_red"Couldn't access network disk. Please attach $remote_check and try again."$c_normal
		exit
	fi

	#grab remote files so we have latest
	if [ "$debug_ignore_copy_files" = false ]; then
		rsync --update --archive "$remote_app/config/" "$dir"
	fi

	#Check for a newer version on server
	if [ "$debug_ignore_copy_program" = false ]; then
		if [[ "$remote_app/program/script.sh" -nt "$dir/script.sh" ]]; then
			cp "$remote_app/program/script.sh" "$dir/script.sh"
			echo -e $c_red"This program just got updated. Please run it again to use latest version."$c_normal
			exit
		fi
	fi

}


function create_menus() {
	#operations for project
	menu_operations=(
      "Get latest from remote"
			"Show changes from remote"
			"Send latest from me to remote"
      "Show changes from me to remote"
			"Clear screen and rewrite menu"
      "Return to main menu"
  )
	#projects to choose from
  local -a titles sources targets
  local title source destination
  while IFS='|' read -r title source destination; do
      titles+=( "$title" )
      sources+=( "$source" )
      targets+=( "$destination" )
  done < <(sed 's/, /|/g' "$file_menu")
  # Copy to global arrays
  menu_main+=( "${titles[@]}" )
	menu_main+=( "Quit" ) #add quit
	project_source+=( "${sources[@]}" )
  project_target+=( "${targets[@]}" )
}


function main_menu
{
	clear
	header

	len="${#menu_main[@]}"
	echo -e $c_line
	center "Select a Project"
  echo -e $c_line
	for (( c=0; c<"${#menu_main[@]}"; c++ ))
	do
		title="${menu_main[$c]}"
		index=$(($c+1))
		if [ "$index" -eq "$len" ]; then
			echo -e "${c_menu}**${c_number} $index or q)${c_menu} $title ${c_normal}"
		else
			echo -e "${c_menu}**${c_number} $index)${c_menu} $title ${c_normal}"
		fi
	done
  echo -e $c_line
  print_input_ready
	read opt

	while [ opt != '' ]; do
		if [[ $opt = "" ]]; then
			echo -e "${c_red}You must enter a number, then press enter!${c_normal}"
			read opt
    elif [ "$opt" = "q" ]; then
	    echo "Exiting..."
			echo "Goodbye!"
	    exit;
		else
			re='^[0-9]+$'
			if ! [[ $opt =~ $re ]] ; then
				echo -e "${c_red}Incorrect Input: Select a number 1-$len ${c_normal}"
				read opt
			fi
			declare -i index;
			index="$opt"
			if [ "$index" -gt "$len" ]; then
				echo -e "${c_red}Incorrect Input: Select a number 1-$len ${c_normal}"
				read opt
			elif [ "$index" -eq "$len" ]; then
				echo "Exiting..."
				echo "Goodbye!"
		    exit;
			elif [ 1 -le "$index" ] && [ "$index" -le $(($len-1)) ]; then
				local title source target
				index=$(($index-1))
		    title=${menu_main[$index]}
		    source=${project_source[$index]}
		    target=${project_target[$index]}
				#echo "selected $index, $title, $source, $target"
				project_menu "1" "$title" "$source" "$target"
				exit;
			fi
		fi
	done
}

function project_menu
{
	if [ "$1" = "1" ]; then
	clear
	header
	fi

	len="${#menu_operations[@]}"
	echo -e $c_line
	center "$2"
	echo -e $c_line
	for (( c=0; c<"${#menu_operations[@]}"; c++ ))
	do
		title="${menu_operations[$c]}"
		index=$(($c+1))
		if [ "$index" -eq $(($len-1)) ]; then
			echo -e "${c_menu}**${c_number} $index or m)${c_menu} $title ${c_normal}"
		elif [ "$index" -eq "$len" ]; then
			echo -e "${c_menu}**${c_number} $index or q)${c_menu} $title ${c_normal}"
		else
			echo -e "${c_menu}**${c_number} $index)${c_menu} $title ${c_normal}"
		fi
	done
  echo -e $c_line
  print_input_ready
	read opt


	while [ opt != '' ]; do
		if [[ $opt = "" ]]; then
			echo -e "${c_red}You must enter a number, then press enter!${c_normal}"
			read opt
    elif [ "$opt" = "q" ]; then
	    main_menu
	    exit;
		elif [ "$opt" = "m" ]; then
	    project_menu "1" "$2" "$3" "$4"
	    exit;
		else
			re='^[0-9]+$'
			if ! [[ $opt =~ $re ]] ; then
				echo -e "${c_red}Incorrect Input: Select a number 1-$len ${c_normal}"
				read opt
			fi
			declare -i index;
			index="$opt"
			if [ "$index" -gt "$len" ]; then
				echo -e "${c_red}Incorrect Input: Select a number 1-$len ${c_normal}"
				read opt
			elif [ "$index" -eq "$len" ]; then
				main_menu
		    exit;
			elif [ 1 -le "$index" ] && [ "$index" -le $(($len-1)) ]; then
				case $index in
					1) #get latest from remote
						check_path "$remote/${4}"
		      	paths="\"$remote/${4}/\" \"$dir_company/${3}/\"";
						eval "mkdir -p \"$dir_company/${3}\""
						execute_command "This will move new and changed files\n${c_menu}** ${c_normal}FROM server TO your computer" "$call_move" "$paths" "$2" "$3" "$4"
						;;
					2) #check changes from server
						check_path "$remote/${4}"
						paths="\"$remote/${4}/\" \"$dir_company/${3}/\"";
						echo exec="$call_test $paths";
						exec="$call_test $paths";
						eval $exec
						print_input_ready
						read opt
						;;
					3) #send latest to remote
						check_path "$dir_company/${3}"
						check_path "$remote/${4}"
						paths="\"$dir_company/${3}/\" \"$remote/${4}/\"";
						execute_command "This will move new and changed files\n${c_menu}** ${c_normal}FROM your computer TO server" "$call_move" "$paths" "$2" "$3" "$4"
						;;
					4) #check changes from local
						check_path "$dir_company/${3}"
						check_path "$remote/${4}"
						paths="\"$dir_company/${3}/\" \"$remote/${4}/\"";
						exec="$call_test $paths";
						eval $exec
						print_input_ready
						read opt
						;;
					5) #clean
						project_menu "1" "$2" "$3" "$4"
						break;
						;;
					*)
					read opt
					;;
				esac
			fi
		fi
	done
}

#params input,exec,var1,var2,var3
function execute_command() {
	echo -e $c_line
	echo -e "${c_menu}**${c_normal} $1"
	echo -e $c_line
	echo -e "${c_menu}**${c_number} 1 or y or ENTER)${c_menu} Do it ${c_normal}"
	echo -e "${c_menu}**${c_number} 2 or n)${c_menu} I regret my choice ${c_normal}"
	echo -e "${c_menu}**------------------------------------------------${c_normal}"
	echo -e "${c_menu}**${c_number} 6 advanced)${c_menu} Do it, and clean!\n** ${c_red}Will delete non-existing files on target! ${c_normal}"
	echo -e $c_line
	read opt
	while [ opt != '' ]; do
		if [ "$opt" = "1" ] || [ "$opt" = "y" ] || [[ $opt = "" ]]; then
			eval "$2 $3"
			project_menu "0" "$4" "$5" "$6"
			break;
		elif [ "$opt" = "2" ] || [ "$opt" = "n" ]; then
			project_menu "0" "$4" "$5" "$6"
			break;
		elif [ "$opt" = "6" ]; then
			eval "$2 --delete $3"
			project_menu "0" "$4" "$5" "$6"
			break;
		else
			echo -e "${c_red}Incorrect Input: Select something from the menu"
			read opt
		fi
	done
}

#lets run it

set_bg 24 34 52
set_fg 221 229 232
set_font "Oxygen Mono" 10

clear
header

check_bash
check_requirements
check_files
create_menus

main_menu
