{{
    config(
        materialized = 'view',
        tags = ['bbc_sport']
    )
}}

SELECT
    "source_match_id" AS match_id,
    "urn" AS urn,
    {{ parse_iso_timestamp("startDateTime") }} AS start_date_time,
    "tournament_disambiguatedName" AS tournament_name,
    "tournament_urn",
    "venue_name",
    "venue_urn",
    CAST("attendance_value" AS integer) AS attendance_count,
    CASE WHEN "stage_name" LIKE 'Regular Season' THEN true ELSE false END AS is_regular_season,
    CASE WHEN "periodLabel_value" LIKE 'FT' THEN true ELSE false END AS full_time,
    "home_urn",
    CAST("home_runningScores_halftime" AS integer) AS home_score_halftime,
    CAST("home_runningScores_fulltime" AS integer) AS home_score_fulltime,
    CASE "winner" 
        WHEN 'home' THEN 3
        WHEN 'away' THEN 0
        WHEN 'draw' THEN 1
        END AS home_points,
    "away_urn",
    CAST("away_runningScores_halftime" AS integer) AS away_score_halftime,
    CAST("away_runningScores_fulltime" AS integer) AS away_score_fulltime,
    CASE "winner" 
        WHEN 'home' THEN 0
        WHEN 'away' THEN 3
        WHEN 'draw' THEN 1
        END AS away_points
FROM {{ source('bbc_sport', 'matches') }}
