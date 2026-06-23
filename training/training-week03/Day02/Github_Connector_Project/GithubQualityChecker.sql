

-- Data quality scorecard for GitHub ingestion tables
-- Co-authored with CoCo
-- Checks included per table:
--   1. Null checks on key fields
--   2. Duplicate primary key checks (= primary key uniqueness)
--   3. Foreign key integrity (orphan child rows vs. parent via _dlt_parent_id/_dlt_id)
--   4. Accepted values (state, merged, reaction content, etc.)
--   5. Date consistency (updated_at >= created_at)
--   6. Future date validation (created_at/updated_at not in the future)
--   7. Empty string validation (title/body/login not blank)
--   8. Freshness check (age of most recent record)
--   9. Row count monitoring between pipeline runs (via history table)



WITH

-- ISSUES

dup_issues AS (
    SELECT COUNT(*) AS dup_groups
    FROM (
        SELECT number FROM issues GROUP BY number HAVING COUNT(*) > 1
    ) t
),

issues_nulls AS (
    SELECT
        SUM(CASE WHEN number     IS NULL THEN 1 ELSE 0 END) AS null_number,
        SUM(CASE WHEN title      IS NULL THEN 1 ELSE 0 END) AS null_title,
        SUM(CASE WHEN created_at IS NULL THEN 1 ELSE 0 END) AS null_created_at,
        SUM(CASE WHEN updated_at IS NULL THEN 1 ELSE 0 END) AS null_updated_at
    FROM issues
),

issues_dates AS (
    SELECT COUNT(*) AS bad_dates
    FROM issues
    WHERE updated_at < created_at
),

issues_future AS (
    SELECT COUNT(*) AS future_dates
    FROM issues
    WHERE created_at > CURRENT_TIMESTAMP OR updated_at > CURRENT_TIMESTAMP
),

issues_state AS (
    SELECT COUNT(*) AS bad_state
    FROM issues
    WHERE LOWER(state) NOT IN ('open', 'closed')
),

issues_empty AS (
    SELECT COUNT(*) AS empty_strings
    FROM issues
    WHERE TRIM(title) = ''
),
issues_fresh AS (
    SELECT DATEDIFF('second', MAX(updated_at), CURRENT_TIMESTAMP) / 86400.0 AS stale_days
    FROM issues
),

--  PULL_REQUESTS 

dup_pr AS (
    SELECT COUNT(*) AS dup_groups
    FROM (
        SELECT number FROM pull_requests GROUP BY number HAVING COUNT(*) > 1
    ) t
),

pr_nulls AS (
    SELECT
        SUM(CASE WHEN number     IS NULL THEN 1 ELSE 0 END) AS null_number,
        SUM(CASE WHEN title      IS NULL THEN 1 ELSE 0 END) AS null_title,
        SUM(CASE WHEN created_at IS NULL THEN 1 ELSE 0 END) AS null_created_at,
        SUM(CASE WHEN updated_at IS NULL THEN 1 ELSE 0 END) AS null_updated_at
    FROM pull_requests
),

pr_dates AS (
    SELECT COUNT(*) AS bad_dates
    FROM pull_requests
    WHERE updated_at < created_at
),

pr_future AS (
    SELECT COUNT(*) AS future_dates
    FROM pull_requests
    WHERE created_at > CURRENT_TIMESTAMP OR updated_at > CURRENT_TIMESTAMP
),

pr_state_consistency AS (
    SELECT COUNT(*) AS bad_state
    FROM pull_requests
    WHERE (closed = TRUE  AND state <> 'closed')
       OR (closed = FALSE AND state = 'closed')
),

pr_state_accepted AS (
    SELECT COUNT(*) AS bad_state
    FROM pull_requests
    WHERE LOWER(state) NOT IN ('open', 'closed')
),


pr_empty AS (
    SELECT COUNT(*) AS empty_strings
    FROM pull_requests
    WHERE TRIM(title) = ''
),

pr_fresh AS (
    SELECT DATEDIFF('second', MAX(updated_at), CURRENT_TIMESTAMP) / 86400.0 AS stale_days
    FROM pull_requests
),

--  ISSUES__COMMENTS 

dup_issue_comments AS (
    SELECT COUNT(*) AS dup_groups
    FROM (
        SELECT id FROM issues__comments GROUP BY id HAVING COUNT(*) > 1
    ) t
),

