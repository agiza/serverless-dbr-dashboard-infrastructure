{
  "bucket_output": { "S": "s3://${s3_bucket_name}/output" },
  "cw_dimension": { "S": "cost" },
  "cw_name": { "S": "TotalCost" },
  "cw_type": { "S": "None" },
  "db": { "S": "${athena_db}" },
  "metric_name": { "S": "total-cost" },
  "sql": { "S": "SELECT 'total' as dimension, substr(usagestartdate, 1, 13) AS date, sum(cast(unblendedcost as double)) AS value FROM ${athena_table} WHERE try_cast(usagestartdate as timestamp) > now() - interval '11' day AND try_cast(unblendedcost AS double) > 0 GROUP BY substr(usagestartdate, 1, 13) ORDER BY substr(usagestartdate, 1, 13) desc"}
}