#!/bin/bash

#===========#
# user-vars # CHANGE
#===========#

prompt_message="Log" # rofi prompt message left of entry field

#=============#
# script-vars #  DONT CHANGE
#=============#

directory=$1
config="${0##*/}"; config="${config%.*}.rasi"                  # get rofi configs for scripts
# config file titles must match associated script title

rofi_command="rofi -theme $directory/configs/$config"          # rofi config for menu
rofi_error_command="rofi -theme $directory/configs/error.rasi" # rofi config for error message
notifications=$2                                               # enable/disable notifications
notifier=$3                                                    # command to use for notifications
logs=$4                                                        # log directory
log_count=$5; log_count=$((log_count+1))                       # number of backup logs to keep

#===========#
# borg-vars # CHANGE
#===========#

# quote any options containing spaces
backup_options=(
	--verbose
	'--filter AME'
	--list
	--stats
	--show-rc
	--compression
	lz4
)

prune_options=(
	--list
	--show-rc
	--keep-daily 7
	--keep-weekly 4
	--keep-monthly 6
	--keep-yearly 3
)

archive_name="::{hostname}-{now}"
# borg may use the following placeholders: {now}, {utcnow}, {fqdn}, {hostname}, {user} and others

backup_directories=(
    $HOME/documents
)

#============#
# backup_run #
#============#

# create log file
filename="backup-log-$(date +"%Y-%m-%d_%T_XXXXXX")"
tempfile=$(mktemp -p $logs $filename)
# send all output to log 
exec &>> $tempfile

# utility for printing info into logs
info() {
	printf "%s %s\n" "$*" "$( date )"
}

# function for notifications if enabled
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

# main backup function
backup() {
	# output progress
	notify "Backup: Starting!"
	info "Starting backup!"

	# create backup
	borg create ${backup_options[@]} $archive_name ${backup_directories[@]}
	backup_exit=$?

	# output progress
	notify "Backup: Finished!"
	notify "Backup: Pruning!"
	info "Pruning repository!"

	# prune backups
	borg prune ${prune_options[@]} 
	prune_exit=$?

	# note - later versions of borg will need compact to be done here

	# use highest exit code as global exit code
	global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

	# check exit status and report it
	if [ ${global_exit} -eq 0 ]; then
		info "Backup and Prune finished successfully!"
	elif [ ${global_exit} -eq 1 ]; then
		info "Backup and/or Prune finished with warnings!"
	else
		info "Backup and/or Prune finished with errors!"
	fi

	# show backup log
	display="$(cat $tempfile | $rofi_command -no-click-to-exit -p $prompt_message -dmenu)"
	# note - one could use this to extend the function of selecting something from the log

	# prune log files
	prune_logs

	# exit sending status
	exit ${global_exit}
}

# run backup
backup
