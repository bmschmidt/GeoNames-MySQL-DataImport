
downloads:
	chmod +x geonames_importer.sh
	./geonames_importer.sh -a download-data
	touch $@

database:
	./geonames_importer.sh -a create-db
	./geonames_importer.sh -a import-dumps
	touch $@
