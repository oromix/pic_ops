#!/bin/bash

PICTURERDIRS=("/Users/jess/Dropbox/Camera Uploads" "/Users/jess/Adams Dropbox/Dropbox/Camera Uploads" "/Users/jess/Pictures/PhotoSync/jess" "/Users/jess/Pictures/PhotoSync/adam")
UPLOADREPO="/Users/jess/.picture_upload_repo"
UPLOADREPOFIX="/Users/jess/.picture_upload_repo_fix"
PLUPLOAD="/Users/jess/Pictures/PictureLife Upload"
SCREENFOLDER="/Users/jess/Pictures/Screenshots - Mobile"
VOLUME="/Volumes/NAS-Backup"
CACHEDIR="/Volumes/NAS-Backup/Pictures/cached"
APUPLOAD="$VOLUME/Pictures"
COUNTER=1
LIMIT=500
SKIPPLPRUNE=true
SKIPPL=true
DEBUG=false

echo ""
echo "####"
echo "[$(date +%m.%d.%Y-%H:%M)] - Starting picture processing"
echo ""
echo "Copying files from sources"

for i in "${PICTURERDIRS[@]}"
do
  #Copy images/movies to upload repo for processing
  cd "$i"
  echo "  Copying files from $i"
  find * | while read FILE
  do
    if [ "$COUNTER" -le $LIMIT ]; then
      #lowercase filename
      NEWFILE="$(echo $FILE | tr '[:upper:]' '[:lower:]' | tr '_' '-')"

      echo "    #$COUNTER - copying $FILE to $UPLOADREPO/$NEWFILE"
      cp -p "$FILE" "$UPLOADREPO/$NEWFILE"

      URPATH="$UPLOADREPO/$NEWFILE"
      if [[ -e "$URPATH" ]]
      then
        echo "      removing $FILE from $i"
        if [ "$DEBUG" = false ]; then
          rm "$FILE"
        else
          echo "        debug - rm $FILE"
        fi
        let "COUNTER += 1"
      fi
    fi
  done
done
echo "...done copying files"

#Process images/movies from upload repo
cd "$UPLOADREPO"

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
    if [ "$DEBUG" = false ]; then
      rm "$FILE"
    else
      echo "    debug - rm $FILE"
    fi
	fi
done
echo "...done processing screenshots"

#Rename files in upload folder
/Users/jess/bin/rename_pictures.sh

LIMIT=1000

