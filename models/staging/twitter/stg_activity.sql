-- The macros here will create an empty data set if (i.e., until) the 'activity' dataset exists
-- Inspired by 'Writing packages when a source table may or may not exist'
-- https://discourse.getdbt.com/t/writing-packages-when-a-source-table-may-or-may-not-exist/1487

{%- set source_relation = adapter.get_relation(
      database=source('twitter', 'activity').database,
      schema=source('twitter', 'activity').schema,
      identifier=source('twitter', 'activity').name) -%}

{% set table_exists=source_relation is not none   %}

{% if table_exists %}

with source as (

    select * from {{ source('twitter', 'activity') }}

),

{% else %}

with source as (

    select
        CAST(null AS INT64) as action_status_id,
        CAST(null AS INT64) as actioned_user_id,
        CAST(null AS STRING) as payload,
        CAST(null AS STRING) as created_at

),

{% endif %}

renamed as (

    select
        action_status_id,
        actioned_user_id,
        payload,
        PARSE_TIMESTAMP('%a %b %d %H:%M:%S +0000 %Y', created_at) AS created_at
    from source
    where action_status_id is not NULL

)

select * from renamed