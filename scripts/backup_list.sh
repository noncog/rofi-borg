#!/usr/bin/env bash

#===========#
# user-vars # CHANGE
#===========#

prompt_message="List" # rofi prompt message left of entry field

#=============#
# script-vars #  DONT CHANGE
#=============#

directory=$1
config=$7                                                      # get rofi configs for scripts
# config file titles must match associated script title

rofi_command="rofi -no-fixed-num-lines -location 2 -yoffset 57 -theme $directory/configs/$config"          # configure main menu
rofi_error_command="rofi -theme $directory/configs/error.rasi" # configure error message
notifications=$2                                               # enable/disable notifications
notifier=$3                                                    # command to use for notifications
logs=$4                                                        # log directory
log_count=$5; log_count=$((log_count+1))                       # number of backup logs to keep

#===========#
# borg-vars # CHANGE
#===========#

# quote any options containing spaces
list_options=(
    '--format {archive}{NL}'
)

#=============#
# backup-list #
#=============#

# create log file
filename="backup-list-log-$(date +"%Y-%m-%d_%T_XXXXXX")"
tempfile=$(mktemp -p $logs $filename)
# send all output to log
exec &>> $tempfile

# function used for notifying if enabled
notify() {
    if [ $notifications == "y" ]; then
	eval $notifier $1
    fi    
}

# function to delete excess logs
prune_logs() {
    # if logs is >= log_count delete the oldest
    if [ $(ls $logs | wc -l) -ge $log_count ]; then
	(cd $logs && ls -tp | grep -v '/$' | tail -n +$log_count | xargs -I {} rm -- {})
    fi    
}

# output progress
notify "Backup: Listing!"
# get list of backups
borg list $list_options
# output list rofi
list="$(cat $tempfile | $rofi_command -no-click-to-exit -p $prompt_message -dmenu)"
# prune log files
prune_logs
