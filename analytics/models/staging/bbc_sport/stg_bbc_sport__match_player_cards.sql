{{
    config(
        materialized = 'view',
        tags = ['bbc_sport']
    )
}}

WITH parsed AS (
    SELECT
        "source_match_id" AS match_id,
        "match_urn" AS match_urn,
        "playerUrn" AS player_urn,
        "team_urn" AS team_urn,
        CASE WHEN "type" = 'Yellow Card' THEN true ELSE false END AS is_yellow_card,
        CASE WHEN "type" = 'Two Yellow Cards' THEN true ELSE false END AS is_second_yellow,
        CASE WHEN "type" = 'Red Card' THEN true ELSE false END AS is_direct_red,
        {{ analytics.match_regulation_time('"timeLabel_value"') }} AS regulation_time_minutes,
        {{ analytics.match_added_time('"timeLabel_value"') }} AS injury_time_minutes
    FROM {{ source('bbc_sport', 'match_player_cards') }}
)
SELECT
    *,
    CASE
        WHEN regulation_time_minutes <= 45 THEN 1
        WHEN regulation_time_minutes > 45 AND regulation_time_minutes <= 90 THEN 2
        WHEN regulation_time_minutes > 90 AND regulation_time_minutes <= 105 THEN 3
        WHEN regulation_time_minutes > 105 THEN 3
        END AS "period"
FROM parsed
