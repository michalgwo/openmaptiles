DROP TRIGGER IF EXISTS trigger_store_poly ON osm_outdoor_name_polygon;
DROP TRIGGER IF EXISTS trigger_flag_poly ON osm_outdoor_name_polygon;
DROP TRIGGER IF EXISTS trigger_store_line ON osm_outdoor_name_linestring;
DROP TRIGGER IF EXISTS trigger_flag_line ON osm_outdoor_name_linestring;
DROP TRIGGER IF EXISTS trigger_refresh ON outdoor_name.updates;

CREATE SCHEMA IF NOT EXISTS outdoor_name;

-- 1. Tracking Tables for Incremental Updates
CREATE TABLE IF NOT EXISTS outdoor_name.osm_ids
(
    osm_id bigint,
    is_old bool,
    PRIMARY KEY (osm_id, is_old)
);

CREATE TABLE IF NOT EXISTS outdoor_name.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);

-- 2. Line Features (Valleys)
CREATE INDEX IF NOT EXISTS osm_outdoor_name_linestring_update_idx ON osm_outdoor_name_linestring (name, ST_IsValid(geometry))
    WHERE name <> '' AND ST_IsValid(geometry);

CREATE OR REPLACE VIEW osm_outdoor_lineline_view AS
SELECT osm_id,
       geometry,
       name,
       name_en,
       name_de,
       update_tags(tags, geometry) AS tags,
       "natural" AS class
FROM osm_outdoor_name_linestring
WHERE name <> ''
  AND ST_IsValid(geometry)
  AND "natural" = 'valley';

DROP TABLE IF EXISTS osm_outdoor_lineline CASCADE;

CREATE TABLE IF NOT EXISTS osm_outdoor_lineline AS
SELECT *
FROM osm_outdoor_lineline_view;

DO
$$
    BEGIN
        ALTER TABLE osm_outdoor_lineline
            ADD CONSTRAINT osm_outdoor_lineline_pk PRIMARY KEY (osm_id);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'primary key osm_outdoor_lineline_pk already exists in osm_outdoor_lineline.';
    END;
$$;
CREATE INDEX IF NOT EXISTS osm_outdoor_lineline_geometry_idx ON osm_outdoor_lineline USING gist (geometry);


-- 3. Point Features (Scree, Fell, Bare Rock, Glacier, Meadow)
CREATE INDEX IF NOT EXISTS osm_outdoor_name_polygon_update_idx ON osm_outdoor_name_polygon (name, ST_IsValid(geometry))
    WHERE name <> '' AND ST_IsValid(geometry);

CREATE OR REPLACE VIEW osm_outdoor_point_view AS
SELECT osm_id,
       ST_PointOnSurface(geometry) AS geometry,
       name,
       name_en,
       name_de,
       COALESCE(NULLIF("natural", ''), landuse) AS class,
       update_tags(tags, ST_PointOnSurface(geometry)) AS tags,
       ST_Area(geometry) AS area
FROM osm_outdoor_name_polygon
WHERE name <> ''
  AND ST_IsValid(geometry)
  AND ("natural" IN ('scree', 'fell', 'bare_rock', 'glacier') OR landuse = 'meadow');

CREATE OR REPLACE VIEW osm_outdoor_point_earth_view AS
SELECT osm_id,
       geometry,
       name,
       name_en,
       name_de,
       class,
       tags,
       -- Percentage of the earth's surface covered by this feature (approximately)
       area / (405279708033600 * COS(ST_Y(ST_Transform(geometry,4326))*PI()/180)) as earth_area
FROM osm_outdoor_point_view;

DROP TABLE IF EXISTS osm_outdoor_point CASCADE;

CREATE TABLE IF NOT EXISTS osm_outdoor_point AS
SELECT *
FROM osm_outdoor_point_earth_view;

DO
$$
    BEGIN
        ALTER TABLE osm_outdoor_point
            ADD CONSTRAINT osm_outdoor_point_pk PRIMARY KEY (osm_id);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'primary key osm_outdoor_point_pk already exists in osm_outdoor_point.';
    END;
$$;
CREATE INDEX IF NOT EXISTS osm_outdoor_point_geometry_idx ON osm_outdoor_point USING gist (geometry);


