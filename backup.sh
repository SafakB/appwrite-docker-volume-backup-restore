#!/bin/bash

# Backup klasörünü oluştur
mkdir -p ./backup

# MariaDB veritabanı yedeğini al
docker-compose exec mariadb sh -c 'exec mysqldump --all-databases --add-drop-database -u"$MYSQL_USER" -p"$MYSQL_PASSWORD"' > ./backup/dump.sql

# Appwrite hacimlerini yedekle
appwrite_volumes=("uploads" "cache" "config" "certificates" "functions")
for volume in "${appwrite_volumes[@]}"; do
    docker run --rm --volumes-from "$(docker-compose ps -q appwrite)" -v $PWD/backup:/backup ubuntu bash -c "cd /storage/$volume && tar cvf /backup/$volume.tar ."
done

# Appwrite_appwrite-mariadb hacmini yedekle
docker run --rm --volume appwrite_appwrite-mariadb:/var/lib/mysql --volume $PWD/backup:/backup ubuntu tar -cvf /backup/mariadb.tar -C /var/lib/mysql .

# appwrite_appwrite-influxdb hacmini yedekle
docker run --rm --volume appwrite_appwrite-influxdb:/var/lib/docker/volumes/appwrite_appwrite-influxdb/_data --volume $PWD/backup:/backup ubuntu tar -cvf /backup/influxdb.tar -C /var/lib/docker/volumes/appwrite_appwrite-influxdb/_data .

# Appwrite-worker-deletes hacmini yedekle
docker run --rm --volumes-from "$(docker-compose ps -q appwrite-worker-deletes)" -v $PWD/backup:/backup ubuntu bash -c "cd /storage/builds && tar cvf /backup/builds.tar ."

# Konfigürasyon dosyalarını kopyala
cp docker-compose.yml ./backup/
cp .env ./backup/
if [ -f docker-compose.override.yml ]; then
    cp docker-compose.override.yml ./backup/
fi