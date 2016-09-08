SELECT issue.id, issue.issue, issue.closed, issue.date, client.name, issue.updated FROM issue
INNER JOIN client ON client.id = issue.client_id
WHERE issue.id = %s