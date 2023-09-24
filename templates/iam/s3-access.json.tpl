{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowToPushCloudWatchLog",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:GetLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Sid": "AllowS3OperationsOnElasticBeanstalkBuckets",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": ["${s3_resources}","${s3_resources}/*"]
    }

  ]
}