#!/bin/bash
set -euo pipefail

osm_continent=$1
osm_country=$2
osm_region=""
import_data=""
slim=""

if [ $# -gt 2 ]; then
    if [ "$3" = "true" ]; then
        import_data=true
    elif [ "$3" = "slim" ]; then
        slim=true
    else
        if [ $# -eq 4 ]; then
            if [ "$4" = "true" ]; then
                import_data=true
            elif [ "$4" = "slim" ]; then
                slim=true
            fi
        fi
        osm_region=$3
    fi
fi

rm data/europe data/africa data/australia-oceania data/asia data/antarctica data/central-america data/north-america data/south-america -rf
make clean
make

if [ -n "$osm_region" ]; then
    make download area=${osm_continent}/${osm_country}/${osm_region}
    if [ "$osm_country" = "us" ]; then
        ./import-us-woodlands.sh $osm_region
    fi
else
    make download area=${osm_continent}/${osm_country}
fi

if [ -n "$import_data" ]; then
    echo "importing data"
    make import-data
fi


if [ -n "$slim" ]; then
    make import-osm slim=yes
else
    make import-osm
fi

make import-wikidata
make import-sql
make generate-tiles-pg

if [ "$osm_region" == "georgia" ] && [ "$osm_country" == "us" ]; then
    tile-join -pk -o /mnt/d/nailthetrail/mbtiles/${osm_continent}/${osm_country}/${osm_region}.mbtiles data/tiles.mbtiles ../opencontourmaptiles/data/${osm_region}-us.mbtiles
elif [ -n "$osm_region" ]; then
    if [ "$osm_region" == "flevoland" ]; then
        cp data/tiles.mbtiles /mnt/d/nailthetrail/mbtiles/${osm_continent}/${osm_country}/${osm_region}.mbtiles
    else
        tile-join -pk -o /mnt/d/nailthetrail/mbtiles/${osm_continent}/${osm_country}/${osm_region}.mbtiles data/tiles.mbtiles ../opencontourmaptiles/data/${osm_region}.mbtiles
    fi
else
    tile-join -pk -o /mnt/d/nailthetrail/mbtiles/${osm_continent}/${osm_country}.mbtiles data/tiles.mbtiles ../opencontourmaptiles/data/${osm_country}.mbtiles
fi