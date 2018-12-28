#!/bin/bash
CACHE_DIR="/Volumes/NAS-Backup/Pictures/cached"

recurse() {
  for i in "$1"/*; do
    if [ -d "$i" ]; then
      echo "dir: $i"
      recurse "$i" "$2"
    elif [ -f "$i" ]; then
      echo $i
      local cached_file=$(echo "$i" | sed 's/^\/Volumes\/NAS-Backup\/Pictures\///')
      local cached_dir=$(echo "$1" | sed 's/^\/Volumes\/NAS-Backup\/Pictures\///')

      if [ ! -d "$CACHE_DIR/$2/$cached_dir" ]; then
        mkdir -p "$CACHE_DIR/$2/$cached_dir"
      fi

      if [[ $(file -b "$i") =~ JPEG ]]; then
        if [ ! -f "$CACHE_DIR/$2/$cached_file" ]; then
          sips -Z $2 $i --out "$CACHE_DIR/$2/$cached_file"
          #~/src/scripts/cwebp "$CACHE_DIR/$2/$cached_file" -o "$CACHE_DIR/$2/${cached_file%.*}.webp"
          #rm "$CACHE_DIR/$2/$cached_file"
        fi
      fi
    fi
  done
}

SIZE=${2:-375}

echo "caching files ($SIZE) for: $1"

recurse $1 $SIZE
