DROP TRIGGER IF EXISTS trigger_osm_route_bicycle_hiking_merge_linestring ON osm_route_bicycle_hiking_network_merge;
DROP TRIGGER IF EXISTS trigger_store_route_bicycle_hiking ON osm_route_bicycle_hiking_linestring;
DROP TRIGGER IF EXISTS trigger_flag_route_bicycle_hiking ON osm_route_bicycle_hiking_linestring;
DROP TRIGGER IF EXISTS trigger_refresh ON route_bicycle_hiking.updates;

TRUNCATE osm_route_bicycle_hiking_linestring;
INSERT INTO osm_route_bicycle_hiking_linestring (relation_id, osm_id, role, type, route, ref, network, name, colour, symbol, wiki_symbol, scale, geometry)
SELECT
	h.rel_member['rel_id']::bigint AS relation_id,
	h.way_id AS osm_id,
	h.rel_member['role'] #>> '{}' AS role,
	h.rel_member['type']::smallint AS type,
	r.route, 
	r.ref,
	r.network,
	r.name,
    r.colour,
    r.symbol,
    r.wiki_symbol,
    r.scale,
	h.geom AS geometry
FROM (SELECT way_id, jsonb_array_elements(rels_member) AS rel_member, geom from osm2pgsql_hiking_highways) h
JOIN osm2pgsql_hiking_relations r on r.relation_id = h.rel_member['rel_id']::bigint;

CREATE OR REPLACE FUNCTION network_level(network TEXT) RETURNS INTEGER AS $$
    SELECT coalesce(
        array_position(ARRAY['icn', 'ncn', 'rcn', 'lcn'], network::text),
        array_position(ARRAY['iwn', 'nwn', 'rwn', 'lwn'], network::text)
    );
$$ LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION check_province_border_rel_id() RETURNS INTEGER AS $$ 
DECLARE
   rb_url text;
