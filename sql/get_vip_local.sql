with helper as (
    select client_id, max(id) as maxid from client_summary  group by client_id
),
last_summary as (
    SELECT client_summary.* from client_summary INNER JOIN helper ON helper.maxid = client_summary.id
),
open_issues as (
    SELECT client_id, COUNT(issue.id) as opened
    FROM issue
    WHERE NOT issue.closed
    GROUP BY client_id
)

SELECT
  client.name ,
  last_summary.calls_long_last,
  last_summary.calls_last,
  last_summary.duration_last,
  COALESCE(open_issues.opened, 0) as issues_count
FROM last_summary
INNER JOIN client ON last_summary.client_id = client.id
LEFT JOIN open_issues ON last_summary.client_id = open_issues.client_id
WHERE  last_summary.last_update > date_trunc('day', now())
ORDER BY issues_count DESC, duration_last DESC;
