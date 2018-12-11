CREATE EXTERNAL TABLE IF NOT EXISTS ${athena_db}.${athena_table} (
    invoiceid string,
    payeraccountid string,
    linkedaccountid string,
    recordtype string,
    productname string,
    rateid string,
    subscriptionid string,
    pricingplanid string,
    usagetype string,
    operation string,
    availabilityzone string,
    reservedinstance string,
    itemdescription string,
    usagestartdate string,
    usageenddate string,
    usagequantity string,
    blendedrate string,
    blendedcost string,
    unblendedrate string,
    unblendedcost string )
    ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
    WITH SERDEPROPERTIES ( 'serialization.format' = '1' )
    LOCATION 's3://${s3_bucket_name}/' TBLPROPERTIES ('has_encrypted_data'='false');