BEGIN
    SELECT value 
    INTO rb_url 
    FROM osm2pgsql_properties 
    WHERE property='replication_base_url'
    LIMIT 1;

    if (rb_url LIKE '%europe/poland/slaskie%') then
        return -224462;
    elsif (rb_url LIKE '%europe/poland/malopolskie%') then
        return -224459;
    elsif (rb_url LIKE '%europe/poland/podkarpackie%') then
        return -130957;
    elsif (rb_url LIKE '%europe/poland/dolnoslaskie%') then
        return -224457;
    elsif (rb_url LIKE '%europe/poland/opolskie%') then
        return -224460; 
    elsif (rb_url LIKE '%europe/poland/podlaskie%') then
        return -224461;
    elsif (rb_url LIKE '%europe/poland/warminsko-mazurskie%') then
        return -223408;
    elsif (rb_url LIKE '%europe/poland/lubuskie%') then
        return -130969;
    elsif (rb_url LIKE '%europe/poland/zachodniopomorskie%') then
        return -104401;
    elsif (rb_url LIKE '%europe/poland/lubelskie%') then
        return -130919;
    elsif (rb_url LIKE '%europe/poland/pomorskie%') then
        return -130975;
    elsif (rb_url LIKE '%europe/poland/mazowieckie%') then
        return -130935;
    elsif (rb_url LIKE '%europe/poland/lodzkie%') then
        return -224458;
    elsif (rb_url LIKE '%europe/poland/kujawsko-pomorskie%') then
        return -223407;
    elsif (rb_url LIKE '%europe/poland/wielkopolskie%') then
        return -130971;
    elsif (rb_url LIKE '%europe/poland/swietokrzyskie%') then
        return -130914;
    elsif (rb_url LIKE '%europe/slovakia%') then
        return -14296;
    elsif (rb_url LIKE '%europe/czech-republic%') then
        return -51684;
    elsif (rb_url LIKE '%europe/spain/andalucia%') then
        return -349044;
    elsif (rb_url LIKE '%europe/spain/aragon%') then
        return -349045;
    elsif (rb_url LIKE '%europe/spain/asturias%') then
        return -349033;
    elsif (rb_url LIKE '%europe/spain/cantabria%') then
        return -349013;
    elsif (rb_url LIKE '%europe/spain/castilla-la-mancha%') then
        return -349052;
    elsif (rb_url LIKE '%europe/spain/castilla-y-leon%') then
        return -349041;
    elsif (rb_url LIKE '%europe/spain/cataluna%') then
        return -349053;
    elsif (rb_url LIKE '%europe/spain/ceuta%') then
        return -1154756;
    elsif (rb_url LIKE '%europe/spain/extremadura%') then
        return -349050;
    elsif (rb_url LIKE '%europe/spain/galicia%') then
        return -349036;
    elsif (rb_url LIKE '%europe/spain/islas-baleares%') then
        return -348981;
    elsif (rb_url LIKE '%europe/spain/la-rioja%') then
        return -348991;
    elsif (rb_url LIKE '%europe/spain/madrid%') then
        return -349055;
    elsif (rb_url LIKE '%europe/spain/melilla%') then
        return -1154757;
    elsif (rb_url LIKE '%europe/spain/murcia%') then
        return -349047;
    elsif (rb_url LIKE '%europe/spain/navarra%') then
        return -349027;
    elsif (rb_url LIKE '%europe/spain/pais-vasco%') then
        return -349042;
    elsif (rb_url LIKE '%europe/spain/valencia%') then
        return -349043;
    elsif (rb_url LIKE '%africa/canary-islands%') then
        return -349048;
    elsif (rb_url LIKE '%europe/great-britain/england%') then
        return -58447;
    elsif (rb_url LIKE '%europe/great-britain/scotland%') then
        return -58446;
    elsif (rb_url LIKE '%europe/great-britain/wales%') then
        return -58437;
    elsif (rb_url LIKE '%europe/united-kingdom/england%') then
        return -58447;
    elsif (rb_url LIKE '%europe/united-kingdom/scotland%') then
        return -58446;
    elsif (rb_url LIKE '%europe/united-kingdom/wales%') then
        return -58437;
    elsif (rb_url LIKE '%europe/germany/baden-wuerttemberg%') then
        return -62611;
    elsif (rb_url LIKE '%europe/germany/bayern%') then
        return -2145268;
    elsif (rb_url LIKE '%europe/germany/berlin%') then
        return -62422;
    elsif (rb_url LIKE '%europe/germany/brandenburg%') then
        return -62504; -- geofabrik contains berlin, osm not
    elsif (rb_url LIKE '%europe/germany/bremen%') then
        return -62718;
    elsif (rb_url LIKE '%europe/germany/hamburg%') then
        return -62782;
    elsif (rb_url LIKE '%europe/germany/hessen%') then
        return -62650;
    elsif (rb_url LIKE '%europe/germany/mecklenburg-vorpommern%') then
        return -28322;
    elsif (rb_url LIKE '%europe/germany/niedersachsen%') then
        return -62771; -- geofabrik contains bremen, osm not
    elsif (rb_url LIKE '%europe/germany/nordrhein-westfalen%') then
        return -62761;
    elsif (rb_url LIKE '%europe/germany/rheinland-pfalz%') then
        return -62341;
    elsif (rb_url LIKE '%europe/germany/saarland%') then
        return -62372;
    elsif (rb_url LIKE '%europe/germany/sachsen%') then
        return -62467;
    elsif (rb_url LIKE '%europe/germany/sachsen-anhalt%') then
        return -62607;
    elsif (rb_url LIKE '%europe/germany/schleswig-holstein%') then
        return -51529;
    elsif (rb_url LIKE '%europe/germany/thueringen%') then
        return -62366;
    elsif (rb_url LIKE '%europe/austria%') then
        return -16239;
    elsif (rb_url LIKE '%europe/switzerland%') then
        return -51701;
    elsif (rb_url LIKE '%europe/luxembourg%') then
        return -2171347;
    elsif (rb_url LIKE '%europe/liechtenstein%') then
        return -1155955;
    elsif (rb_url LIKE '%europe/hungary%') then
        return -21335;
    elsif (rb_url LIKE '%europe/romania%') then
        return -90689;
    elsif (rb_url LIKE '%europe/bulgaria%') then
        return -186382;
    elsif (rb_url LIKE '%europe/greece%') then
        return -192307;
    elsif (rb_url LIKE '%europe/cyprus%') then
        return -307787;
    elsif (rb_url LIKE '%europe/slovenia%') then
        return -218657;
    elsif (rb_url LIKE '%europe/france/alsace%') then
        return -8636;
    elsif (rb_url LIKE '%europe/france/aquitaine%') then
        return -8637;
    elsif (rb_url LIKE '%europe/france/auvergne%') then
        return -8638;
    elsif (rb_url LIKE '%europe/france/basse-normandie%') then
        return -8646;
    elsif (rb_url LIKE '%europe/france/bourgogne%') then
        return -27768;
    elsif (rb_url LIKE '%europe/france/bretagne%') then
        return -102740;
    elsif (rb_url LIKE '%europe/france/centre%') then
        return -8640;
    elsif (rb_url LIKE '%europe/france/champagne-ardenne%') then
        return -8641;
    elsif (rb_url LIKE '%europe/france/corse%') then
        return -7112309;
    elsif (rb_url LIKE '%europe/france/franche-comte%') then
        return -8642;
    elsif (rb_url LIKE '%europe/france/guadeloupe%') then
        return -2562137;
    elsif (rb_url LIKE '%europe/france/guyane%') then
        return -1260551;
    elsif (rb_url LIKE '%europe/france/haute-normandie%') then
        return -8656;
    elsif (rb_url LIKE '%europe/france/ile-de-france%') then
        return -8649;
    elsif (rb_url LIKE '%europe/france/languedoc-roussillon%') then
        return -8643;
    elsif (rb_url LIKE '%europe/france/limousin%') then
        return -8644;
    elsif (rb_url LIKE '%europe/france/lorraine%') then
        return -8645;
    elsif (rb_url LIKE '%europe/france/martinique%') then
        return -2473088;
    elsif (rb_url LIKE '%europe/france/mayotte%') then
        return -1363069;
    elsif (rb_url LIKE '%europe/france/midi-pyrenees%') then
        return -8647;
    elsif (rb_url LIKE '%europe/france/nord-pas-de-calais%') then
        return -8648;
    elsif (rb_url LIKE '%europe/france/pays-de-la-loire%') then
        return -8650;
    elsif (rb_url LIKE '%europe/france/picardie%') then
        return -8651;
    elsif (rb_url LIKE '%europe/france/poitou-charentes%') then
        return -8652;
    elsif (rb_url LIKE '%europe/france/provence-alpes-cote-d-azur%') then
        return -8654;
    elsif (rb_url LIKE '%europe/france/reunion%') then
        return -2470060;
    elsif (rb_url LIKE '%europe/france/rhone-alpes%') then
        return -8655;
    elsif (rb_url LIKE '%australia-oceania/australia%') then
        return -80500;
    elsif (rb_url LIKE '%australia-oceania/new-zealand%') then
        return -556706;
    elsif (rb_url LIKE '%north-america/canada/alberta%') then
        return -391186;
    elsif (rb_url LIKE '%north-america/canada/british-columbia%') then
        return -390867;
    elsif (rb_url LIKE '%north-america/canada/manitoba%') then
        return -390841;
    elsif (rb_url LIKE '%north-america/canada/new-brunswick%') then
        return -68942;
    elsif (rb_url LIKE '%north-america/canada/newfoundland-and-labrador%') then
        return -391196;
    elsif (rb_url LIKE '%north-america/canada/northwest-territories%') then
        return -391220;
    elsif (rb_url LIKE '%north-america/canada/nova-scotia%') then
        return -390558;
    elsif (rb_url LIKE '%north-america/canada/nunavut%') then
        return -390840;
    elsif (rb_url LIKE '%north-america/canada/ontario%') then
        return -68841;
    elsif (rb_url LIKE '%north-america/canada/prince-edward-island%') then
        return -391115;
    elsif (rb_url LIKE '%north-america/canada/quebec%') then
        return -61549;
    elsif (rb_url LIKE '%north-america/canada/saskatchewan%') then
        return -391178;
    elsif (rb_url LIKE '%north-america/canada/yukon%') then
        return -391455;
    elsif (rb_url LIKE '%north-america/us/alabama%') then
        return -161950;
    elsif (rb_url LIKE '%north-america/us/alaska%') then
        return -1116270;
    elsif (rb_url LIKE '%north-america/us/arizona%') then
        return -162018;
    elsif (rb_url LIKE '%north-america/us/arkansas%') then
        return -161646;
    elsif (rb_url LIKE '%north-america/us/california%') then
        return -165475;
    elsif (rb_url LIKE '%north-america/us/colorado%') then
        return -161961;
    elsif (rb_url LIKE '%north-america/us/connecticut%') then
        return -165794;
    elsif (rb_url LIKE '%north-america/us/delaware%') then
        return -162110;
    elsif (rb_url LIKE '%north-america/us/district-of-columbia%') then
        return -162069;
    elsif (rb_url LIKE '%north-america/us/florida%') then
        return -162050;
    elsif (rb_url LIKE '%north-america/us/georgia%') then
        return -161957;
    elsif (rb_url LIKE '%north-america/us/hawaii%') then
        return -166563;
    elsif (rb_url LIKE '%north-america/us/idaho%') then
        return -162116;
    elsif (rb_url LIKE '%north-america/us/illinois%') then
        return -122586;
    elsif (rb_url LIKE '%north-america/us/indiana%') then
        return -161816;
    elsif (rb_url LIKE '%north-america/us/iowa%') then
        return -161650;
    elsif (rb_url LIKE '%north-america/us/kansas%') then
        return -161644;
    elsif (rb_url LIKE '%north-america/us/kentucky%') then
        return -161655;
    elsif (rb_url LIKE '%north-america/us/louisiana%') then
        return -224922;
    elsif (rb_url LIKE '%north-america/us/maine%') then
        return -63512;
    elsif (rb_url LIKE '%north-america/us/maryland%') then
        return -162112;
    elsif (rb_url LIKE '%north-america/us/massachusetts%') then
        return -61315;
    elsif (rb_url LIKE '%north-america/us/michigan%') then
        return -165789;
    elsif (rb_url LIKE '%north-america/us/minnesota%') then
        return -165471;
    elsif (rb_url LIKE '%north-america/us/mississippi%') then
        return -161943;
    elsif (rb_url LIKE '%north-america/us/missouri%') then
        return -161638;
    elsif (rb_url LIKE '%north-america/us/montana%') then
        return -162115;
    elsif (rb_url LIKE '%north-america/us/nebraska%') then
        return -161648;
    elsif (rb_url LIKE '%north-america/us/nevada%') then
        return -165473;
    elsif (rb_url LIKE '%north-america/us/new-hampshire%') then
        return -67213;
    elsif (rb_url LIKE '%north-america/us/new-jersey%') then
        return -224951;
    elsif (rb_url LIKE '%north-america/us/new-mexico%') then
        return -162014;
    elsif (rb_url LIKE '%north-america/us/new-york%') then
        return -61320;
    elsif (rb_url LIKE '%north-america/us/north-carolina%') then
        return -224045;
    elsif (rb_url LIKE '%north-america/us/north-dakota%') then
        return -161653;
    elsif (rb_url LIKE '%north-america/us/ohio%') then
        return -162061;
    elsif (rb_url LIKE '%north-america/us/oklahoma%') then
        return -161645;
    elsif (rb_url LIKE '%north-america/us/oregon%') then
        return -165476;
    elsif (rb_url LIKE '%north-america/us/pennsylvania%') then
        return -162109;
    elsif (rb_url LIKE '%north-america/us/puerto-rico%') then
        return -4422604;
    elsif (rb_url LIKE '%north-america/us/rhode-island%') then
        return -392915;
    elsif (rb_url LIKE '%north-america/us/south-carolina%') then
        return -224040;
    elsif (rb_url LIKE '%north-america/us/south-dakota%') then
        return -161652;
    elsif (rb_url LIKE '%north-america/us/tennessee%') then
        return -161838;
    elsif (rb_url LIKE '%north-america/us/texas%') then
        return -114690;
    elsif (rb_url LIKE '%north-america/us/us-virgin-islands%') then
        return -286898;
    elsif (rb_url LIKE '%north-america/us/utah%') then
        return -161993;
    elsif (rb_url LIKE '%north-america/us/vermont%') then
        return -60759;
    elsif (rb_url LIKE '%north-america/us/virginia%') then
        return -224042;
    elsif (rb_url LIKE '%north-america/us/washington%') then
        return -165479;
    elsif (rb_url LIKE '%north-america/us/west-virginia%') then
        return -162068;
    elsif (rb_url LIKE '%north-america/us/wisconsin%') then
        return -165466;
    elsif (rb_url LIKE '%north-america/us/wyoming%') then
        return -161991;
    elsif (rb_url LIKE '%asia/israel%') then
        return -1473946;
    elsif (rb_url LIKE '%asia/palestine%') then
        return -13283819;
    elsif (rb_url LIKE '%asia/israel-and-palestine%') then
        return -6195356;
    elsif (rb_url LIKE '%asia/south-korea%') then
        return -307756;
    elsif (rb_url LIKE '%asia/taiwan%') then
        return -449220;
    elsif (rb_url LIKE '%asia/jordan%') then
        return -184818;
    elsif (rb_url LIKE '%asia/lebanon%') then
        return -184843;
    else 
        return 0;
    end if;
