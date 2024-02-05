# Geri yüklenecek backup klasörünü tanımla
$backupFolder = ".\backup"

# MariaDB veritabanını geri yükle
#Get-Content "${backupFolder}\dump.sql" | docker-compose exec -T mariadb sh -c 'exec mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD"'

# Appwrite hacimlerini geri yükle
$appwrite_volumes = @("cache", "config", "certificates", "functions")
foreach ($volume in $appwrite_volumes) {
    docker run --rm --volumes-from $(docker compose ps -q appwrite) -v "${PWD}\${backupFolder}:/backup" ubuntu bash -c "cd /storage && tar xvf /backup/$volume.tar"
}

# Appwrite_appwrite-mariadb hacmini geri yükle
docker run --rm --volume "${PWD}\${backupFolder}:/backup" --volume appwrite_appwrite-mariadb:/restore ubuntu tar -xvf /backup/mariadb.tar -C /restore

# appwrite_appwrite-uploads hacmini geri yükle
docker run --rm --volume "${PWD}\${backupFolder}:/backup" --volume appwrite_appwrite-uploads:/restore ubuntu tar -xvf /backup/uploads.tar -C /restore

# appwrite_appwrite-influxdb hacmini geri yükle
docker run --rm --volume "${PWD}\${backupFolder}:/backup" --volume appwrite_appwrite-influxdb:/restore ubuntu tar -xvf /backup/influxdb.tar -C /restore

# Appwrite-worker-deletes hacmini geri yükle
docker run --rm --volumes-from $(docker compose ps -q appwrite-worker-deletes) -v "${PWD}\${backupFolder}:/backup" ubuntu bash -c "cd /storage/builds && tar xvf /backup/builds.tar"

# Konfigürasyon dosyalarını geri yükle
Copy-Item "${backupFolder}\docker-compose.yml" -Destination .
Copy-Item "${backupFolder}\.env" -Destination .
if (Test-Path "${backupFolder}\docker-compose.override.yml") {
    Copy-Item "${backupFolder}\docker-compose.override.yml" -Destination .
}