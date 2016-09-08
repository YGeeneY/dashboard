SELECT
  "instance".name,
  instance_summary.calls_long_last,
  instance_summary.calls_last,
  instance_summary.duration_last,
  instance_package.expires,
  instance_summary.acd_last,
  instance_summary.asr_last,
  instance_summary.last_update
FROM  "instance"
INNER JOIN instance_summary ON "instance".id = instance_summary.instance_id
INNER JOIN instance_package  ON "instance".id =  instance_package.instance_id AND instance_package.package_id = 1
WHERE
  (instance_package.expires > now())
  AND calls_long_last > 200
ORDER BY calls_last DESC;
