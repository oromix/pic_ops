#!/bin/bash
#http://ninedegreesbelow.com/photography/exiftool-commands.html

YEAR="$1"
SCREENFOLDER="/Users/jess/Pictures/Screenshots - Mobile"
LOGFILE="~/.logs/yearly_standardize_$(date +%m.%d.%Y-%H.%M).log"

cd /Volumes/NAS-Backup/Pictures/$YEAR

find . -type d -maxdepth 1 | while read MONTHDIR
do
  cd /Volumes/NAS-Backup/Pictures/$YEAR/$MONTHDIR

  # TODO remove spaces from names
  echo "Removing spaces from filenames"
  find . -type f -iname "*\ *" | while read FILE
  do
    NEWFILE="${FILE// /_}"
    #mv "$FILE" "$NEWFILE"
    echo "  renamed $FILE to $NEWFILE" >> $LOGFILE
    echo "  renamed $FILE to $NEWFILE"
    FILE="$NEWFILE"
  done
  echo "...done"

  # TODO make sure all JPG have DateTimeOrignal EXIF data tag
    exiftool '-AllDates<filename' -r -if '(not $datetimeoriginal or ($datetimeoriginal eq "0000:00:00 00:00:00")) and (not $filetype eq "MOV" and not $filetype eq "MP4")' -overwrite_original.
    echo "  $FILE - set DateTimeOriginal FileModifyDate from filename" >> $LOGFILE
    echo "  $FILE - set DateTimeOriginal FileModifyDate from filename"
done

exiftool -r -d "%Y-%m-%d_%H.%M.%S%%-c.%%le" "-filename<dateTimeOriginal" "-fileModifyDate<DateTimeOriginal" -ext jpg -ext jpeg -ext tiff .
exiftool -r -d "%Y-%m-%d_%H.%M.%S%%-c.%%le" "-filename<creationDate" "-fileModifyDate<creationDate" -ext mov .
#exiftool -r "-FileModifyDate<DateTimeOriginal" .

#find . -iname "*.mov" | while read FILE
#do
  #exiftool -r -d "%Y-%m-%d_%H.%M.%S%%-c.%%le" "-filename<creationDate" .
  #exiftool "-FileModifyDate<CreationDate" $FILE
#done

echo ""
echo "Processing Screenshots"
#Move PNG files to local folder to clear up upload folder
find . -type f -iname \*.png | while read FILE
do
	echo "  copying screenshot: $FILE"
	cp -p "$FILE" "$SCREENFOLDER"
	SCREENFULLPATH="$SCREENFOLDER/$FILE"
	if [[ -e $SCREENFULLPATH ]]
  then
		echo " removing screenshot: $FILE"
    rm "$FILE"
	fi
done
echo "...done processing screenshots"
