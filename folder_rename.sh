#!/bin/bash

TARGET=$1

cd $TARGET

OLDIFS="${IFS}"
IFS="\n"
find -E . -type d -regex "\.\/[0-9]{4}-[0-9]{2}-[0-9]{2}" | while read file
do
  dirname=$(echo "$file" | sed -E 's/^.{2}//')
  FYEAR="${dirname:0:4}"
  FMONTH="${dirname:5:2}"
  FDAY="${dirname:8:2}"

  path="/Volumes/NAS-Backup/Pictures/${FYEAR}/${FMONTH}"
  if [ ! -e $path ]; then
    mkdir $path
  fi

  echo "mv \"${TARGET}/${dirname}\" \"/Volumes/NAS-Backup/Pictures/${FYEAR}/${FMONTH}/${FDAY}\""
  echo "mv \"${TARGET}/${dirname}\" \"/Volumes/NAS-Backup/Pictures/${FYEAR}/${FMONTH}/${FDAY}\"" >> "/Users/jess/.pic_ops/rename_day_dirs_${FYEAR}.sh"
done
