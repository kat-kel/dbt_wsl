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
        "team_urn" AS team_urn,
        -- (all) general player information --
        "urn" AS player_urn,
        "displayName" AS display_name,
        "name_first" AS name_first,
        "name_last" AS name_last,
        "name_shirt" AS name_shirt,
        "position" AS position,
        "shirtNumber" AS shirt_number,
        CASE WHEN "source_player_list" = 'starters' THEN true ELSE false END AS is_starter,
        CASE WHEN "isCaptain" = 'true' THEN true ELSE false END AS is_captain,
        "formationPlace" AS formation_place,
        -- (starter) subtituted off --
        CAST("substitutedOff_periodId" AS integer) AS substituted_off_period,
        "substitutedOff_timeMinSec" AS raw_substituted_off_min_sec,
        {{ analytics.match_clock_seconds('"substitutedOff_timeMinSec"') }} AS substituted_off_time_seconds,
        {{ analytics.match_clock_minute('"substitutedOff_timeMinSec"') }} AS substituted_off_minute,
        "substitutedOff_reason" AS substituted_off_reason,
        "substitutedOff_playerOnUrn" AS substituted_off_for_player,
        -- (sub) substituted on --
        CAST("substitutedOn_periodId" AS integer) AS substituted_on_period,
        "substitutedOn_timeMinSec" AS raw_substituted_on_min_sec,
        {{ analytics.match_clock_seconds('"substitutedOn_timeMinSec"') }} AS substituted_on_time_seconds,
        {{ analytics.match_clock_minute('"substitutedOn_timeMinSec"') }} AS substituted_on_minute,
        "substitutedOn_reason" AS substituted_on_reason,
        "substitutedOn_playerOffUrn" AS substituted_on_for_player
    FROM {{ source('bbc_sport', 'match_players') }}
)
SELECT
    match_id,
    match_urn,
    team_urn,
    player_urn,
    display_name,
    name_first,
    name_last,
    name_shirt,
    position,
    shirt_number,
    is_starter,
    is_captain,
    formation_place,
    -- (starter) subtituted off --
    substituted_off_reason,
    substituted_off_for_player,
    substituted_off_period,
    {{ regulation_time_from_minute('substituted_off_minute', 'substituted_off_period') }}
        AS substituted_off_regulation_time,
    {{ injury_time_from_minute('substituted_off_minute', 'substituted_off_period') }}
        AS substituted_off_injury_time,
    raw_substituted_off_min_sec,
    substituted_off_time_seconds,
    -- (sub) substituted on --
    substituted_on_reason,
    substituted_on_for_player,
    substituted_on_period,
    {{ regulation_time_from_minute('substituted_on_minute', 'substituted_on_period') }}
        AS substituted_on_regulation_time,
    {{ injury_time_from_minute('substituted_on_minute', 'substituted_on_period') }}
        AS substituted_on_injury_time,
    raw_substituted_on_min_sec,
    substituted_on_time_seconds
FROM parsed