#!/bin/bash

# rofi-borg options
# =======================
# rofi-borg location
directory="$HOME/Projects/rofi-borg"
# configured rofi commands
rofi_command="rofi -theme $directory/configs/borg-rofi.rasi"
rofi_error_command="rofi -theme $directory/configs/error.rasi"

# borg options
# ======================



# rofi-borg
# ======================

# error message
err_msg() {
	$rofi_error_command -e "$1"
}

# menu items - to modify just add/remove items
menu_items=(
	backup="backup"
	list="list"
	download="download"
	delete="delete"
)

for item in "${menu_items[@]}"; do
	# this succesfully gets the list of variables
	concat+="\$${item%=*}\n"
done

items="${concat%\\*}"

err_msg $items
