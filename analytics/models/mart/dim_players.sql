{{
    config(
        materialized = 'table',
        tags = ['wsl']
    )
}}

WITH ranked_players AS (
    SELECT
        p.*,
        ROW_NUMBER() OVER (
            PARTITION BY p.player_urn
            ORDER BY m.start_date_time DESC, m.urn DESC
        ) AS rn
    FROM {{ ref('stg_bbc_sport__match_players') }} p
    JOIN {{ ref('stg_bbc_sport__matches') }} m ON p.match_urn = m.urn
),
ranked_starts AS (
    SELECT
        p.player_urn,
        p."position",
        ROW_NUMBER() OVER (
            PARTITION BY p.player_urn
            ORDER BY m.start_date_time DESC, m.urn DESC
        ) AS rn
    FROM {{ ref('stg_bbc_sport__match_players') }} p
    JOIN {{ ref('stg_bbc_sport__matches') }} m ON p.match_urn = m.urn
    WHERE p.is_starter
),
position_starts AS (
    SELECT
        p.player_urn,
        SUM(
            CASE WHEN p."position" = 'Striker' THEN 1 ELSE 0 END
        ) AS starts_as_striker,
        SUM(
            CASE WHEN p."position" = 'Attacking Midfielder' THEN 1 ELSE 0 END
        ) AS starts_as_attacking_midfielder,
        SUM(
            CASE WHEN p."position" = 'Defensive Midfielder' THEN 1 ELSE 0 END
        ) AS starts_as_defensive_midfielder,
        SUM(
            CASE WHEN p."position" = 'Midfielder' THEN 1 ELSE 0 END
        ) AS starts_as_midfielder,
        SUM(
            CASE WHEN p."position" = 'Defender' THEN 1 ELSE 0 END
        ) AS starts_as_defender,
        SUM(
            CASE WHEN p."position" = 'Goalkeeper' THEN 1 ELSE 0 END
        ) AS starts_as_goalkeeper
    FROM {{ ref('stg_bbc_sport__match_players') }} p
    WHERE p.is_starter
    GROUP BY p.player_urn
)
SELECT
    ranked_players.player_urn AS player_urn,
    ranked_players.team_urn AS current_team_urn,
    ranked_players.name_first AS name_first,
    ranked_players.name_last AS name_last,
    ranked_players.name_shirt AS name_shirt,
    ranked_players.display_name AS display_name,
    CAST(ranked_players.shirt_number AS integer) AS shirt_number,
    ranked_starts."position" AS latest_starting_position,
    coalesce(position_starts.starts_as_striker, 0) AS starts_as_striker,
    coalesce(position_starts.starts_as_attacking_midfielder, 0) AS starts_as_attacking_midfielder,
    coalesce(position_starts.starts_as_defensive_midfielder, 0) AS starts_as_defensive_midfielder,
    coalesce(position_starts.starts_as_midfielder, 0) AS starts_as_midfielder,
    coalesce(position_starts.starts_as_defender, 0) AS starts_as_defender,
    coalesce(position_starts.starts_as_goalkeeper, 0) AS starts_as_goalkeeper
FROM ranked_players
LEFT JOIN ranked_starts
    ON ranked_players.player_urn = ranked_starts.player_urn
   AND ranked_starts.rn = 1
LEFT JOIN position_starts
    ON ranked_players.player_urn = position_starts.player_urn
WHERE ranked_players.rn = 1
