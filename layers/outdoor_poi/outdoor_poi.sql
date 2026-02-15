CREATE OR REPLACE FUNCTION layer_outdoor_poi(bbox geometry, zoom_level integer, pixel_width numeric)
    RETURNS TABLE
            (
                osm_id   bigint,
                geometry geometry,
                name     text,
                name_en  text,
                name_pl  text,
                tags     hstore,
                drinking_water    text,
                class    text,
                subclass text
            )
AS
$$
SELECT ABS(osm_id),
       geometry,
       NULLIF(name, '') AS name,
       NULLIF(COALESCE(NULLIF(name_en, ''), name), '') AS name_en,
       NULLIF(COALESCE(NULLIF(name_pl, ''), name, name_en), '') AS name_pl,
       tags,
       NULLIF(drinking_water, '') AS drinking_water,
       mapping_key AS class,
       subclass
FROM (
         SELECT *
         FROM osm_outdoor_poi_point
         WHERE geometry && bbox
           AND zoom_level >= 14

         UNION ALL

         SELECT *
         FROM osm_outdoor_poi_polygon
         WHERE geometry && bbox 
			      AND zoom_level >= 14

     ) AS outdoor_poi_union
$$ LANGUAGE SQL STABLE
                PARALLEL SAFE;