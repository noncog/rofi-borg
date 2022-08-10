#!/bin/bash

#===========#
# user-vars # CHANGE
#===========#

directory="$HOME/projects/rofi-borg"      # directory of rofi-borg
# recommend $HOME/.config/rofi/rofi-borg

downloads="$HOME/downloads/borg-download" # downloads directory
prompt_message="Borg"                     # rofi prompt message left of entry field
log_count=7                               # amount of logs want to keep
# never set log_count to 0, rofi-borg requires logging to function and not freeze your pc

notifications="y"                         # set to n to disable 
notifier="dunstify"                       # set to command for your notifications
# caution - this command is evaluated. DO NOT put any dangerous commands in here

#=============#
# script-vars #  DONT CHANGE
#=============#

scripts="$directory/scripts"                                   # dfirectory for menu item scripts
logs="$directory/logs"                                         # directory of logs & tmp files
config="${0##*/}"; config="${config%.*}.rasi"                  # get rofi config for script# config file titles must match associated script title

# to change location on screen, increase -yoffset 
rofi_command="rofi -no-fixed-num-lines -location 2 -yoffset 57 -theme $directory/configs/$config"          # rofi config for menu
rofi_error_command="rofi -theme $directory/configs/error.rasi" # rofi config for error message

#===========#
# borg-vars # CHANGE
#===========#

# feel free to customize this section with all of your borg requirements.

# these variables are passed to all subsequent scripts and are not set globally in your environment after execution

export BORG_REPO="$(cat $HOME/.borg-repo)"
# use single quotes to prevent variable expansion if server contains special symbols: e.g. @ or $
export BORG_REMOTE_PATH="/usr/local/bin/borg1/borg1"
# rsync.net users must use BORG_REMOTE_PATH
export BORG_PASSCOMMAND="cat $HOME/.borg-passphrase" 
# my recommended way to pass borg your passphrase only during execution of this script and not globally setting in environment variables
# just put your password in that file and it will just work.

#============#
# menu-items # CAN CUSTOMIZE
#============#

items=(
    backup=" Backup"
    list=" List"
    download=" Download"
    delete=" Delete"
)

scripts=(
    backup="$scripts/backup_run.sh"
    list="$scripts/backup_list.sh"
    download="$scripts/backup_download.sh"
    delete="$scripts/backup_delete.sh"
)

#===========#
# rofi-borg # DONT CHANGE
#===========#

# create command to push/pipe menu into rofi
assemble_menu() {
    declare -A menu
    declare -a order
    # assemble menu items from items array
    for item in "${items[@]}"; do
	menu+=(["${item%=*}"]="${item#*=}")
	order+=( "${item%=*}" )
    done
    for item in "${order[@]}"; do
	echo "${menu["$item"]}"
    done
}

# function for notifications if enabled
notify() {
    if [ $notifications == "y" ]; then
	eval $notifier $1
    fi
}

# error message
err_msg() {
    $rofi_error_command -e "$1"
}

# if logs set correctly: log_count >= 1 proceed
if [ $log_count -ge 1 ]; then    
    # create logs directory
    if [ ! -d "${logs}" ]; then
	mkdir -p "${logs}"
    fi

    # call rofi and return selection
    selection="$(assemble_menu | $rofi_command -p "$prompt_message" -dmenu)"

    # if selection was empty, do nothing
    if [[ -z "$selection" ]]; then
	notify "Selection canceled."
	
    # if selection not empty, run the command for the selection
    else
	# get index of selected command
	for i in "${!items[@]}"; do
	    if [[ "${items[$i]#*=}" = "$selection" ]]; then
		index=$i
	    fi
	done

	# execute command for selection
	if [[ -f "${scripts[index]#*=}" ]]; then
	    bash "${scripts[index]#*=}" $directory $notifications $notifier $logs $log_count $downloads $config
	else
	    err_msg "$selection script not found."
	fi
    fi

# if logs set incorrectly: log_count < 1 error out   
else
    err_msg "Log count too low: $log_count"
fi
