#!/bin/sh

MIN_SEED_TIME=1209600
COUCHPOTATO_DOWNLOAD_DIR="/mnt/Downloads/Movies"
COUCHPOTATO_DESTINATION_FOLDER="/mnt/Movies"
TRANSMISSION_USER="admin"
TRANSMISSION_PASSWORD="password"

# First delete any empty directories
find ${COUCHPOTATO_DOWNLOAD_DIR} -type d -exec rmdir {} + 2>/dev/null

# Then find all renamed_already files
find ${COUCHPOTATO_DOWNLOAD_DIR} -type f -name "*.renamed_already.ignore" -print0 | xargs -0 ls -t | while read filename
do

  MKV_PATH="${filename%.renamed_already.ignore}".mkv
  MKV=$(basename "$MKV_PATH")
  MOVIE="${MKV%.mkv}"

  # If we can find a corresponding mkv file
  if [ -e "$MKV_PATH" ]; then

    # Try and then find a linked file in the destination dir
    MATCHES=`find ${COUCHPOTATO_DESTINATION_FOLDER} -inum "$(ls -i "$MKV_PATH" | cut -d ' ' -f 1)" | wc -l`

    # We cant find a linked file
    if [ "$MATCHES" -eq 0 ]; then
      echo "$MOVIE - LINK FAILED $MKV has no hardlink!"
    else

      # If we can then try and find an active torrent in transmissions
      TORRENT_ID=`transmission-remote -n ${TRANSMISSION_USER}:${TRANSMISSION_PASSWORD} -l | grep "$MOVIE" | awk '{print $1}'`

      # If we cant find a corresponding torrent in transmission try looking for the parent folder
      if [ -z "$TORRENT_ID" ];then
        PARENT_FOLDER=$(basename $(dirname "$MKV_PATH"))
        TORRENT_ID=`transmission-remote -n ${TRANSMISSION_USER}:${TRANSMISSION_PASSWORD} -l | grep "$PARENT_FOLDER" | awk '{print $1}'`
      fi

      if [ -z "$TORRENT_ID" ];then
        echo "$MOVIE - NO TORRENT FOUND $filename"
      else

        # Then check how long the torrent has been seeding
        SEED_TIME=`transmission-remote -n ${TRANSMISSION_USER}:${TRANSMISSION_PASSWORD} -t ${TORRENT_ID} -i | grep 'Seeding Time' | sed 's/Seeding.*(\(.*\) seconds)/\1/'`

        # If it has been seeding long enough remove it
        if [ "$SEED_TIME" -gt ${MIN_SEED_TIME} ]; then
          echo "$MOVIE - REMOVING OLD TORRENT"
          transmission-remote -n ${TRANSMISSION_USER}:${TRANSMISSION_PASSWORD} -t ${TORRENT_ID} --remove-and-delete >/dev/null
        else
          echo "$MOVIE - STILL SEEDING"
        fi
      fi
    fi

  else

    VAR=$(ls -al "${filename%.renamed_already.ignore}".* | wc -l)

    if [ "$VAR" -gt "1" ];then
      echo "$MOVIE - MULTIPLE FILES";
    else
      echo "$MOVIE - ORPHANED RENAMED IGNORE FILE"
      rm "$filename"
    fi

  fi

done

# Find all unknown files
find ../Movies -type f -name "*.unknown.ignore" -print0 | xargs -0 ls -t | while read filename
do

  VAR=$(ls -al "${filename%.unknown.ignore}".* | wc -l)
  if [ "$VAR" -gt "1" ];then
    echo "UNKNOWN $filename";
  else
    echo "ORPHANED UNKNOWN IGNORE FILE $filename"
    rm "$filename"
  fi

done

# Find all exists files
find ../Movies -type f -name "*.exists.ignore" -print0 | xargs -0 ls -t | while read filename
do

  VAR=$(ls -al "${filename%.exists.ignore}".* | wc -l)
  if [ "$VAR" -gt "1" ];then
    echo "EXISTS $filename";
  else
    echo "ORPHANED EXISTS IGNORE FILE $filename"
    rm "$filename"
  fi

done
