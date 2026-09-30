-- etldoc: layer_city[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_city | <z2_14> z2-z14+" ] ;

-- etldoc: osm_city_point -> layer_city:z2_14
CREATE OR REPLACE FUNCTION layer_city(bbox geometry, zoom_level int, pixel_width numeric)
    RETURNS TABLE
            (
                osm_id   bigint,
                geometry geometry,
                name     text,
                name_en  text,
                name_de  text,
                tags     hstore,
                place    city_place,
                "rank"   int,
                capital  int
            )
AS
$$
SELECT *
FROM (
         SELECT osm_id,
                geometry,
                name,
                COALESCE(NULLIF(name_en, ''), name) AS name_en,
                COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
                tags,
                place,
                "rank",
                normalize_capital_level(capital) AS capitalnum
         FROM osm_city_point
         WHERE geometry && bbox
           AND (
            ((capital = 'yes' OR capital = '2') AND zoom_level > 2)
            OR 
            (zoom_level > 3 AND "rank" <= zoom_level + 1)
           )
           
           
             
     ) AS city_all;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;
