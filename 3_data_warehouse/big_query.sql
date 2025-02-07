-- create external table referring to gcs path
CREATE OR REPLACE EXTERNAL TABLE `splendid-strand-448621-u2.warehouse_dataset.external_yellow_tripdata`
OPTIONS (
  format = 'CSV',
  uris = ['gs://splendid-strand-448621-u2-kestra-bucket/yellow_tripdata_2019-*.csv', 'gs://splendid-strand-448621-u2-kestra-bucket/yellow_tripdata_2020-*.csv']
);

-- check yellow trip data
SELECT * FROM `splendid-strand-448621-u2.warehouse_dataset.external_yellow_tripdata` limit 10;

-- create a non partitioned table from external table
CREATE OR REPLACE TABLE `splendid-strand-448621-u2.warehouse_dataset.yellow_tripdata_non_partitoned` AS
SELECT * FROM `splendid-strand-448621-u2.warehouse_dataset.external_yellow_tripdata`;

-- create a partitioned table from external table
CREATE OR REPLACE TABLE `splendid-strand-448621-u2.warehouse_dataset.yellow_tripdata_partitoned`
PARTITION BY DATE(tpep_pickup_datetime) AS
SELECT * FROM `splendid-strand-448621-u2.warehouse_dataset.external_yellow_tripdata`;

-- impact of partition
-- scan 1.6 GB of data
SELECT DISTINCT(VendorID)
FROM `splendid-strand-448621-u2.warehouse_dataset.yellow_tripdata_non_partitoned`
WHERE DATE(tpep_pickup_datetime) BETWEEN '2019-06-01' AND '2019-06-30';

-- scan 106 MB of data
SELECT DISTINCT(VendorID)
FROM `splendid-strand-448621-u2.warehouse_dataset.yellow_tripdata_partitoned`
WHERE DATE(tpep_pickup_datetime) BETWEEN '2019-06-01' AND '2019-06-30';

-- look into the partitons
SELECT table_name, partition_id, total_rows
FROM `warehouse_dataset.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'yellow_tripdata_partitoned'
ORDER BY total_rows DESC;

-- create a partition and cluster table
CREATE OR REPLACE TABLE `splendid-strand-448621-u2.warehouse_dataset.yellow_tripdata_partitoned_clustered`
PARTITION BY DATE(tpep_pickup_datetime)
CLUSTER BY VendorID AS
SELECT * FROM `splendid-strand-448621-u2.warehouse_dataset.external_yellow_tripdata`;

-- impact of cluster
-- scan 1.06 GB of data
SELECT count(*) as trips
FROM `splendid-strand-448621-u2.warehouse_dataset.yellow_tripdata_partitoned`
WHERE DATE(tpep_pickup_datetime) BETWEEN '2019-06-01' AND '2020-12-31'
  AND VendorID = 1;

-- scan 854 MB of data
SELECT count(*) as trips
FROM `splendid-strand-448621-u2.warehouse_dataset.yellow_tripdata_partitoned_clustered`
WHERE DATE(tpep_pickup_datetime) BETWEEN '2019-06-01' AND '2020-12-31'
  AND VendorID = 1;