END; 
$$ LANGUAGE plpgsql;

-- etldoc: osm_route_bicycle_hiking_linestring -> osm_route_bicycle_hiking_max_network
CREATE OR REPLACE VIEW osm_route_bicycle_hiking_max_network AS
SELECT DISTINCT ON (osm_id, route, relation_id)
    osm_id,
    geometry::geometry(Geometry,3857) AS geometry,
    relation_id,
    route,
    network,
    network_org,
    name,
    ref,
    colour,
    symbol,
    wiki_symbol,
    scale
FROM (
    SELECT
        osm_id, 
        geometry,
        role,
        type,
        relation_id, 
        route, 
        network_level(network) AS network,
        network AS network_org,
        name, 
        ref, 
        colour, 
        symbol, 
        wiki_symbol, 
        scale
    FROM
        osm_route_bicycle_hiking_linestring

    UNION ALL

    SELECT
        osm_id, 
        geometry, 
        NULL AS role,
        NULL AS type,
        NULL AS relation_id, 
        route, 
        NULL AS network,
        NULL AS network_org,
        name, 
        NULL AS ref, 
        NULL AS colour, 
        NULL AS symbol, 
        NULL AS wiki_symbol, 
        scale
    FROM
        osm_via_ferrata_linestring
) AS combined_routes
WHERE
    combined_routes.route = 'via_ferrata' OR
    (
        combined_routes.type = 1 AND
        combined_routes.network IS NOT NULL AND
        combined_routes.role IN ('', 'forward', 'backward', 'reverse', 'route', 'north', 'south')
    )
