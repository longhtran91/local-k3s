#!/bin/bash
export S3_BUCKET=$1

aws s3 rm s3://$S3_BUCKET --recursive --profile admin
aws s3 rb s3://$S3_BUCKET --profile admin