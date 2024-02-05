#!/bin/bash

# Backup klasöründen dosyaları geri yükle
# Not: Bu adımların çalışabilmesi için ilgili Docker konteynerlerinin çalışıyor olması gerekmektedir.

# MariaDB veritabanını geri yükle
# docker-compose exec -T mariadb sh -c 'exec mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD"' < ./backup/dump.sql

# Appwrite hacimlerini geri yükle
appwrite_volumes=("cache" "config" "certificates" "functions")
for volume in "${appwrite_volumes[@]}"; do
    docker run --rm --volumes-from "$(docker-compose ps -q appwrite)" -v $PWD/backup:/backup ubuntu bash -c "cd /storage && tar xvf /backup/$volume.tar"
done

# Appwrite_appwrite-mariadb hacmini geri yükle
docker run --rm --volume $PWD/backup:/backup --volume appwrite_appwrite-mariadb:/restore ubuntu tar -xvf /backup/mariadb.tar -C /restore

# appwrite_appwrite-uploads hacmini geri yükle
docker run --rm --volume $PWD/backup:/backup --volume appwrite_appwrite-uploads:/restore ubuntu tar -xvf /backup/uploads.tar -C /restore

# appwrite_appwrite-influxdb hacmini geri yükle
docker run --rm --volume $PWD/backup:/backup --volume appwrite_appwrite-influxdb:/restore ubuntu tar -xvf /backup/influxdb.tar -C /restore

# Appwrite-worker-deletes hacmini geri yükle
docker run --rm --volumes-from "$(docker-compose ps -q appwrite-worker-deletes)" -v $PWD/backup:/backup ubuntu bash -c "cd /storage/builds && tar xvf /backup/builds.tar"

# Konfigürasyon dosyalarını geri yükle
cp ./backup/docker-compose.yml ./
cp ./backup/.env ./
if [ -f ./backup/docker-compose.override.yml ]; then
    cp ./backup/docker-compose.override.yml ./
fi