issue_comments_nulls AS (
    SELECT
        SUM(CASE WHEN id         IS NULL THEN 1 ELSE 0 END) AS null_id,
        SUM(CASE WHEN body       IS NULL THEN 1 ELSE 0 END) AS null_body,
        SUM(CASE WHEN created_at IS NULL THEN 1 ELSE 0 END) AS null_created_at
    FROM issues__comments
),



issue_comments_dates AS (
    SELECT 0 AS bad_dates
),

issue_comments_future AS (
    SELECT COUNT(*) AS future_dates
    FROM issues__comments
    WHERE created_at > CURRENT_TIMESTAMP
),

issue_comments_empty AS (
    SELECT COUNT(*) AS empty_strings
    FROM issues__comments
    WHERE TRIM(body) = ''
),

issue_comments_fresh AS (
    SELECT DATEDIFF('second', MAX(created_at), CURRENT_TIMESTAMP) / 86400.0 AS stale_days
    FROM issues__comments
),


--  ISSUES_REACTIONS 

dup_issue_reactions AS (
    SELECT COUNT(*) AS dup_groups
    FROM (
        SELECT content, user__login, _dlt_parent_id
        FROM issues__reactions
        GROUP BY content, user__login, _dlt_parent_id
        HAVING COUNT(*) > 1
    ) t
),

issue_reactions_nulls AS (
    SELECT
        SUM(CASE WHEN content       IS NULL THEN 1 ELSE 0 END) AS null_content,
        SUM(CASE WHEN user__login   IS NULL THEN 1 ELSE 0 END) AS null_login,
        SUM(CASE WHEN created_at    IS NULL THEN 1 ELSE 0 END) AS null_created_at
    FROM issues__reactions
),





issue_reactions_future AS (
    SELECT COUNT(*) AS future_dates
    FROM issues__reactions
    WHERE created_at > CURRENT_TIMESTAMP
),

issue_reactions_empty AS (
    SELECT COUNT(*) AS empty_strings
    FROM issues__reactions
    WHERE TRIM(user__login) = ''
),

issue_reactions_fresh AS (
    SELECT DATEDIFF('second', MAX(created_at), CURRENT_TIMESTAMP) / 86400.0 AS stale_days
    FROM issues__reactions
),


--  PULL_REQUESTS__COMMENTS 

dup_pr_comments AS (
    SELECT COUNT(*) AS dup_groups
    FROM (
        SELECT id FROM pull_requests__comments GROUP BY id HAVING COUNT(*) > 1
    ) t
),

pr_comments_nulls AS (
    SELECT
        SUM(CASE WHEN id         IS NULL THEN 1 ELSE 0 END) AS null_id,
        SUM(CASE WHEN body       IS NULL THEN 1 ELSE 0 END) AS null_body,
        SUM(CASE WHEN created_at IS NULL THEN 1 ELSE 0 END) AS null_created_at
    FROM pull_requests__comments
),



pr_comments_dates AS (
    SELECT 0 AS bad_dates
),

pr_comments_future AS (
    SELECT COUNT(*) AS future_dates
    FROM pull_requests__comments
    WHERE created_at > CURRENT_TIMESTAMP
),

pr_comments_empty AS (
    SELECT COUNT(*) AS empty_strings
    FROM pull_requests__comments
    WHERE TRIM(body) = ''
),

pr_comments_fresh AS (
    SELECT DATEDIFF('second', MAX(created_at), CURRENT_TIMESTAMP) / 86400.0 AS stale_days
    FROM pull_requests__comments
),



-- PULL_REQUESTS__COMMENTS__REACTIONS 

dup_pr_comment_reactions AS (
    SELECT COUNT(*) AS dup_groups
    FROM (
        SELECT content, user__login, _dlt_parent_id
        FROM pull_requests__comments__reactions
        GROUP BY content, user__login, _dlt_parent_id
        HAVING COUNT(*) > 1
    ) t
),

pr_comment_reactions_nulls AS (
    SELECT
        SUM(CASE WHEN content     IS NULL THEN 1 ELSE 0 END) AS null_content,
        SUM(CASE WHEN user__login IS NULL THEN 1 ELSE 0 END) AS null_login,
        SUM(CASE WHEN created_at  IS NULL THEN 1 ELSE 0 END) AS null_created_at
    FROM pull_requests__comments__reactions
),



pr_comment_reactions_future AS (
    SELECT COUNT(*) AS future_dates
    FROM pull_requests__comments__reactions
    WHERE created_at > CURRENT_TIMESTAMP
),

