#!/usr/bin/env bash
set -euo pipefail

IN=planet-261116.osm.pbf
OUT=planet-261116-filtered.osm.pbf

# 1) access_restrictions_linestring
#    highway in (...) AND any of access / foot / access:conditional / foot:conditional
osmium tags-filter "$IN" \
  w/highway=path,footway,track,steps,pedestrian \
  -o tmp_highways.osm.pbf --overwrite

osmium tags-filter tmp_highways.osm.pbf \
  w/access,foot,access:conditional,foot:conditional \
  -o part_access.osm.pbf --overwrite
rm -f tmp_highways.osm.pbf

# 2) outdoor_name_polygon + outdoor_name_linestring
#    (natural/landuse polygons + natural=valley lines) AND name
osmium tags-filter "$IN" \
  w/natural=scree,fell,bare_rock,glacier,grassland r/natural=scree,fell,bare_rock,glacier,grassland \
  w/landuse=meadow r/landuse=meadow \
  w/natural=valley \
  -o tmp_named_candidates.osm.pbf --overwrite

osmium tags-filter tmp_named_candidates.osm.pbf \
  w/name r/name \
  -o part_names.osm.pbf --overwrite
rm -f tmp_named_candidates.osm.pbf

# 3) Plain-OR tables in a single pass:
#    POIs, path features, hiking/foot route relations + member ways
osmium tags-filter "$IN" \
  nwr/information=board,map,office,visitor_centre,guidepost \
  nwr/tower:type=observation,communication,lighting,bell_tower \
  nwr/shelter_type=basic_hut \
  nwr/tourism=alpine_hut,wilderness_hut,picnic_site,viewpoint \
  nwr/amenity=shelter,drinking_water,bench,lounger,shower,fountain,water_point \
  nwr/leisure=firepit \
  nwr/natural=cave_entrance,spring \
  nwr/waterway=waterfall \
  nwr/castle_type=fortress \
  nwr/historic=castle,memorial,monument,wayside_cross,wayside_shrine \
  nwr/ford=yes,stepping_stones \
  nwr/emergency=mountain_rescue \
  nwr/man_made=water_well,water_tap,cross,obelisk \
  w/assisted_trail,safety_rope,rungs \
  r/route=hiking,foot \
  -o part_poi_features_hiking.osm.pbf --overwrite

# 4) Merge, then remove the parts
osmium merge \
  part_access.osm.pbf \
  part_names.osm.pbf \
  part_poi_features_hiking.osm.pbf \
  -o "$OUT" --overwrite
rm -f part_access.osm.pbf part_names.osm.pbf part_poi_features_hiking.osm.pbf
