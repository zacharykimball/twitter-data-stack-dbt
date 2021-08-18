with tweets as (

    select * from {{ ref('stg_tweets') }}

),

final as (

    select
        status_id,
        user_id,
        user_screen_name,
        full_text,
        is_quote_status,
        in_reply_to_status_id is not null as is_reply_status,
        created_at
    from tweets

)

select * from final