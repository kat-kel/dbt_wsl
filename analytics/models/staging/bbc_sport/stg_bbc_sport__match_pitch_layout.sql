{{
    config(
        materialized = 'view',
        tags = ['bbc_sport']
    )
}}

SELECT
    "source_match_id" AS match_id,
    "match_urn" AS match_urn,
    "urn" as player_urn,
    CAST("row_index" AS integer) as row_index,
    CAST("slot_index" AS integer) as slot_index
FROM {{ source('bbc_sport', 'match_pitch_layout') }}
