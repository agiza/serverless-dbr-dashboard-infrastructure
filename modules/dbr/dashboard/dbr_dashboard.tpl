{
    "widgets": [
        {
           "view": "timeSeries",
           "type":"metric",
           "width": 12,
           "height": 7,
           "properties":{
            "metrics": [
                [ "DBR", "TotalCostService", "service", "Amazon API Gateway" ],
                [ "...", "Amazon CloudFront" ],
                [ "...", "Amazon Cognito" ],
                [ "...", "Amazon DynamoDB" ],
                [ "...", "Amazon EC2 Container Registry (ECR)" ],
                [ "...", "Amazon Elastic Compute Cloud" ],
                [ "...", "Amazon Elastic File System" ],
                [ "...", "Amazon ElastiCache" ],
                [ "...", "Amazon GuardDuty" ],
                [ "...", "Amazon Kinesis" ],
                [ "...", "Amazon Kinesis Firehose" ],
                [ "...", "Amazon Kinesis Video Streams" ],
                [ "...", "Amazon QuickSight" ],
                [ "...", "Amazon RDS Service" ],
                [ "...", "Amazon Relational Database Service" ],
                [ "...", "Amazon Route 53" ],
                [ "...", "Amazon Simple Email Service" ],
                [ "...", "Amazon Simple Notification Service" ],
                [ "...", "Amazon Simple Queue Service" ],
                [ "...", "Amazon Simple Storage Service" ],
                [ "...", "Amazon SimpleDB" ],
                [ "...", "Amazon Virtual Private Cloud" ],
                [ "...", "Amazon WorkDocs" ],
                [ "...", "Amazon WorkSpaces" ],
                [ "...", "AmazonCloudWatch" ],
                [ "...", "AWS CloudTrail" ],
                [ "...", "AWS CodeCommit" ],
                [ "...", "AWS CodePipeline" ],
                [ "...", "AWS Data Pipeline" ],
                [ "...", "AWS Data Transfer" ],
                [ "...", "AWS Database Migration Service" ],
                [ "...", "AWS Directory Service" ],
                [ "...", "AWS Glue" ],
                [ "...", "AWS Key Management Service" ],
                [ "...", "AWS Lambda" ],
                [ "...", "AWS Premium Support (Silver)" ],
                [ "...", "AWS Support (Business)" ],
                [ "...", "AWS WAF" ],
                [ "...", "CodeBuild" ]
            ],
              "period":300,
              "stat":"Average",
              "region": "${region}",
              "title":"Cost Per Service per Hour ($)"
           }
        },
        {
           "view": "timeSeries",
           "type":"metric",
           "width": 12,
           "height": 7,
           "properties":{
            "metrics": [
                [ "DBR", "TotalCost", "cost", "total" ]
            ],
              "period":300,
              "stat":"Average",
              "region": "${region}",
              "title":"Total Cost per Hour ($)"
           }
        }
    ]
}