echo ""
echo "Processing images"
#Process JPG/TIFF images and MOV files; send a copy to the NAS and a copy to PictureLife via the local upload folder
find . -iname "*.jpg" -o -iname "*.tif" -o -iname "*.tiff" -o -iname "*.mov" -o -iname "*.mp4"  | while read FILE
do
	if [ "$COUNTER" -le $LIMIT ]; then
		echo "#$COUNTER - processing $FILE..."

		#Parse out image date information
    FYEAR="${FILE:2:4}"
    FMONTH="${FILE:7:2}"
    FDAY="${FILE:10:2}"

    # Ensure we have the correct info
		if [ -z "$FYEAR" -o -z "$FMONTH" -o -z "$FDAY" ]
		then
      # If the date parts dont exist then move the file to UPLOADREPOFIX and move on to the next iteration
			echo "  filename does not contain date info. moving to fix repo."
      if [ "$DEBUG" = false ]; then
        mv "$FILE" "$UPLOADREPOFIX"
      else
        echo "    debug - mv $FILE to $UPLOADREPOFIX"
      fi
      continue
		fi

		DEST="$APUPLOAD/$FYEAR/$FMONTH/$FDAY"
    CACHEDEST="$CACHEDIR/375/$FYEAR/$FMONTH/$FDAY"
		APFULLPATH="$DEST/$FILE"

		if /sbin/mount | grep "on ${VOLUME}" > /dev/null
		then
			#Copy to Nas Backup dir using Year/Month/Day/FILE
			if [[ ! -d "$DEST" ]]; then
				mkdir -p "$DEST"
			fi
			if [[ ! -d "$CACHEDEST" ]]; then
				mkdir -p "$CACHEDEST"
			fi
			if [[ ! -e "$APFULLPATH" ]]; then
				echo "  copying to $DEST"
        if [ "$DEBUG" = false ]; then
          cp -p "$FILE" "$DEST"
          # make cached versions
          if [[ $(file -b "$FILE") =~ JPEG ]]; then
            sips -Z 375 $FILE --out "$CACHEDEST/$FILE"
            ~/src/scripts/cwebp "$CACHEDEST/$FILE" -o "$CACHEDEST/${FILE%.*}.webp"
            rm "$CACHEDEST/$FILE"
          fi
        else
          echo "    debug - cp $FILE to $DEST"
        fi
			else
        #LOCALMD5=$(md5 -q "$FILE")
        #echo "$LOCALMD5"
        #REMOTEMD5=$(md5 -q "$APFULLPATH")
        #echo "$REMOTEMD5"
        #if [ "$LOCALMD5" = "$REMOTEMD5" ]; then
          #echo "  file already exists in $DEST. md5 match"
          echo "  file already exists in $DEST."
        #else
          #echo "  file name alread exists in $DEST, but MD5 does not match. copying to $UPLOADREPOFIX"
          #cp -p "$FILE" "$UPLOADREPOFIX/duplicates"
        #fi
			fi
		else
			echo "$VOLUME not mounted"
			##Exit entire script due to the volume not being available;
			#Commenting this exit line out because it does not allow anything else to be processed;
			#The only downfall is that after a certain time the files will start getting added to PictureLifeUpload again
			#exit
		fi

    if [ "$SKIPPL" = false ]; then
      #Test if file already exists in PictureLife Upload
      PLUPPATH="$PLUPLOAD/$FILE"
      if [[ ! -e $PLUPPATH ]]; then
        # If the FILE does not exist in the Picture Life upload folder then copy it to the Picture Life upload folder
        echo "  uploading to PictureLife"
        if [ "$DEBUG" = false ]; then
          cp -p -n "$FILE" "$PLUPLOAD"
        else
          echo "    debug - cp $FILE to $PLUPLOAD"
        fi
        let "COUNTER += 1"
      else
        echo "  file already exists in PictureLife Upload.  Moving on..."
      fi
    else
      echo "  skipping PictureLife Upload"
      let "COUNTER += 1"
    fi

		#Test if the file actually exists on the NAS
		if [ -e "$APFULLPATH" ]
		then
      # If FILE exists on DEST
			echo "  removing original file: $FILE"
      if [ "$DEBUG" = false ]; then
        rm "$FILE"
      else
        echo "    debug - rm $FILE"
      fi
		else
			echo "  WARNING: file did not end up in either $DEST; retaining original copy"
		fi
	fi
done
echo "...done processing images"

if [ "$DEBUG" = true ]; then
  exit 1
fi
if [ "$SKIPPLPRUNE" = true ]; then
  echo ""
  echo "Skip Prunning"
  echo ""
  echo "[$(date +%m.%d.%Y-%H:%M)] - All Done"
  echo "####"
  echo ""
  exit 1
fi

echo ""
echo "Pruning $PLUPLOAD files"
#Cleanup pics in Picture Life upload folder that are older than 28 days
cd "$PLUPLOAD"

find . -iname "*.jpg" -o -iname "*.mov" -o -iname "*.tiff" | while read FILE
do
	FDATE=$(exiftool -d "%Y%m%d" -dateTimeOriginal -S -s "$FILE")
	if [ -z "$FDATE" ]
	then
		FDATE="${FILE:2:4}${FILE:7:2}${FILE:10:2}"
	fi
	DATELIMIT=$(date -v-28d "+%Y%m%d")
	if [ "$FDATE" -le "$DATELIMIT" ]; then
		echo "  removing file: $FILE"
    if [ "$DEBUG" = false ]; then
      rm "$FILE"
    else
      echo "    debug - rm $FILE"
    fi
	fi
done
echo "...done pruning files"

echo ""
echo "[$(date +%m.%d.%Y-%H:%M)] - All Done"
echo "####"
echo ""
