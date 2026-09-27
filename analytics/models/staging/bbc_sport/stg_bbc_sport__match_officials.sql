{{
    config(
        materialized = 'view',
        tags = ['bbc_sport']
    )
}}

SELECT
    "source_match_id" AS match_id,
    "match_urn" AS match_urn,
    "id" as urn,
    "firstName" as first_name,
    "lastName" as last_name
FROM {{ source('bbc_sport', 'match_officials') }}
