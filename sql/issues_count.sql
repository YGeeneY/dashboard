SELECT client.name, count(*) FROM issue
INNER JOIN client ON client.id = issue.client_id
WHERE NOT issue.closed
GROUP BY client.name;