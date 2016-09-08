SELECT id, author, body, date FROM issue_comments
WHERE issue_comments.issue_id = %s
ORDER BY date desc;