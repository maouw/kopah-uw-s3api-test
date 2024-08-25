# University of Washington KOPAH S3 Testing

This repository contains code for testing the University of Washington's [KOPAH](https://hyak.uw.edu/docs/storage/kopah/) S3 storage service during its trial period.

## Tools

The following tools were used to test the KOPAH S3 service:

- [`rclone`](https://rclone.org): A command-line program to manage files on cloud storage services (version v1.67.0)
- [`s3-tests`](https://github.com/ceph/s3-tests) by Ceph: A suite of tests for S3-compatible storage services (included under `vendor/ceph--s3-tests`)
- [`warp`](https://github.com/minio/warp) by MinIO: A tool for generating load on S3-compatible storage services (included under `vendor/minio--warp`)
- [`ossperf`](https://github.com/christianbaun/ossperf) by Christian Baun: A tool for measuring the performance of S3-compatible storage services (included under `vendor/christianbaun--ossperf`)

## Notes
