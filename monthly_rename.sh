#!/bin/bash

MONTH="$1"

cd /Volumes/NAS-Backup/Pictures/2016/$MONTH

exiftool -r "-FileModifyDate<DateTimeOriginal" .

find . -iname "*.mov" | while read FILE
do
  exiftool "-FileModifyDate<CreationDate" $FILE
done

find . -depth -name '* *' | while IFS= read -r f ; do mv -i "$f" "$(dirname "$f")/$(basename "$f"|tr ' ' _)" ; done
