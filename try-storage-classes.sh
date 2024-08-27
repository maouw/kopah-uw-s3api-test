#!/usr/bin/env bash

# This script tests the storage classes by creating a bucket, uploading a file with each storage class, and then deleting the file and bucket.

s3cmd -c .s3cfg mb s3://storage-classes
date >|/tmp/date.txt
for x in STANDARD REDUCED_REDUNDANCY STANDARD_IA ONEZONE_IA INTELLIGENT_TIERING GLACIER DEEP_ARCHIVE LUKEWARM FROZEN; do
	if s3cmd -q -c .s3cfg put /tmp/date.txt s3://storage-classes/date-$x.txt --storage-class $x; then
		echo "Storage class $x OK"
		s3cmd -q -c .s3cfg rm s3://storage-classes/date-$x.txt
	else
		echo "Couldn't put a file with storage class $x"
	fi
done
s3cmd -c .s3cfg rb s3://storage-classes
rm /tmp/date.txt
