with source as (

    select * from {{ source('twitter', 'tweets') }}

),

renamed as (

    select
        id as status_id,
        user.id as user_id,
        user.screen_name as user_screen_name,
        full_text,
        is_quote_status,
        in_reply_to_status_id,
        PARSE_TIMESTAMP('%a %b %d %H:%M:%S +0000 %Y', created_at) AS created_at

    from source

)

select * from renamed