ORDER BY
    combined_routes.osm_id,
    combined_routes.route,
	combined_routes.relation_id,
    combined_routes.network
;

-- etldoc: osm_route_bicycle_hiking_max_network -> osm_route_bicycle_hiking_network
CREATE OR REPLACE VIEW osm_route_bicycle_hiking_network AS
SELECT
    coalesce(bicycle.osm_id, hiking.osm_id) AS osm_id,
    coalesce(bicycle.geometry, hiking.geometry) AS geometry,
    coalesce(bicycle.relation_id, hiking.relation_id) AS relation_id,
    coalesce(bicycle.route, hiking.route) AS class,
    bicycle.network AS bicycle_network,
    bicycle.name AS bicycle_name,
    bicycle.ref AS bicycle_ref,
    hiking.network AS hiking_network,
    hiking.name AS hiking_name,
    hiking.ref AS hiking_ref,
    hiking.network_org AS network,
    hiking.name AS name,
    hiking.ref AS ref,
    hiking.colour AS colour,
    hiking.colour AS color,
    hiking.symbol AS symbol,
    hiking.wiki_symbol AS wiki_symbol,
    hiking.scale AS scale
FROM
    (SELECT * FROM osm_route_bicycle_hiking_max_network WHERE route = 'bicycle') AS bicycle
    FULL OUTER JOIN (SELECT * FROM osm_route_bicycle_hiking_max_network WHERE route = 'hiking' OR route = 'foot' OR route = 'via_ferrata') AS hiking ON
        bicycle.osm_id = hiking.osm_id
;


CREATE OR REPLACE VIEW osm_border_linestring_union AS
SELECT ST_LineMerge(ST_Union(geometry)) as geometry, relation_id
FROM osm_border_linestring
WHERE relation_id=check_province_border_rel_id() AND ST_GeometryType(geometry)='ST_LineString'
GROUP BY relation_id;

CREATE OR REPLACE VIEW osm_border_linestring_union_polygons AS
SELECT ST_MakePolygon(ST_AddPoint(geometry, ST_StartPoint(geometry))) as geometry, relation_id
FROM osm_border_linestring_union
WHERE ST_GeometryType(geometry)='ST_LineString';

CREATE OR REPLACE VIEW osm_route_bicycle_hiking_network_union AS
SELECT ST_Union(h.geometry) as geometry, h.relation_id, h.class, h.bicycle_network, h.bicycle_name, h.bicycle_ref, h.hiking_network, h.hiking_name, h.hiking_ref, h.network, h.name, h.ref, h.colour, h.color, h.symbol, h.wiki_symbol, h.scale
FROM osm_route_bicycle_hiking_network h
GROUP BY h.relation_id, h.class, h.bicycle_network, h.bicycle_name, h.bicycle_ref, h.hiking_network, h.hiking_name, h.hiking_ref, h.network, h.name, h.ref, h.colour, h.color, h.symbol, h.wiki_symbol, h.scale;


