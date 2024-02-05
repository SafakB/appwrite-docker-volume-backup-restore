# Geçerli tarih ve saati formatlayarak yedek adını oluştur
$backupName = "backup_" + (Get-Date -Format "yyyyMMdd_HHmm")

# Backup klasörünü oluştur
New-Item -ItemType Directory -Force -Path .\$backupName

# MariaDB veritabanı yedeğini al
docker-compose exec mariadb sh -c 'exec mysqldump --all-databases --add-drop-database -u"$MYSQL_USER" -p"$MYSQL_PASSWORD"' > ".\${backupName}\dump.sql"

# Appwrite hacimlerini yedekle
$appwrite_volumes = @("uploads", "cache", "config", "certificates", "functions")
foreach ($volume in $appwrite_volumes) {
    docker run --rm --volumes-from $(docker compose ps -q appwrite) -v "${PWD}\${backupName}:/backup" ubuntu bash -c "cd /storage/$volume && tar cvf /backup/$volume.tar ."
}

# Appwrite_appwrite-mariadb hacmini yedekle
docker run --rm --volume appwrite_appwrite-mariadb:/var/lib/mysql --volume "${PWD}\${backupName}:/backup" ubuntu tar -cvf /backup/mariadb.tar -C /var/lib/mysql .

# appwrite_appwrite-influxdb hacmini yedekle
docker run --rm --volume appwrite_appwrite-influxdb:/var/lib/docker/volumes/appwrite_appwrite-influxdb/_data --volume "${PWD}\${backupName}:/backup" ubuntu tar -cvf /backup/influxdb.tar -C /var/lib/docker/volumes/appwrite_appwrite-influxdb/_data .

# Appwrite-worker-deletes hacmini yedekle
docker run --rm --volumes-from $(docker compose ps -q appwrite-worker-deletes) -v "${PWD}\${backupName}:/backup" ubuntu bash -c "cd /storage/builds && tar cvf /backup/builds.tar ."

# Konfigürasyon dosyalarını kopyala
Copy-Item docker-compose.yml -Destination ".\${backupName}"
Copy-Item .env -Destination ".\${backupName}"
if (Test-Path docker-compose.override.yml) {
    Copy-Item docker-compose.override.yml -Destination ".\${backupName}"
}