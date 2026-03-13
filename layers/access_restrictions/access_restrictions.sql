CREATE OR REPLACE FUNCTION parse_conditional_start_date(foot text, foot_conditional text, access_conditional text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  m text[];
  start_date date;
  conditional text;
BEGIN
  IF NULLIF(foot, '') IS NOT NULL THEN
    conditional := foot_conditional;
  ELSE
    conditional := COALESCE(NULLIF(foot_conditional, ''), access_conditional);
  END IF;

  m := regexp_match(
    conditional,
    '@\s*\(?\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s*(\d{1,2})\s*-\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s*(\d{1,2})\s*\)?\s*$'
  );
  IF m IS NULL THEN
    RETURN NULL;
  END IF;

  BEGIN
    IF trim(split_part(conditional, '@', 1)) IN ('no', 'private', 'agricultural', 'forestry', 'delivery', 'military', 'permit') THEN
      start_date := to_date(m[1] || ' ' || m[2] || ' 2025', 'Mon DD YYYY');
    ELSE
      start_date := to_date(m[3] || ' ' || m[4] || ' 2025', 'Mon DD YYYY') + 1;
    END IF;
  EXCEPTION WHEN datetime_field_overflow THEN
    RETURN NULL;
  END;

  -- Reject impossible dates like Feb 30
  IF start_date IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN to_char(start_date, 'MM-DD');
END;
$$;

CREATE OR REPLACE FUNCTION parse_conditional_end_date(foot text, foot_conditional text, access_conditional text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  m text[];
  end_date date;
  conditional text;
BEGIN
  IF NULLIF(foot, '') IS NOT NULL THEN
    conditional := foot_conditional;
  ELSE
    conditional := COALESCE(NULLIF(foot_conditional, ''), access_conditional);
  END IF;

  m := regexp_match(
    conditional,
    '@\s*\(?\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s*(\d{1,2})\s*-\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s*(\d{1,2})\s*\)?\s*$'
  );

  IF m IS NULL THEN
    RETURN NULL;
  END IF;

  BEGIN
    IF trim(split_part(conditional, '@', 1)) IN ('no', 'private', 'agricultural', 'forestry', 'delivery', 'military', 'permit') THEN
      end_date := to_date(m[3] || ' ' || m[4] || ' 2025', 'Mon DD YYYY');
    ELSE
      end_date := to_date(m[1] || ' ' || m[2] || ' 2025', 'Mon DD YYYY') - 1;
    END IF;
  EXCEPTION WHEN datetime_field_overflow THEN
    RETURN NULL;
  END;

  -- Reject impossible dates like Feb 30
  IF end_date IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN to_char(end_date, 'MM-DD');
END;
$$;

CREATE OR REPLACE FUNCTION parse_conditional_cross_year(foot text, foot_conditional text, access_conditional text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  m text[];
  start_date date;
  end_date date;
  conditional text;
  is_no_access boolean;
BEGIN
  IF NULLIF(foot, '') IS NOT NULL THEN
    conditional := foot_conditional;
  ELSE
    conditional := COALESCE(NULLIF(foot_conditional, ''), access_conditional);
  END IF;

  m := regexp_match(
    conditional,
    '@\s*\(?\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s*(\d{1,2})\s*-\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s*(\d{1,2})\s*\)?\s*$'
  );

  IF m IS NULL THEN
    RETURN NULL;
  END IF;

  is_no_access := trim(split_part(conditional, '@', 1)) IN ('no', 'private', 'agricultural', 'forestry', 'delivery', 'military', 'permit');


  BEGIN
    IF is_no_access THEN
      start_date := to_date(m[1] || ' ' || m[2] || ' 2025', 'Mon DD YYYY');
    ELSE
      start_date := to_date(m[3] || ' ' || m[4] || ' 2025', 'Mon DD YYYY') + 1;
    END IF;

    IF is_no_access THEN
      end_date := to_date(m[3] || ' ' || m[4] || ' 2025', 'Mon DD YYYY');
    ELSE
      end_date := to_date(m[1] || ' ' || m[2] || ' 2025', 'Mon DD YYYY') - 1;
    END IF;
  EXCEPTION WHEN datetime_field_overflow THEN
    RETURN NULL;
  END;

  -- Reject impossible dates like Feb 30
  IF end_date IS NULL OR start_date IS NULL THEN
    RETURN NULL;
  END IF;

  IF start_date > end_date THEN
    RETURN 'true';
  ELSE
    RETURN 'false';
  END IF;
END;
$$;


CREATE OR REPLACE FUNCTION parse_access(foot text, access text, foot_conditional text, access_conditional text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  access_text text;
  conditional_text text;
BEGIN
  access_text := COALESCE(NULLIF(foot, ''), NULLIF(access, ''));
  conditional_text := COALESCE(NULLIF(foot_conditional, ''), NULLIF(access_conditional, ''));

  IF extract_other_condition(foot, foot_conditional, access_conditional) IS NOT NULL THEN
    IF access_text IN ('no', 'private', 'agricultural', 'forestry', 'delivery', 'military', 'permit') THEN
      RETURN 'no';
    ELSE
      RETURN 'yes';
    END IF;
  END IF;

  IF access_text IN ('no', 'private', 'agricultural', 'forestry', 'delivery', 'military', 'permit') AND conditional_text IS NULL THEN
    RETURN 'no';
  END IF;

  RETURN NULL;
END;
$$;


CREATE OR REPLACE FUNCTION extract_other_condition(foot text, foot_conditional text, access_conditional text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  condition text;
  conditional text;
BEGIN
  IF NULLIF(foot, '') IS NOT NULL THEN
    conditional := foot_conditional;
  ELSE
    conditional := COALESCE(NULLIF(foot_conditional, ''), access_conditional);
  END IF;

  condition := trim(split_part(conditional, '@', 2));

  IF condition IN ('winter', 'snow') THEN
      RETURN condition;
  END IF;

  RETURN NULL;
END;
$$;


CREATE OR REPLACE FUNCTION layer_access_restrictions(bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, 
            type text,   -- 'line', 'start', 'end'
            osm_id BIGINT,
            highway TEXT, 
            no_foot_access_condition_start TEXT,
            no_foot_access_condition_end TEXT,
            no_foot_access_condition_cross_year TEXT,
            foot_access_condition_other TEXT,
            foot_access TEXT
            )
    AS
$$
WITH base AS (
    SELECT
        geometry,
        osm_id,
        highway,
        parse_conditional_start_date(foot, foot_conditional, access_conditional)
            AS no_foot_access_condition_start,
        parse_conditional_end_date(foot, foot_conditional, access_conditional)
            AS no_foot_access_condition_end,
        parse_conditional_cross_year(foot, foot_conditional, access_conditional)
            AS no_foot_access_condition_cross_year,
        extract_other_condition(foot, foot_conditional, access_conditional)
            AS foot_access_condition_other,
        parse_access(foot, access, foot_conditional, access_conditional)
            AS foot_access
    FROM osm_access_restrictions_linestring
    WHERE geometry && bbox
      AND zoom_level >= 12
),
filtered AS (
    SELECT *
    FROM base
    WHERE
        no_foot_access_condition_start IS NOT NULL
        OR no_foot_access_condition_end IS NOT NULL
        OR foot_access_condition_other IS NOT NULL
        OR foot_access IS NOT NULL
)

-- Line feature
SELECT
    geometry,
    'line' AS type,
    osm_id,
    highway,
    no_foot_access_condition_start,
    no_foot_access_condition_end,
    no_foot_access_condition_cross_year,
    foot_access_condition_other,
    foot_access
FROM filtered

UNION ALL

-- Start point feature
SELECT
    ST_StartPoint(geometry) AS geometry,
    'start' AS type,
    osm_id,
    highway,
    no_foot_access_condition_start,
    no_foot_access_condition_end,
    no_foot_access_condition_cross_year,
    foot_access_condition_other,
    foot_access
FROM filtered

UNION ALL

-- End point feature
SELECT
    ST_EndPoint(geometry) AS geometry,
    'end' AS type,
    osm_id,
    highway,
    no_foot_access_condition_start,
    no_foot_access_condition_end,
    no_foot_access_condition_cross_year,
    foot_access_condition_other,
    foot_access
FROM filtered

$$ LANGUAGE SQL STABLE
                PARALLEL UNSAFE;