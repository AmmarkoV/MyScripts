#!/bin/bash 

# === CONFIG ===
TARGET_USER="ammar"
TARGET_HOST="nvassilikopoulos"
TARGET_DIR="/media/nvasilik/Magician/ammar/backup/ammar_$(date +%F)"

LOGFILE="backup_errors.log"

echo "Starting emergency backup to $TARGET_HOST..."

# Create remote directory
ssh ${TARGET_USER}@${TARGET_HOST} "mkdir -p ${TARGET_DIR}"

# Function to copy safely
copy_dir () {
    SRC=$1
    DEST=$2

    echo "Backing up $SRC ..."
    rsync -avh --progress --ignore-errors \
        --exclude={"/proc/*","/sys/*","/dev/*","/run/*","/tmp/*"} \
        "$SRC" "${TARGET_USER}@${TARGET_HOST}:${DEST}" \
        2>>$LOGFILE
}

# === BACKUP TARGETS ===

copy_dir /etc        ${TARGET_DIR}/
#copy_dir /home       ${TARGET_DIR}/
copy_dir /var/lib    ${TARGET_DIR}/
copy_dir /usr/local  ${TARGET_DIR}/
copy_dir /opt        ${TARGET_DIR}/

echo "Backup completed (with possible errors). Check $LOGFILE"


exit 0
