SELECT issue.id, issue.issue, issue.closed, issue.date, client.name, issue.updated FROM issue
INNER JOIN client ON client.id = issue.client_id
WHERE client.name = %s
ORDER BY closed ASC, date DESC;