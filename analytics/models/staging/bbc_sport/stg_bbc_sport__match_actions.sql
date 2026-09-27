{{
    config(
        materialized = 'view',
        tags = ['bbc_sport']
    )
}}

WITH parsed AS (
    SELECT
        "source_match_id" AS match_id,
        "team_urn" AS team_urn,
        "playerUrn" AS player_urn,
        CAST("action_index" AS integer) AS action_index,
        CAST("sub_index" AS integer) AS sub_index,
        CASE WHEN "type" = 'Own Goal' THEN true ELSE false END AS is_own_goal,
        CASE WHEN "type" = 'Goal' THEN true ELSE false END AS is_goal,
        CASE WHEN "type" = 'Red Card' THEN true ELSE false END AS is_direct_red,
        CASE WHEN "type" = 'Two Yellow Cards' THEN true ELSE false END AS is_second_yellow,
        CASE WHEN "type" = 'Penalty' THEN true ELSE false END AS is_penalty,
        {{ analytics.match_regulation_time('"timeLabel_value"') }} AS regulation_time_minutes,
        {{ analytics.match_added_time('"timeLabel_value"') }} AS injury_time_minutes
    FROM {{ source('bbc_sport', 'match_actions') }}
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
