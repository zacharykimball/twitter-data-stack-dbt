with tweets as (

    select * from {{ ref('fct_tweets') }}

),

user_stats as (

    select
        user_id,
        max(status_id) as most_recent_status,
        min(created_at) as first_tweet_at,
        max(created_at) as last_tweet_at,
        count(status_id) as number_tweets_total,

        -- Note: a tweet can be a quote tweet AND a reply tweet, so these are not mutually exclusive
        countif(is_quote_status and created_at > timestamp_sub(current_timestamp(), interval 28 day))
            as number_quote_tweets_l28,
        countif(is_reply_status and created_at > timestamp_sub(current_timestamp(), interval 28 day))
            as number_reply_tweets_l28,
        countif(not is_reply_status and not is_quote_status and created_at > timestamp_sub(current_timestamp(), interval 28 day))
            as number_organic_tweets_l28,
        countif(created_at > timestamp_sub(current_timestamp(), interval 28 day))
            as number_total_tweets_l28,

        -- Note: a tweet can be a quote tweet AND a reply tweet, so these are not mutually exclusive
        countif(is_quote_status and created_at > timestamp_sub(current_timestamp(), interval 7 day))
            as number_quote_tweets_l7,
        countif(is_reply_status and created_at > timestamp_sub(current_timestamp(), interval 7 day))
            as number_reply_tweets_l7,
        countif(not is_reply_status and not is_quote_status and created_at > timestamp_sub(current_timestamp(), interval 7 day))
            as number_organic_tweets_l7,
        countif(created_at > timestamp_sub(current_timestamp(), interval 7 day))
            as number_total_tweets_l7
    from tweets

    group by user_id

),

user_info as (

    select
        tweets.user_id,
        tweets.user_screen_name
    from tweets

    left join user_stats
    on tweets.user_id = user_stats.user_id  
    
    where tweets.status_id = user_stats.most_recent_status

),

final as (

    select
        user_stats.user_id,
        user_info.user_screen_name as latest_screen_name,
        user_stats.first_tweet_at,
        user_stats.last_tweet_at,
        date_diff(current_timestamp(), user_stats.last_tweet_at, day) as days_since_last_tweet,
        date_diff(current_timestamp(), user_stats.first_tweet_at, day) as days_tracked,
        ifnull(user_stats.number_tweets_total, 0) as number_tweets_total,
        ifnull(user_stats.number_quote_tweets_l28, 0) as number_quote_tweets_l28,
        ifnull(user_stats.number_reply_tweets_l28, 0) as number_reply_tweets_l28,
        ifnull(user_stats.number_organic_tweets_l28, 0) as number_organic_tweets_l28,
        ifnull(user_stats.number_total_tweets_l28, 0) as number_total_tweets_l28,
        ifnull(user_stats.number_quote_tweets_l7, 0) as number_quote_tweets_l7,
        ifnull(user_stats.number_reply_tweets_l7, 0) as number_reply_tweets_l7,
        ifnull(user_stats.number_organic_tweets_l7, 0) as number_organic_tweets_l7,
        ifnull(user_stats.number_total_tweets_l7, 0) as number_total_tweets_l7
    from user_stats
    left join user_info
    on user_stats.user_id = user_info.user_id

)

select * from final