CREATE TABLE IF NOT EXISTS osm_route_bicycle_hiking_network_merge (
    geometry geometry,
    id SERIAL PRIMARY KEY,
    relation_id bigint,
    class varchar,
    bicycle_network integer,
    bicycle_name varchar,
    bicycle_ref varchar,
    hiking_network integer,
    hiking_name varchar,
    hiking_ref varchar,
    network varchar,
    name varchar,
    ref varchar,
    colour varchar,
    color varchar,
    symbol varchar,
    wiki_symbol varchar,
    scale varchar
);

TRUNCATE osm_route_bicycle_hiking_network_merge;

-- etldoc: osm_route_bicycle_hiking_network -> osm_route_bicycle_hiking_network_merge

INSERT INTO osm_route_bicycle_hiking_network_merge (geometry, relation_id, class, bicycle_network, bicycle_name, bicycle_ref, hiking_network, hiking_name, hiking_ref, network, name, ref, colour, color, symbol, wiki_symbol, scale)
SELECT (ST_Dump(ST_LineMerge(
        CASE 
            WHEN b.geometry IS NOT NULL THEN ST_Intersection(b.geometry, h.geometry)
            ELSE h.geometry 
        END
    ))).geom::geometry(Geometry,3857) AS geometry,
    h.relation_id,
    h.class,
    h.bicycle_network,
    h.bicycle_name,
    h.bicycle_ref,
    h.hiking_network,
    h.hiking_name,
    h.hiking_ref,
    h.network,
    h.name,
    h.ref,
    h.colour,
    h.color,
    h.symbol,
    h.wiki_symbol,
    h.scale
FROM
    osm_route_bicycle_hiking_network_union h
LEFT JOIN (SELECT * FROM osm_border_linestring_union_polygons WHERE relation_id=check_province_border_rel_id() LIMIT 1) b
ON true;

CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_merge_geometry_idx
    ON osm_route_bicycle_hiking_network_merge USING gist(geometry);

CREATE TABLE IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z13
    (LIKE osm_route_bicycle_hiking_network_merge);
CREATE TABLE IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z12
    (LIKE osm_route_bicycle_hiking_network_gen_z13);
CREATE TABLE IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z11
    (LIKE osm_route_bicycle_hiking_network_gen_z12);
CREATE TABLE IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z10
    (LIKE osm_route_bicycle_hiking_network_gen_z11);
CREATE TABLE IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z9
    (LIKE osm_route_bicycle_hiking_network_gen_z10);
CREATE TABLE IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z8
    (LIKE osm_route_bicycle_hiking_network_gen_z9);
CREATE TABLE IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z7
    (LIKE osm_route_bicycle_hiking_network_gen_z8);
CREATE TABLE IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z6
    (LIKE osm_route_bicycle_hiking_network_gen_z7);


