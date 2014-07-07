#!/bin/bash

# Default values for database variables.
dbhost="localhost"
dbport=3306
dbname="geonames"
defaults="~/.my.cnf"

dir=$( cd "$( dirname "$0" )" && pwd )

logo() {
	echo "================================================================================================"
	echo "                           G E O N A M E S    D A T A    I M P O R T E R                        "
	echo "================================================================================================"
}

usage() {
	logo
	echo "Usage 1: " $0 "--download-data"
	echo "In this mode the current GeoNames.org's dumps are downloaded to the local machine."
	echo
	echo "Usage 2: " $0 "-a <action> -u <user> -p <password> -h <host> -r <port> -n <dbname>"
	echo " This is to operate with the geographic database"
    echo " Where <action> can be one of this: "
	echo "    download-data Downloads the last packages of data available in GeoNames."
    echo "    create-db Creates the mysql database structure with no data."
    echo "    import-dumps Imports geonames data into db. A database is previously needed for this to work."
	echo "    drop-db Removes the db completely."
    echo "    truncate-db Removes geonames data from db."
    echo
    echo " The rest of parameters indicates the following information:"
	echo "    -u <user>     User name to access database server."
	echo "    -p <password> User password to access database server."
	echo "    -h <host>     Data Base Server address (default: localhost)."
	echo "    -r <port>     Data Base Server Port (default: 3306)"
	echo "    -n <dbname>  Data Base Name for the geonames.org data (default: geonames)"
	echo "================================================================================================"
    exit -1
}

download_geonames_data() {
	echo "Downloading GeoNames.org data..." 
	wget http://download.geonames.org/export/dump/allCountries.zip
	wget http://download.geonames.org/export/dump/alternateNames.zip
	wget http://download.geonames.org/export/dump/hierarchy.zip
	wget http://download.geonames.org/export/dump/admin1CodesASCII.txt
	wget http://download.geonames.org/export/dump/admin2Codes.txt
	wget http://download.geonames.org/export/dump/featureCodes_en.txt
	wget http://download.geonames.org/export/dump/timeZones.txt
	wget http://download.geonames.org/export/dump/countryInfo.txt
	wget -O allCountries_zip.zip http://download.geonames.org/export/zip/allCountries.zip
	unzip allCountries.zip
	unzip alternateNames.zip
	unzip hierarchy.zip
	unzip allCountries_zip.zip -d ./zip/
	rm allCountries.zip
	rm alternateNames.zip
	rm hierarchy.zip
	rm allCountries_zip.zip
}

if [ $# -lt 1 ]; then
	usage
	exit 1
fi

logo

# Deals operation mode 1 (Download data bundles from geonames.org)
if { [ $# == 1 ] && [ "$1" == "--download-data" ]; } then
    download_geonames_data
	exit 0
fi

# Deals with operation mode 2 (Database issues...)
# Parses command line parameters.
while getopts "a:d:h:r:n:" opt; 
do
    case $opt in
        a) action=$OPTARG ;;
        d) defaults=$OPTARG ;;
        h) dbhost=$OPTARG ;;
        r) dbport=$OPTARG ;;
        n) dbname=$OPTARG ;;
    esac
done


case $action in
    download-data)
        download_geonames_data
        exit 0
    ;;
esac

echo "Database parameters being used..."
echo "Orden: " $action
echo "Defaults file: " $defaults
echo "DB Host: " $dbhost
echo "DB Port: " $dbport
echo "DB Name: " $dbname

case "$action" in
    create-db)
        echo "Creating database $dbname..."
        mysql --defaults-file=$defaults -h $dbhost -P $dbport -Bse "DROP DATABASE IF EXISTS $dbname;"
        mysql  --defaults-file=$defaults -h $dbhost -P $dbport -Bse "CREATE DATABASE $dbname DEFAULT CHARACTER SET utf8;" 
        mysql  --defaults-file=$defaults -h $dbhost -P $dbport -Bse "USE $dbname;" 
        mysql  --defaults-file=$defaults -h $dbhost -P $dbport $dbname < $dir/geonames_db_struct.sql
    ;;
        
    import-dumps)
        echo "Importing geonames dumps into database $dbname"
        mysql  --defaults-file=$defaults -h $dbhost -P $dbport --local-infile=1 $dbname < $dir/geonames_import_data.sql
    ;;    
    
    drop-db)
        echo "Dropping $dbname database"
        mysql  --defaults-file=$defaults -h $dbhost -P $dbport  -Bse "DROP DATABASE IF EXISTS $dbname;"
    ;;
        
    truncate-db)
        echo "Truncating \"geonames\" database"
        mysql --defaults-file=$defaults -h $dbhost -P $dbport $dbname < $dir/geonames_truncate_db.sql
    ;;
esac

if [ $? == 0 ]; then 
	echo "[OK]"
else
	echo "[FAILED]"
fi

exit 0
