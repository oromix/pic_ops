#!/bin/bash

#http://www.sno.phy.queensu.ca/~phil/exiftool/filename.html

#UPLOADREPO="/Users/jess/Pictures/test_repo"
UPLOADREPO="/Users/jess/.picture_upload_repo"
UPLOADREPOFIX="/Users/jess/.picture_upload_repo_fix"

WORKINGDIR="$UPLOADREPO"

if [ ! -z "$1" ]; then
  WORKINGDIR="$1"
fi

echo "Renaming files in $WORKINGDIR ..."
cd "$WORKINGDIR"

find . -iname "*.jpg" -o -iname "*.tiff" -o -iname "*.mov" -o -iname "*.mp4"  | while read FILE
do
  REGEXALT='[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}\.[0-9]{2}\.[0-9]{2}'
  REGEX='[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}\.[0-9]{2}\.[0-9]{2}'
  EXIFDATEPATTERN='%Y-%m-%d_%H.%M.%S%%-c.%%e'

  # dateTimeOriginal is for images
  # creationDate is for MOV files
  FILEEXIFDATETAGS=('dateTimeOriginal' 'creationDate')

  # Test filename against REGEXALT
  # Should catch the Snapchat picture edge case
  # Snapchat pictures do not contain EXIF data but do write the date/time info to the filename;
  # however that filename is very slightly different than our standard
  if [[ $FILE =~ $REGEXALT ]]; then
    NEWFILE="${FILE// /_}"
    echo "  File is snapchat picture - renaming $FILE to $NEWFILE"
    mv "$FILE" "$NEWFILE"

    # Write the Date/Time from the filename to the EXIFDATA
    exiftool "-dateTimeOriginal<filename" "-FileModifyDate<filename" "-FileAccessDate<filename" -overwrite_original $NEWFILE

    FILE="$NEWFILE"
  fi

  # Match the FILE name against the REGEX to see if they match.
  if [[ ! $FILE =~ $REGEX ]]; then
    # The FILE name does not match the REGEX
    # Parse FILE EXIF dates
    echo "  Processing $FILE..."

    FILEEXIFDATETAG=''
    for i in "${FILEEXIFDATETAGS[@]}"
    do
      FILEEXIFDATE=$(exiftool -d "$EXIFDATEPATTERN" -"$i" -S -s "$FILE")

      # If FILEEXIFDATE matches REGEX pattern then set the tag to use and end the loop
      if [[ $FILEEXIFDATE =~ $REGEX ]]; then
        FILEEXIFDATETAG="$i"
        break
      fi
    done

		if [ -z "$FILEEXIFDATETAG" ]
		then
      echo "    date info not parseable."
      if [ "$WORKINGDIR" == "$UPLOADREPO" ]; then
        echo    "moving $FILE to $UPLOADREPOFIX"
        mv "$FILE" "$UPLOADREPOFIX"
      fi
    else
      EXTENSION="${FILE##*.}"
      EXTENSION="$(echo $EXTENSION | tr '[:upper:]' '[:lower:]')"
      echo "    renaming $FILE to match date pattern"
      exiftool -d "%Y-%m-%d_%H.%M.%S%%-c.$EXTENSION" "-filename<$FILEEXIFDATETAG" "$FILE"
      # TODO test if the write worked correctly by matching against regex?
    fi
  else
    # Filename matches the REGEX pattern
    # Test to make sure the file has EXIF data

    # ISSUE - mp4 files potentially from snapchat can not have the EXIF data written by EXIFTOOL
    # so they will always fail and get moved to UPLOADFIXREPO
    # TODO - skip mp4 files or see if an updated version of exiftool can write to MP4.
    # TODO - for skipped MP4 files at least check the filename to make sure it matches $REGEX

    FILEEXIFDATETAG=''
    for i in "${FILEEXIFDATETAGS[@]}"
    do
      FILEEXIFDATE=$(exiftool -d "$EXIFDATEPATTERN" -"$i" -S -s "$FILE")

      # If FILEEXIFDATE matches REGEX pattern then set the tag to use and end the loop
      if [[ $FILEEXIFDATE =~ $REGEX ]]; then
        FILEEXIFDATETAG="$i"
        break
      fi
    done

		if [ -z "$FILEEXIFDATETAG" ]
		then
      echo "    $FILE date info not parseable. - 2"
      if [ "$WORKINGDIR" == "$UPLOADREPO" ]; then
        echo    "moving $FILE to $UPLOADREPOFIX"
        mv "$FILE" "$UPLOADREPOFIX"
      fi
    fi
  fi
done

# set read permissions for all users for all files
chmod +r *

echo "...done renaming files"
