#!/bin/bash

# TODO: Fill in these three values to suit your deployment.
export MYSQL_PWD="SOME_PASSWORD"
db="demo_db"
user="demo_user"

# The remaining values are ok as they are.
osm_url="https://s3.amazonaws.com/goddard.datasets/osm.csv.gz"
osm_kv_url="https://s3.amazonaws.com/goddard.datasets/osm_k_v.csv.gz"
db_host="127.0.0.1"

# Load the osm_load table.
curl $osm_url | zcat - | mysql --local-infile=1 -h $db_host -u $user $db \
  -e "LOAD DATA LOCAL INFILE '/dev/stdin' INTO TABLE osm_load FIELDS TERMINATED BY ',';"

# Load the osm table from that landing table.
cat <<EndOfSQL | mysql -h $db_host -u $user $db
INSERT INTO osm
SELECT id, STR_TO_DATE(date_time, '%Y-%m-%dT%H:%i:%sZ'), uid, lat, lon, name
FROM osm_load
ORDER BY id ASC;
EndOfSQL

# Drop that load table.
echo "DROP TABLE osm_load;" | mysql -h $db_host -u $user $db

# Load the osm_k_v table.
curl $osm_kv_url | zcat - | mysql --local-infile=1 -h $db_host -u $user $db \
  -e "LOAD DATA LOCAL INFILE '/dev/stdin' INTO TABLE osm_k_v FIELDS TERMINATED BY ',';"