CREATE OR REPLACE FUNCTION insert_route_bicycle_hiking_network_gen(update_id bigint) RETURNS void AS
$$
BEGIN
    -- etldoc: osm_route_bicycle_hiking_network_merge -> osm_route_bicycle_hiking_network_gen_z13
    INSERT INTO osm_route_bicycle_hiking_network_gen_z13
    SELECT ST_Simplify(geometry, ZRes(13)) AS geometry,
        id,
        relation_id,
        class,
        bicycle_network,
        bicycle_name,
        bicycle_ref,
        hiking_network,
        hiking_name,
        hiking_ref,
        network,
        name,
        ref,
        colour,
        color,
        symbol,
        wiki_symbol,
        scale
    FROM osm_route_bicycle_hiking_network_merge
    WHERE
        (update_id IS NULL OR id = update_id) AND
        ST_Length(geometry) > 20;


    -- etldoc: osm_route_bicycle_hiking_network_gen_z13 -> osm_route_bicycle_hiking_network_gen_z12
    INSERT INTO osm_route_bicycle_hiking_network_gen_z12
    SELECT ST_Simplify(geometry, ZRes(12)) AS geometry,
        id,
        relation_id,
        class,
        bicycle_network,
        bicycle_name,
        bicycle_ref,
        hiking_network,
        hiking_name,
        hiking_ref,
        network,
        name,
        ref,
        colour,
        color,
        symbol,
        wiki_symbol,
        scale
    FROM osm_route_bicycle_hiking_network_gen_z13
    WHERE
        (update_id IS NULL OR id = update_id) AND
        ST_Length(geometry) > 20;

    -- etldoc: osm_route_bicycle_hiking_network_gen_z12 -> osm_route_bicycle_hiking_network_gen_z11
    INSERT INTO osm_route_bicycle_hiking_network_gen_z11
    SELECT ST_Simplify(geometry, ZRes(11)) AS geometry,
        id,
        relation_id,
        class,
        bicycle_network,
        bicycle_name,
        bicycle_ref,
        hiking_network,
        hiking_name,
        hiking_ref,
        network,
        name,
        ref,
        colour,
        color,
        symbol,
        wiki_symbol,
        scale
    FROM osm_route_bicycle_hiking_network_gen_z12
    WHERE
        (update_id IS NULL OR id = update_id) AND
        ST_Length(geometry) > 75;

    -- etldoc: osm_route_bicycle_hiking_network_gen_z11 -> osm_route_bicycle_hiking_network_gen_z10
    INSERT INTO osm_route_bicycle_hiking_network_gen_z10
    SELECT ST_Simplify(geometry, ZRes(10)) AS geometry,
        id,
        relation_id,
        class,
        bicycle_network,
        bicycle_name,
        bicycle_ref,
        hiking_network,
        hiking_name,
        hiking_ref,
        network,
        name,
        ref,
        colour,
        color,
        symbol,
        wiki_symbol,
        scale
    FROM osm_route_bicycle_hiking_network_gen_z11
    WHERE
        (update_id IS NULL OR id = update_id) AND hiking_network <= 3 AND
        ST_Length(geometry) > 125;

    -- etldoc: osm_route_bicycle_hiking_network_gen_z10 -> osm_route_bicycle_hiking_network_gen_z9
    INSERT INTO osm_route_bicycle_hiking_network_gen_z9
    SELECT ST_Simplify(geometry, ZRes(9)) AS geometry,
        id,
        relation_id,
        class,
        bicycle_network,
        bicycle_name,
        bicycle_ref,
        hiking_network,
        hiking_name,
        hiking_ref,
        network,
        name,
        ref,
        colour,
        color,
        symbol,
        wiki_symbol,
        scale
    FROM osm_route_bicycle_hiking_network_gen_z10
    WHERE
        (update_id IS NULL OR id = update_id) AND hiking_network <= 2 AND
        ST_Length(geometry) > 250;

    -- etldoc: osm_route_bicycle_hiking_network_gen_z9 -> osm_route_bicycle_hiking_network_gen_z8
    INSERT INTO osm_route_bicycle_hiking_network_gen_z8
    SELECT ST_Simplify(geometry, ZRes(8)) AS geometry,
        id,
        relation_id,
        class,
        bicycle_network,
        bicycle_name,
        bicycle_ref,
        hiking_network,
        hiking_name,
        hiking_ref,
        network,
        name,
        ref,
        colour,
        color,
        symbol,
        wiki_symbol,
        scale
    FROM osm_route_bicycle_hiking_network_gen_z9
    WHERE
        (update_id IS NULL OR id = update_id) AND
        ST_Length(geometry) > 500;

    -- etldoc: osm_route_bicycle_hiking_network_gen_z8 -> osm_route_bicycle_hiking_network_gen_z7
    INSERT INTO osm_route_bicycle_hiking_network_gen_z7
    SELECT ST_Simplify(geometry, ZRes(7)) AS geometry,
        id,
        relation_id,
        class,
        bicycle_network,
        bicycle_name,
        bicycle_ref,
        hiking_network,
        hiking_name,
        hiking_ref,
        network,
        name,
        ref,
        colour,
        color,
        symbol,
        wiki_symbol,
        scale
    FROM osm_route_bicycle_hiking_network_gen_z8
    WHERE
        (update_id IS NULL OR id = update_id) AND
        ST_Length(geometry) > 1000;

    -- etldoc: osm_route_bicycle_hiking_network_gen_z7 -> osm_route_bicycle_hiking_network_gen_z6
    INSERT INTO osm_route_bicycle_hiking_network_gen_z6
    SELECT ST_Simplify(geometry, ZRes(6)) AS geometry,
        id,
        relation_id,
        class,
        bicycle_network,
        bicycle_name,
        bicycle_ref,
        hiking_network,
        hiking_name,
        hiking_ref,
        network,
        name,
        ref,
        colour,
        color,
        symbol,
        wiki_symbol,
        scale
    FROM osm_route_bicycle_hiking_network_gen_z7
    WHERE
        (update_id IS NULL OR id = update_id) AND
        ST_Length(geometry) > 2000;
END;
$$ LANGUAGE plpgsql;

TRUNCATE osm_route_bicycle_hiking_network_gen_z13;
TRUNCATE osm_route_bicycle_hiking_network_gen_z12;
TRUNCATE osm_route_bicycle_hiking_network_gen_z11;
TRUNCATE osm_route_bicycle_hiking_network_gen_z10;
TRUNCATE osm_route_bicycle_hiking_network_gen_z9;
TRUNCATE osm_route_bicycle_hiking_network_gen_z8;
TRUNCATE osm_route_bicycle_hiking_network_gen_z7;
TRUNCATE osm_route_bicycle_hiking_network_gen_z6;

SELECT insert_route_bicycle_hiking_network_gen(NULL);

CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z13_geometry_idx
    ON osm_route_bicycle_hiking_network_gen_z13 USING gist(geometry);
CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z13_id_idx
    ON osm_route_bicycle_hiking_network_gen_z13(id);


CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z12_geometry_idx
    ON osm_route_bicycle_hiking_network_gen_z12 USING gist(geometry);
CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z12_id_idx
    ON osm_route_bicycle_hiking_network_gen_z12(id);

CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z11_geometry_idx
    ON osm_route_bicycle_hiking_network_gen_z11 USING gist(geometry);
CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z11_id_idx
    ON osm_route_bicycle_hiking_network_gen_z11(id);

CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z10_geometry_idx
    ON osm_route_bicycle_hiking_network_gen_z10 USING gist(geometry);
CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z10_id_idx
    ON osm_route_bicycle_hiking_network_gen_z10(id);

CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z9_geometry_idx
    ON osm_route_bicycle_hiking_network_gen_z9 USING gist(geometry);
CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z9_id_idx
    ON osm_route_bicycle_hiking_network_gen_z9(id);

CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z8_geometry_idx
    ON osm_route_bicycle_hiking_network_gen_z8 USING gist(geometry);
CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z8_id_idx
    ON osm_route_bicycle_hiking_network_gen_z8(id);

CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z7_geometry_idx
    ON osm_route_bicycle_hiking_network_gen_z7 USING gist(geometry);
CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z7_id_idx
    ON osm_route_bicycle_hiking_network_gen_z7(id);

CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z6_geometry_idx
    ON osm_route_bicycle_hiking_network_gen_z6 USING gist(geometry);
CREATE INDEX IF NOT EXISTS osm_route_bicycle_hiking_network_gen_z6_id_idx
    ON osm_route_bicycle_hiking_network_gen_z6(id);


-- Handle updates

CREATE SCHEMA IF NOT EXISTS route_bicycle_hiking;

CREATE TABLE IF NOT EXISTS route_bicycle_hiking.changes
(
    id serial PRIMARY KEY,
    osm_id bigint,
    relation_id bigint,
    role varchar,
    is_old boolean,
    geometry geometry,
    route varchar,
    network varchar,
    name varchar,
    ref varchar,
    colour varchar,
    symbol varchar,
    wiki_symbol varchar,
    scale varchar
);

CREATE OR REPLACE FUNCTION route_bicycle_hiking.store() RETURNS trigger AS
$$
BEGIN
    IF (tg_op = 'DELETE' OR tg_op = 'UPDATE') AND old.type = 1 THEN
        INSERT INTO route_bicycle_hiking.changes(osm_id, relation_id, role, is_old, geometry, route, network, name, ref, colour, symbol, wiki_symbol, scale)
        VALUES (old.osm_id, old.relation_id, old.role, true, old.geometry, old.route, old.network, old.name, old.ref, old.colour, old.symbol, old.wiki_symbol, old.scale);
    END IF;
    IF (tg_op = 'UPDATE' OR tg_op = 'INSERT') AND new.type = 1 THEN
        INSERT INTO route_bicycle_hiking.changes(osm_id, relation_id, role, is_old, geometry, route, network, name, ref, colour, symbol, wiki_symbol, scale)
        VALUES (new.osm_id, new.relation_id, new.role, false, new.geometry, new.route, new.network, new.name, new.ref, new.colour, new.symbol, new.wiki_symbol, new.scale);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS route_bicycle_hiking.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION route_bicycle_hiking.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO route_bicycle_hiking.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION route_bicycle_hiking.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh route_bicycle_hiking';

    --
    -- Simplify the changes set
    --

    -- Compact the change history to keep only the first and last version
    CREATE TEMP TABLE changes_compact AS
    SELECT
        osm_id,
        relation_id,
        role,
        is_old,
        geometry,
        route,
        network,
        name,
        ref,
        colour,
        symbol,
        wiki_symbol,
        scale
    FROM ((
              SELECT DISTINCT ON (osm_id) *
              FROM route_bicycle_hiking.changes
              WHERE is_old
              ORDER BY osm_id,
                       id ASC
          )
          UNION ALL
          (
              SELECT DISTINCT ON (osm_id) *
              FROM route_bicycle_hiking.changes
              WHERE NOT is_old
              ORDER BY osm_id,
                       id DESC
          )) AS t;

    -- Delete not matching roles
    DELETE FROM changes_compact
    WHERE role NOT IN ('', 'forward', 'backward', 'reverse', 'route', 'north', 'south');

    -- As Imposm inserts full relation, list unchaged way
    CREATE TEMP TABLE no_changed AS
    SELECT
        n.osm_id
    FROM
        changes_compact AS o
        JOIN changes_compact AS n ON
            n.osm_id = o.osm_id AND
            o.is_old AND
            NOT n.is_old
    WHERE
        o.relation_id IS NOT DISTINCT FROM n.relation_id AND
        o.role IS NOT DISTINCT FROM n.role AND
        o.geometry IS NOT DISTINCT FROM n.geometry AND
        o.route IS NOT DISTINCT FROM n.route AND
        o.network IS NOT DISTINCT FROM n.network AND
        o.name IS NOT DISTINCT FROM n.name AND
        o.ref IS NOT DISTINCT FROM n.ref AND
        o.colour IS NOT DISTINCT FROM n.colour AND
        o.symbol IS NOT DISTINCT FROM n.symbol AND
        o.wiki_symbol IS NOT DISTINCT FROM n.wiki_symbol AND
        o.scale IS NOT DISTINCT FROM n.scale;

    -- Delete unchanged ways
    DELETE FROM changes_compact
    USING no_changed
    WHERE changes_compact.osm_id = no_changed.osm_id;

    DROP TABLE no_changed;

    --
    -- Fetch impacted merged ways and delete
    --

    CREATE TEMP TABLE original_merge AS
    SELECT DISTINCT ON (r.geometry)
        r.geometry
    FROM osm_route_bicycle_hiking_network_merge AS r
        JOIN changes_compact AS c ON
            r.geometry && c.geometry
            AND ST_Contains(r.geometry, c.geometry);

    DELETE FROM osm_route_bicycle_hiking_network_merge AS r
    USING original_merge AS c
    WHERE
        r.geometry && c.geometry
        AND ST_Equals(r.geometry, c.geometry);

    --
    -- Reconstruct new merged ways
    --

    CREATE TEMP TABLE changes_osm_route_bicycle_hiking_max_network AS
    SELECT DISTINCT ON (osm_id, route)
        osm_id,
        relation_id,
        geometry,
        route,
        network_level(network) AS network,
        network AS network_org,
        name,
        ref,
        colour,
        symbol,
        wiki_symbol,
        scale
    FROM ((
        SELECT
            osm_id,
            relation_id,
            role,
            geometry,
            route,
            network,
            name,
            ref,
            colour,
            symbol,
            wiki_symbol,
            scale
        FROM
            changes_compact
        WHERE
            NOT is_old
    ) UNION (
        SELECT
            osm_id,
            relation_id,
            role,
            t.geometry,
            route,
            network,
            name,
            ref,
            colour,
            symbol,
            wiki_symbol,
            scale
        FROM
            osm_route_bicycle_hiking_linestring AS t
            JOIN original_merge AS c ON
                c.geometry && t.geometry
                AND ST_Contains(c.geometry, t.geometry)
        WHERE
            "type" = 1
    )) AS t
    WHERE
        network_level(network) IS NOT NULL AND
        role IN ('', 'forward', 'backward', 'reverse', 'route', 'north', 'south')
    ORDER BY
        osm_id,
        route,
        network_level(network)
    ;
    CREATE INDEX changes_osm_route_bicycle_hiking_max_network_idx_osm_id ON changes_osm_route_bicycle_hiking_max_network(osm_id);

    CREATE OR REPLACE TEMP VIEW changes_osm_route_bicycle_hiking_network AS
    SELECT
        coalesce(bicycle.osm_id, hiking.osm_id) AS osm_id,
        coalesce(bicycle.geometry, hiking.geometry) AS geometry,
        coalesce(bicycle.relation_id, hiking.relation_id) AS relation_id,
        coalesce(bicycle.route, hiking.route) AS class,
        bicycle.network AS bicycle_network,
        bicycle.name AS bicycle_name,
        bicycle.ref AS bicycle_ref,
        hiking.network AS hiking_network,
        hiking.name AS hiking_name,
        hiking.ref AS hiking_ref,
        hiking.network_org AS network,
        hiking.name AS name,
        hiking.ref AS ref,
        hiking.colour AS colour,
        hiking.colour AS color,
        hiking.symbol AS symbol,
        hiking.wiki_symbol AS wiki_symbol,
        hiking.scale AS scale
    FROM
        (SELECT * FROM changes_osm_route_bicycle_hiking_max_network WHERE route = 'bicycle') AS bicycle
        FULL OUTER JOIN (SELECT * FROM changes_osm_route_bicycle_hiking_max_network WHERE route = 'hiking' OR route = 'foot') AS hiking ON
            bicycle.osm_id = hiking.osm_id
    ;

    INSERT INTO osm_route_bicycle_hiking_network_merge (geometry, relation_id, class, bicycle_network, bicycle_name, bicycle_ref, hiking_network, hiking_name, hiking_ref, network, name, ref, colour, color, symbol, wiki_symbol, scale)
    SELECT (ST_Dump(ST_LineMerge(ST_Union(geometry)))).geom::geometry(Geometry,3857) AS geometry,
        relation_id,
        class,
        bicycle_network,
        bicycle_name,
        bicycle_ref,
        hiking_network,
        hiking_name,
        hiking_ref,
        network,
        name,
        ref,
        colour,
        color,
        symbol,
        wiki_symbol,
        scale
    FROM
        changes_osm_route_bicycle_hiking_network
    GROUP BY
        relation_id,
        class,
        bicycle_network,
        bicycle_name,
        bicycle_ref,
        hiking_network,
        hiking_name,
        hiking_ref,
        network,
        name,
        ref,
        colour,
        color,
        symbol,
        wiki_symbol,
        scale;

    DROP VIEW changes_osm_route_bicycle_hiking_network;
    DROP TABLE changes_osm_route_bicycle_hiking_max_network;
    DROP TABLE original_merge;
    DROP TABLE changes_compact;
    -- noinspection SqlWithoutWhere
    DELETE FROM route_bicycle_hiking.changes;
    -- noinspection SqlWithoutWhere
    DELETE FROM route_bicycle_hiking.updates;

    RAISE LOG 'Refresh route_bicycle_hiking done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION route_bicycle_hiking.route_bicycle_hiking_network_gen_refresh() RETURNS trigger AS
