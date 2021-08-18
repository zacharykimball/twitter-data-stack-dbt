with activity as (

    select * from {{ ref('stg_activity') }}

),

final as (

    select
        action_status_id,
        actioned_user_id,
        created_at
    from activity

)

select * from final