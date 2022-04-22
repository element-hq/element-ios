#!/bin/zsh

assets=$PROJECT_DIR/Riot/Assets
locheck="/opt/homebrew/bin/mint run locheck xcstrings --ignore-missing --ignore lproj_file_missing_from_translation"

typeset -A array

cd $assets

for translation in *.lproj/; do 
	if [ $translation != en.lproj/ ]; then
		cd $translation
		for file in *; do
			if [[ $file = *.strings ]]; then
				array[$file]+="$translation$file "
			fi
		done
		
		cd $assets
	fi
done

for k in "${(@k)array}"; do
	zsh -c "$locheck en.lproj/$k $array[$k]"
done
