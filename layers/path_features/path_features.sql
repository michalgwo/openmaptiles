CREATE OR REPLACE FUNCTION layer_path_features(bbox geometry, zoom_level int)
RETURNS TABLE
(
  geometry geometry, 
  osm_id BIGINT,
  assisted_trail TEXT
)
AS
$$
SELECT geometry,
       osm_id,
       'yes' AS assisted_trail
FROM (
         SELECT *
         FROM osm_path_features_linestring
         WHERE geometry && bbox
           AND zoom_level >= 12 AND (
            (assisted_trail IS NOT NULL AND assisted_trail <> 'no')
            OR (safety_rope IS NOT NULL AND safety_rope <> 'no')
            OR (rungs IS NOT NULL AND rungs <> 'no')
          )
     ) AS path_features_union
$$ LANGUAGE SQL STABLE
                PARALLEL SAFE;