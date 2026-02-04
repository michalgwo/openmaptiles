#!/bin/bash
set -euo pipefail

osm_continent=$1
osm_country=""
osm_region=""

if [ $# -gt 1 ]; then
osm_country=$2
    if [ $# -gt 2 ]; then
        osm_region=$3
    fi
fi

rm data/europe data/africa data/australia-oceania data/asia data/antarctica data/central-america data/north-america data/south-america -rf
make clean
make

if [ -n "$osm_region" ]; then
    make download area=${osm_continent}/${osm_country}/${osm_region}
elif [ -n "$osm_country" ]; then
    make download area=${osm_continent}/${osm_country}
else
    make download area=${osm_continent}
fi

make import-osm-outdoor
make import-sql
make generate-tiles-pg

if [ "$osm_region" == "georgia" ] && [ "$osm_country" == "us" ]; then
    cp data/tiles.mbtiles /mnt/d/nailthetrail/mbtiles-outdoor/${osm_continent}/${osm_country}/${osm_region}.mbtiles
elif [ -n "$osm_region" ]; then
    cp data/tiles.mbtiles /mnt/d/nailthetrail/mbtiles-outdoor/${osm_continent}/${osm_country}/${osm_region}.mbtiles
elif [ -n "$osm_country" ]; then
    cp data/tiles.mbtiles /mnt/d/nailthetrail/mbtiles-outdoor/${osm_continent}/${osm_country}.mbtiles
else
    cp data/tiles.mbtiles /mnt/d/nailthetrail/mbtiles-outdoor/${osm_continent}.mbtiles
fi