$$
BEGIN
    IF (tg_op = 'DELETE') THEN
        DELETE FROM osm_route_bicycle_hiking_network_gen_z13 WHERE id = old.id;
        DELETE FROM osm_route_bicycle_hiking_network_gen_z12 WHERE id = old.id;
        DELETE FROM osm_route_bicycle_hiking_network_gen_z11 WHERE id = old.id;
        DELETE FROM osm_route_bicycle_hiking_network_gen_z10 WHERE id = old.id;
        DELETE FROM osm_route_bicycle_hiking_network_gen_z9 WHERE id = old.id;
        DELETE FROM osm_route_bicycle_hiking_network_gen_z8 WHERE id = old.id;
        DELETE FROM osm_route_bicycle_hiking_network_gen_z7 WHERE id = old.id;
        DELETE FROM osm_route_bicycle_hiking_network_gen_z6 WHERE id = old.id;
    END IF;

    IF (tg_op = 'UPDATE' OR tg_op = 'INSERT') THEN
        PERFORM insert_route_bicycle_hiking_network_gen(new.id);
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_osm_route_bicycle_hiking_merge_linestring
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_route_bicycle_hiking_network_merge
    FOR EACH ROW
EXECUTE PROCEDURE route_bicycle_hiking.route_bicycle_hiking_network_gen_refresh();

CREATE TRIGGER trigger_store_route_bicycle_hiking
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_route_bicycle_hiking_linestring
    FOR EACH ROW
EXECUTE PROCEDURE route_bicycle_hiking.store();

CREATE TRIGGER trigger_flag_route_bicycle_hiking
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_route_bicycle_hiking_linestring
    FOR EACH STATEMENT
EXECUTE PROCEDURE route_bicycle_hiking.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON route_bicycle_hiking.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE route_bicycle_hiking.refresh();
