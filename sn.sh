#!/bin/sh

main() {
	if [ ! "$SN" ]; then
		SN="$HOME/.cache/sn"
		mkdir -p "$SN"
	fi
	notes=$(tree -f --noreport -I "done" "$SN" | sed 1d | sed "s~$SN~~g")
	notes="New Category\n$notes"
	chosen=$(echo "$notes" | dmenu -l 10 -p "Choose note?" | cut -d '/' -f 2-)

	case "$chosen" in
		"")
			;;
		"New Category")
			new_category
			;;
		*/*)
			echo "note chosen"
			note_func
			;;
		*)
			echo "category chosen"
			category_func
			;;
	esac
}

new_category() {
	category=$(echo "" | dmenu -p "Name new category (Only letters and numbers):")
	case "$category" in
		"")
			;;
		*[![:alnum:]]*)
			new_category
			;;
		*)
			mkdir "$SN/$category"
			main
			;;
	esac
}

note_func() {
	echo "note_func note $chosen"
	note=$chosen
	choices="Edit\\nDone\\nRemove"
	chosen=$(echo "$choices" | dmenu -p "Choose")
	echo "$chosen"
	case "$chosen" in
		Edit)
			x-terminal-emulator -e vim "$SN/$note"
			# couldn't read from shell: Input/output error
			;;
		Done)
			category=$(echo "$note" | cut -d'/' -f 1)
			mkdir "$SN/$category/done"
			mv "$SN/$note" "$SN/$category/done"
			;;
		Remove)
			choices="Yes\\nNo"
			chosen=$(echo "$choices" | dmenu -p "Are you sure?")
			case "$chosen" in
				Yes)
					rm "$SN/$note"
					notify-send "$note removed"
					;;
				*)
					;;
			esac
			;;
	esac
	set_cron
	main
}

new_note() {
	note=$(echo "" | dmenu -p "Name new note (Only letters and numbers):")
	case "$note" in
		"")
			;;
		*[![:alnum:]]*)
			new_note
			;;
		*)
			header="SUMMARY\n\nCRON\n\n"
			echo "$header" > "$SN/$category/$note"
			x-terminal-emulator -e vim "$SN/$category/$note"
			set_cron
			notify-send "$note created."
		main
	esac
}

category_func() {
	echo "category $chosen"
	category=$chosen
	choices="New Note\\nRemove Category"
	chosen=$(echo "$choices" | dmenu -p "Choose")
	echo "$chosen"
	case "$chosen" in
		"New Note")
			new_note
			;;
		"Remove Category")
			choices="Yes\\nNo"
			chosen=$(echo "$choices" | dmenu -p "This will rm -rf the directory! Are you sure?")
			case "$chosen" in
				Yes)
					rm -rf "${SN:?}/${category:?}"
					notify-send "$category removed."
					main
					;;
				*)
					main
					;;
			esac
			;;
	esac
}

set_cron() {
	tmp=$(mktemp)
	crontab -l | grep -v "$note" > "$tmp"
	echo "set cron $chosen"

	mycron=$(grep "CRON" -A 1 "$SN/$note" | sed 1d)
	summary=$(grep "SUMMARY" -A 1 "$SN/$note" | sed 1d)
	if [ "$summary" = "" ]; then
		summary=$note
	fi
	if [ "$mycron" != "" ]; then
		crontask="$mycron export DISPLAY=:0 && export XDG_RUNTIME_DIR=/run/user/1000 && /usr/bin/notify-send '$summary' # $note"
		echo "$crontask" >> "$tmp"
	fi

	crontab "$tmp"
}

main
