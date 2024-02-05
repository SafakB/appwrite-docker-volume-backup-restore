#!/bin/bash

# Create the backup name by formatting the current date and time
backupName="backup_$(date +"%Y%m%d_%H%M")"

# Create the Backup folder
mkdir -p ./$backupName

# Backup MariaDB database
docker-compose exec mariadb sh -c 'exec mysqldump --all-databases --add-drop-database -u"$MYSQL_USER" -p"$MYSQL_PASSWORD"' > "./${backupName}/dump.sql"

# Backup Appwrite volumes
appwrite_volumes=("uploads" "cache" "config" "certificates" "functions")
for volume in ${appwrite_volumes[@]}; do
    docker run --rm --volumes-from $(docker compose ps -q appwrite) -v "${PWD}/${backupName}:/backup" ubuntu bash -c "cd /storage/$volume && tar cvf /backup/$volume.tar ."
done

# Backup appwrite_appwrite-mariadb volume
docker run --rm --volume appwrite_appwrite-mariadb:/var/lib/mysql --volume "${PWD}/${backupName}:/backup" ubuntu tar -cvf /backup/mariadb.tar -C /var/lib/mysql .

# Backup appwrite_appwrite-influxdb volume
docker run --rm --volume appwrite_appwrite-influxdb:/var/lib/docker/volumes/appwrite_appwrite-influxdb/_data --volume "${PWD}/${backupName}:/backup" ubuntu tar -cvf /backup/influxdb.tar -C /var/lib/docker/volumes/appwrite_appwrite-influxdb/_data .

# Backup appwrite-worker-deletes volume
docker run --rm --volumes-from $(docker compose ps -q appwrite-worker-deletes) -v "${PWD}/${backupName}:/backup" ubuntu bash -c "cd /storage/builds && tar cvf /backup/builds.tar ."

# Copy configuration files
cp docker-compose.yml "./${backupName}"
cp .env "./${backupName}"
if [ -f docker-compose.override.yml ]; then
    cp docker-compose.override.yml "./${backupName}"
fi