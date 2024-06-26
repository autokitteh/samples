# Data Pipeline Workflow

Workflow will get event on new GPX file in S3 bucket, process it and insert the points to a PostgreSQL database.

## Configuring S3 Bucket for Notifications

- [Change Bucket Access Policy][ap]


[ap]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/ways-to-add-notification-config-to-bucket.html#step1-create-sns-topic-for-notification