-- 4. Update Function
CREATE OR REPLACE FUNCTION update_osm_outdoor_name() RETURNS void AS $$
BEGIN
    -- Update Valleys (Linestrings)
    DELETE FROM osm_outdoor_lineline
    WHERE EXISTS(
        SELECT NULL
        FROM outdoor_name.osm_ids
        WHERE outdoor_name.osm_ids.osm_id = osm_outdoor_lineline.osm_id
              AND outdoor_name.osm_ids.is_old IS TRUE
    );

    INSERT INTO osm_outdoor_lineline
    SELECT * FROM osm_outdoor_lineline_view
    WHERE EXISTS(
        SELECT NULL
        FROM outdoor_name.osm_ids
        WHERE outdoor_name.osm_ids.osm_id = osm_outdoor_lineline_view.osm_id
              AND outdoor_name.osm_ids.is_old IS FALSE
    ) ON CONFLICT (osm_id) DO UPDATE SET geometry = excluded.geometry, name = excluded.name, name_en = excluded.name_en,
                                         name_de = excluded.name_de, tags = excluded.tags, class = excluded.class;

    -- Update Points (Polygons converted to points)
    DELETE FROM osm_outdoor_point
    WHERE EXISTS(
        SELECT NULL
        FROM outdoor_name.osm_ids
        WHERE outdoor_name.osm_ids.osm_id = osm_outdoor_point.osm_id
              AND outdoor_name.osm_ids.is_old IS TRUE
    );

    INSERT INTO osm_outdoor_point
    SELECT * FROM osm_outdoor_point_earth_view
    WHERE EXISTS(
        SELECT NULL
        FROM outdoor_name.osm_ids
        WHERE outdoor_name.osm_ids.osm_id = osm_outdoor_point_earth_view.osm_id
              AND outdoor_name.osm_ids.is_old IS FALSE
    ) ON CONFLICT (osm_id) DO UPDATE SET geometry = excluded.geometry, name = excluded.name, name_en = excluded.name_en,
                                         name_de = excluded.name_de, class = excluded.class, tags = excluded.tags,
                                         earth_area = excluded.earth_area;
END;
$$ LANGUAGE plpgsql;


-- 5. Triggers for Update Logic
CREATE OR REPLACE FUNCTION outdoor_name.store() RETURNS trigger AS $$
BEGIN
    IF (tg_op = 'DELETE') THEN
        INSERT INTO outdoor_name.osm_ids (osm_id, is_old) VALUES (OLD.osm_id, TRUE) ON CONFLICT (osm_id, is_old) DO NOTHING;
    ELSE
        INSERT INTO outdoor_name.osm_ids (osm_id, is_old) VALUES (NEW.osm_id, FALSE) ON CONFLICT (osm_id, is_old) DO NOTHING;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION outdoor_name.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO outdoor_name.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION outdoor_name.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh outdoor_name';

    ANALYZE outdoor_name.osm_ids;
    ANALYZE osm_outdoor_lineline;
    ANALYZE osm_outdoor_point;

    PERFORM update_osm_outdoor_name();
    
    DELETE FROM outdoor_name.osm_ids;
    DELETE FROM outdoor_name.updates;

    RAISE LOG 'Refresh outdoor_name done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


-- Bind triggers to the polygon table
CREATE TRIGGER trigger_store_poly
    AFTER INSERT OR UPDATE OR DELETE ON osm_outdoor_name_polygon
    FOR EACH ROW WHEN (pg_trigger_depth() < 1)
EXECUTE PROCEDURE outdoor_name.store();

CREATE TRIGGER trigger_flag_poly
    AFTER INSERT OR UPDATE OR DELETE ON osm_outdoor_name_polygon
    FOR EACH STATEMENT WHEN (pg_trigger_depth() < 1)
EXECUTE PROCEDURE outdoor_name.flag();


-- Bind triggers to the linestring table
CREATE TRIGGER trigger_store_line
    AFTER INSERT OR UPDATE OR DELETE ON osm_outdoor_name_linestring
    FOR EACH ROW WHEN (pg_trigger_depth() < 1)
EXECUTE PROCEDURE outdoor_name.store();

CREATE TRIGGER trigger_flag_line
    AFTER INSERT OR UPDATE OR DELETE ON osm_outdoor_name_linestring
    FOR EACH STATEMENT WHEN (pg_trigger_depth() < 1)
EXECUTE PROCEDURE outdoor_name.flag();


-- Bind refresh trigger
CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON outdoor_name.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE outdoor_name.refresh();


-- 6. The Layer Rendering Function (Matched to your outdoor_name.yml)
CREATE OR REPLACE FUNCTION layer_outdoor_name(bbox geometry, zoom_level integer)
    RETURNS TABLE
            (
                osm_id       bigint,
                geometry     geometry,
                name         text,
                name_en      text,
                name_de      text,
                tags         hstore,
                class        text
            )
AS
$$
SELECT
    CASE
        WHEN osm_id < 0 THEN -osm_id * 10 + 4
        ELSE osm_id * 10 + 1
        END AS osm_id_hash,
    geometry,
    name,
    NULL::text AS name_en,
    NULL::text AS name_de,
    tags,
    class
FROM osm_outdoor_lineline
WHERE geometry && bbox
  AND ((zoom_level BETWEEN 10 AND 11 AND LineLabel(zoom_level, NULLIF(name, ''), geometry))
    OR (zoom_level >= 12))

UNION ALL

SELECT
    CASE
        WHEN osm_id < 0 THEN -osm_id * 10 + 4
        ELSE osm_id * 10 + 1
        END AS osm_id_hash,
    geometry,
    name,
    NULL::text AS name_en,
    NULL::text AS name_de,
    tags,
    class
FROM osm_outdoor_point
WHERE geometry && bbox
  AND (
        -- Scale rendering by earth_area so massive glaciers/fells show up early, 
        -- but tiny meadows wait until zoom 12
        (zoom_level BETWEEN 6 AND 11 AND POWER(4,zoom_level) * earth_area > 0.25)
        OR (zoom_level >= 12)
    );
$$ LANGUAGE SQL STABLE PARALLEL SAFE;