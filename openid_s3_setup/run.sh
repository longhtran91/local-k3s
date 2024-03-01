#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

export AWS_REGION=us-east-1
export S3_BUCKET=$1


_bucket_name=$(aws s3api list-buckets  --query "Buckets[?Name=='$S3_BUCKET'].Name | [0]" --out text)
if [ $_bucket_name == "None" ]; then
    if [ "$AWS_REGION" == "us-east-1" ]; then
        aws s3api create-bucket --bucket $S3_BUCKET --profile admin
    else
        aws s3api create-bucket --bucket $S3_BUCKET --create-bucket-configuration LocationConstraint=$AWS_REGION --profile admin
    fi

    aws s3api delete-public-access-block --bucket $S3_BUCKET --profile admin

    cat > $SCRIPT_DIR/policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$S3_BUCKET/*",
      "Condition": {
        "StringEquals": {
          "s3:ExistingObjectTag/public": "yes"
        }
      }
    }
  ]
}
EOF

    aws s3api put-bucket-policy --bucket $S3_BUCKET --profile admin --policy file://$SCRIPT_DIR/policy.json && rm -f $SCRIPT_DIR/policy.json
fi

aws s3 cp $SCRIPT_DIR/openid-configuration s3://$S3_BUCKET/.well-known/openid-configuration --profile admin && rm -f $SCRIPT_DIR/openid-configuration
aws s3api put-object-tagging --bucket $S3_BUCKET --key .well-known/openid-configuration --tagging "TagSet=[{Key=public,Value=yes}]" --profile admin

aws s3 cp $SCRIPT_DIR/jwks s3://$S3_BUCKET/openid/v1/jwks --profile admin && rm -f $SCRIPT_DIR/jwks
aws s3api put-object-tagging --bucket $S3_BUCKET --key openid/v1/jwks --tagging "TagSet=[{Key=public,Value=yes}]" --profile admin