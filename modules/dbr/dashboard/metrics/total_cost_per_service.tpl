{
  "bucket_output": { "S": "s3://${s3_bucket_name}/output" },
  "cw_dimension": { "S": "service" },
  "cw_name": { "S": "TotalCostService" },
  "cw_type": { "S": "None" },
  "db": { "S": "${athena_db}" },
  "metric_name": { "S": "total-cost-per-service" },
  "sql": { "S": "SELECT productname AS dimension, usagetype AS usagetype_dimension, substr(usagestartdate,1,13) AS date, SUM(try_cast(unblendedcost AS double)) AS value FROM ${athena_table} WHERE try_cast(usagestartdate as timestamp) > now() - interval '10' day AND try_cast(unblendedcost AS double) > 0 AND productname = 'Amazon Elastic Compute Cloud' GROUP BY  productname, usagetype, substr(usagestartdate, 1, 13) ORDER BY  substr(usagestartdate, 1, 13) desc,productname,usagetype" }
}