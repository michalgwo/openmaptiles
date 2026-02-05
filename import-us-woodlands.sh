#!/bin/bash
set -euo pipefail
set -a
source .env
set +a

formatted_name=$(echo $1 | perl -pe 's/(\w+)/\L\u$1/g; s/Of/of/g; s/-/_/g')

make start-db
cd data
wget https://prd-tnm.s3.amazonaws.com/StagedProducts/LndCvr/GDB/LNDCVR_${formatted_name}_State_GDB.zip

ogr2ogr \
      -progress \
      -f Postgresql \
      -s_srs EPSG:4326 \
      -t_srs EPSG:3857 \
      -lco OVERWRITE=YES \
      -lco GEOMETRY_NAME=geometry \
      -overwrite \
      -nln "usgs_woodland" \
      -nlt geometry \
      --config PG_USE_COPY YES \
      "postgresql://openmaptiles:openmaptiles@localhost:5432/openmaptiles" \
      "LNDCVR_${formatted_name}_State_GDB.zip"

rm LNDCVR_${formatted_name}_State_GDB.zip
cd ..