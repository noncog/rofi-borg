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

# testing error messasge
err_msg "testing the command"

