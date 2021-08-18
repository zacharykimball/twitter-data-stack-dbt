with users as (

    select * from {{ ref('dim_users') }}

),

trend as (

    select
        user_id,
        (number_total_tweets_l28 - number_total_tweets_l7) / 21 as average_daily_activity_baseline,
        number_total_tweets_l7 / 7 as average_daily_activity_recent
    from users

),

activity as (

    select
        actioned_user_id,
        max(created_at) as most_recent_action
    from {{ ref('fct_activity') }}
    group by actioned_user_id

),

final as (

    select
        users.user_id,
        users.latest_screen_name,
        users.days_since_last_tweet,
        trend.average_daily_activity_baseline,
        trend.average_daily_activity_recent,
        false as actioned  -- create a tracker for each action which can later be set to ensure no duplicate actions
    from users
    left join trend
    on users.user_id = trend.user_id
    left join activity
    on users.user_id = activity.actioned_user_id
    
    where
        -- only trigger actions for users with more than 31 days of history (don't want to act preemptively)
        users.days_tracked > 31
        -- only trigger actions when users have no activity for at least 3 days (have to give people a Twitter break sometimes!)
        and users.days_since_last_tweet > 3
        -- trigger actions when user activity in the past week is less than half of prior activity baseline
        and trend.average_daily_activity_recent < average_daily_activity_baseline / 2
        -- cross-check our recent activity and only bother this user if we haven't auto-tweeted at them in the past 7 days
        and most_recent_action < timestamp_sub(current_timestamp(), interval 7 day)

)

select * from final