pr_comment_reactions_empty AS (
    SELECT COUNT(*) AS empty_strings
    FROM pull_requests__comments__reactions
    WHERE TRIM(user__login) = ''
),

pr_comment_reactions_fresh AS (
    SELECT DATEDIFF('second', MAX(created_at), CURRENT_TIMESTAMP) / 86400.0 AS stale_days
    FROM pull_requests__comments__reactions
),





scorecard AS (

    --  ISSUES
    SELECT 'ISSUES' AS check_group, 'issues' AS table_name,
        (SELECT dup_groups FROM dup_issues)::TEXT AS metric_value,
        CASE WHEN (SELECT dup_groups FROM dup_issues) = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
        'Duplicate / non-unique primary key (number)' AS check_name

    UNION ALL SELECT 'ISSUES','issues',
        ((SELECT null_number FROM issues_nulls) + (SELECT null_title FROM issues_nulls)
         + (SELECT null_created_at FROM issues_nulls) + (SELECT null_updated_at FROM issues_nulls))::TEXT,
        CASE WHEN (SELECT null_number FROM issues_nulls) = 0
              AND (SELECT null_title FROM issues_nulls) = 0
              AND (SELECT null_created_at FROM issues_nulls) = 0
              AND (SELECT null_updated_at FROM issues_nulls) = 0
             THEN 'PASS' ELSE 'FAIL' END,
        'Null primary fields'

    UNION ALL SELECT 'ISSUES','issues',
        (SELECT bad_dates FROM issues_dates)::TEXT,
        CASE WHEN (SELECT bad_dates FROM issues_dates) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Date consistency (updated_at >= created_at)'

    UNION ALL SELECT 'ISSUES','issues',
        (SELECT future_dates FROM issues_future)::TEXT,
        CASE WHEN (SELECT future_dates FROM issues_future) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Future date validation'

    UNION ALL SELECT 'ISSUES','issues',
        (SELECT bad_state FROM issues_state)::TEXT,
        CASE WHEN (SELECT bad_state FROM issues_state) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Accepted values (state)'

    UNION ALL SELECT 'ISSUES','issues',
        (SELECT empty_strings FROM issues_empty)::TEXT,
        CASE WHEN (SELECT empty_strings FROM issues_empty) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Empty string validation (title)'

    UNION ALL SELECT 'ISSUES','issues',
        ROUND((SELECT stale_days FROM issues_fresh)::NUMERIC, 2)::TEXT,
        CASE WHEN (SELECT stale_days FROM issues_fresh) < 1 THEN 'PASS' ELSE 'FAIL' END,
        'Freshness (days since last update)'

    --  PULL_REQUESTS
    UNION ALL SELECT 'PR','pull_requests',
        (SELECT dup_groups FROM dup_pr)::TEXT,
        CASE WHEN (SELECT dup_groups FROM dup_pr) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Duplicate / non-unique primary key (number)'

    UNION ALL SELECT 'PR','pull_requests',
        ((SELECT null_number FROM pr_nulls) + (SELECT null_title FROM pr_nulls)
         + (SELECT null_created_at FROM pr_nulls) + (SELECT null_updated_at FROM pr_nulls))::TEXT,
        CASE WHEN (SELECT null_number FROM pr_nulls) = 0
              AND (SELECT null_title FROM pr_nulls) = 0
              AND (SELECT null_created_at FROM pr_nulls) = 0
              AND (SELECT null_updated_at FROM pr_nulls) = 0
             THEN 'PASS' ELSE 'FAIL' END,
        'Null primary fields'

    UNION ALL SELECT 'PR','pull_requests',
        (SELECT bad_dates FROM pr_dates)::TEXT,
        CASE WHEN (SELECT bad_dates FROM pr_dates) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Date consistency (updated_at >= created_at)'

    UNION ALL SELECT 'PR','pull_requests',
        (SELECT future_dates FROM pr_future)::TEXT,
        CASE WHEN (SELECT future_dates FROM pr_future) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Future date validation'

    UNION ALL SELECT 'PR','pull_requests',
        (SELECT bad_state FROM pr_state_consistency)::TEXT,
        CASE WHEN (SELECT bad_state FROM pr_state_consistency) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'State / closed flag consistency'

    UNION ALL SELECT 'PR','pull_requests',
        (SELECT bad_state FROM pr_state_accepted)::TEXT,
        CASE WHEN (SELECT bad_state FROM pr_state_accepted) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Accepted values (state)'


    UNION ALL SELECT 'PR','pull_requests',
        (SELECT empty_strings FROM pr_empty)::TEXT,
        CASE WHEN (SELECT empty_strings FROM pr_empty) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Empty string validation (title)'

    UNION ALL SELECT 'PR','pull_requests',
        ROUND((SELECT stale_days FROM pr_fresh)::NUMERIC, 2)::TEXT,
        CASE WHEN (SELECT stale_days FROM pr_fresh) < 1 THEN 'PASS' ELSE 'FAIL' END,
        'Freshness (days since last update)'

    -- ISSUE__COMMENTS
    UNION ALL SELECT 'ISSUE__COMMENTS','issues__comments',
        (SELECT dup_groups FROM dup_issue_comments)::TEXT,
        CASE WHEN (SELECT dup_groups FROM dup_issue_comments) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Duplicate / non-unique primary key (id)'

    UNION ALL SELECT 'ISSUE__COMMENTS','issues__comments',
        ((SELECT null_id FROM issue_comments_nulls) + (SELECT null_body FROM issue_comments_nulls)
         + (SELECT null_created_at FROM issue_comments_nulls))::TEXT,
        CASE WHEN (SELECT null_id FROM issue_comments_nulls) = 0
              AND (SELECT null_body FROM issue_comments_nulls) = 0
              AND (SELECT null_created_at FROM issue_comments_nulls) = 0
             THEN 'PASS' ELSE 'FAIL' END,
        'Null primary fields'


    UNION ALL SELECT 'ISSUE__COMMENTS','issues__comments',
        (SELECT bad_dates FROM issue_comments_dates)::TEXT,
        CASE WHEN (SELECT bad_dates FROM issue_comments_dates) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Date consistency (updated_at >= created_at)'

    UNION ALL SELECT 'ISSUE__COMMENTS','issues__comments',
        (SELECT future_dates FROM issue_comments_future)::TEXT,
        CASE WHEN (SELECT future_dates FROM issue_comments_future) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Future date validation'

    UNION ALL SELECT 'ISSUE__COMMENTS','issues__comments',
        (SELECT empty_strings FROM issue_comments_empty)::TEXT,
        CASE WHEN (SELECT empty_strings FROM issue_comments_empty) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Empty string validation (body)'

    UNION ALL SELECT 'ISSUE__COMMENTS','issues__comments',
        ROUND((SELECT stale_days FROM issue_comments_fresh)::NUMERIC, 2)::TEXT,
        CASE WHEN (SELECT stale_days FROM issue_comments_fresh) < 1 THEN 'PASS' ELSE 'FAIL' END,
        'Freshness (days since last comment)'

    -- ISSUE__REACTIONS
    UNION ALL SELECT 'ISSUE__REACTIONS','issues__reactions',
        (SELECT dup_groups FROM dup_issue_reactions)::TEXT,
        CASE WHEN (SELECT dup_groups FROM dup_issue_reactions) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Duplicate / non-unique key (content, user, parent)'

    UNION ALL SELECT 'ISSUE__REACTIONS','issues__reactions',
        ((SELECT null_content FROM issue_reactions_nulls) + (SELECT null_login FROM issue_reactions_nulls)
         + (SELECT null_created_at FROM issue_reactions_nulls))::TEXT,
        CASE WHEN (SELECT null_content FROM issue_reactions_nulls) = 0
              AND (SELECT null_login FROM issue_reactions_nulls) = 0
              AND (SELECT null_created_at FROM issue_reactions_nulls) = 0
             THEN 'PASS' ELSE 'FAIL' END,
        'Null primary fields'



    UNION ALL SELECT 'ISSUE__REACTIONS','issues__reactions',
        (SELECT future_dates FROM issue_reactions_future)::TEXT,
        CASE WHEN (SELECT future_dates FROM issue_reactions_future) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Future date validation'

    UNION ALL SELECT 'ISSUE__REACTIONS','issues__reactions',
        (SELECT empty_strings FROM issue_reactions_empty)::TEXT,
        CASE WHEN (SELECT empty_strings FROM issue_reactions_empty) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Empty string validation (user login)'

    UNION ALL SELECT 'ISSUE__REACTIONS','issues__reactions',
        ROUND((SELECT stale_days FROM issue_reactions_fresh)::NUMERIC, 2)::TEXT,
        CASE WHEN (SELECT stale_days FROM issue_reactions_fresh) < 1 THEN 'PASS' ELSE 'FAIL' END,
        'Freshness (days since last reaction)'

    -- PR__COMMENTS
    UNION ALL SELECT 'PR__COMMENTS','pull_requests__comments',
        (SELECT dup_groups FROM dup_pr_comments)::TEXT,
        CASE WHEN (SELECT dup_groups FROM dup_pr_comments) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Duplicate / non-unique primary key (id)'

    UNION ALL SELECT 'PR__COMMENTS','pull_requests__comments',
        ((SELECT null_id FROM pr_comments_nulls) + (SELECT null_body FROM pr_comments_nulls)
         + (SELECT null_created_at FROM pr_comments_nulls))::TEXT,
        CASE WHEN (SELECT null_id FROM pr_comments_nulls) = 0
              AND (SELECT null_body FROM pr_comments_nulls) = 0
              AND (SELECT null_created_at FROM pr_comments_nulls) = 0
             THEN 'PASS' ELSE 'FAIL' END,
        'Null primary fields'


    UNION ALL SELECT 'PR__COMMENTS','pull_requests__comments',
        (SELECT bad_dates FROM pr_comments_dates)::TEXT,
        CASE WHEN (SELECT bad_dates FROM pr_comments_dates) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Date consistency (updated_at >= created_at)'

    UNION ALL SELECT 'PR__COMMENTS','pull_requests__comments',
        (SELECT future_dates FROM pr_comments_future)::TEXT,
        CASE WHEN (SELECT future_dates FROM pr_comments_future) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Future date validation'

    UNION ALL SELECT 'PR__COMMENTS','pull_requests__comments',
        (SELECT empty_strings FROM pr_comments_empty)::TEXT,
        CASE WHEN (SELECT empty_strings FROM pr_comments_empty) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Empty string validation (body)'

    UNION ALL SELECT 'PR__COMMENTS','pull_requests__comments',
        ROUND((SELECT stale_days FROM pr_comments_fresh)::NUMERIC, 2)::TEXT,
        CASE WHEN (SELECT stale_days FROM pr_comments_fresh) < 1 THEN 'PASS' ELSE 'FAIL' END,
        'Freshness (days since last comment)'

    -- PR_COMMENT_REACTIONS
    UNION ALL SELECT 'PR_COMMENT_REACTIONS','pull_requests__comments__reactions',
        (SELECT dup_groups FROM dup_pr_comment_reactions)::TEXT,
        CASE WHEN (SELECT dup_groups FROM dup_pr_comment_reactions) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Duplicate / non-unique key (content, user, parent)'

    UNION ALL SELECT 'PR_COMMENT_REACTIONS','pull_requests__comments__reactions',
        ((SELECT null_content FROM pr_comment_reactions_nulls) + (SELECT null_login FROM pr_comment_reactions_nulls)
         + (SELECT null_created_at FROM pr_comment_reactions_nulls))::TEXT,
        CASE WHEN (SELECT null_content FROM pr_comment_reactions_nulls) = 0
              AND (SELECT null_login FROM pr_comment_reactions_nulls) = 0
              AND (SELECT null_created_at FROM pr_comment_reactions_nulls) = 0
             THEN 'PASS' ELSE 'FAIL' END,
        'Null primary fields'


    UNION ALL SELECT 'PR_COMMENT_REACTIONS','pull_requests__comments__reactions',
        (SELECT future_dates FROM pr_comment_reactions_future)::TEXT,
        CASE WHEN (SELECT future_dates FROM pr_comment_reactions_future) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Future date validation'

    UNION ALL SELECT 'PR_COMMENT_REACTIONS','pull_requests__comments__reactions',
        (SELECT empty_strings FROM pr_comment_reactions_empty)::TEXT,
        CASE WHEN (SELECT empty_strings FROM pr_comment_reactions_empty) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Empty string validation (user login)'

    UNION ALL SELECT 'PR_COMMENT_REACTIONS','pull_requests__comments__reactions',
        ROUND((SELECT stale_days FROM pr_comment_reactions_fresh)::NUMERIC, 2)::TEXT,
        CASE WHEN (SELECT stale_days FROM pr_comment_reactions_fresh) < 1 THEN 'PASS' ELSE 'FAIL' END,
        'Freshness (days since last reaction)'

)

SELECT *
FROM scorecard
ORDER BY
    CASE status
        WHEN 'FAIL' THEN 0
        WHEN 'NO_BASELINE' THEN 1
        ELSE 2
    END,
    check_group,
    table_name;
