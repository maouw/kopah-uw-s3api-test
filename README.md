# University of Washington KOPAH S3 Testing

This repository contains code for testing the University of Washington's [KOPAH](https://hyak.uw.edu/docs/storage/kopah/) S3 storage service during its trial period.


## Features

### Serving static web content

The KOPAH endpoint is capable of serving web content provided appropriate permissions.

```bash

# Create a bucket
s3cmd mb s3://nrdg-pub

# Set the bucket ACL to public-read
s3cmd setacl s3://nrdg-pub --acl-public

# Upload a file
s3cmd put index.html s3://nrdg-pub/index.html

# Access the file
echo "Access the file at: https://s3.kopah.orci.washington.edu/nrdg-pub/index.html"
```

WARNING: The above example makes the bucket and its contents readable to the public. Be sure to restrict access to sensitive data.

### Using `rclone`

`rclone` can be configured to use the KOPAH endpoint as a remote.

For interactive configuration, use:

- the storage type `4 / Amazon S3 Compliant Storage Providers including AWS, ...`
- the S3 provider `32 / Any other S3 compatible provider`

If you have a configuration file, you can use the following template:

```ini
[kopah]
type = s3
provider = Other
access_key_id = <access_key>
secret_access_key = <secret_key>
endpoint = s3.kopah.orci.washington.edu
```

## Testing

The following tools were used to help test the KOPAH S3 service:

- [`rclone`](https://rclone.org): A command-line program to manage files on cloud storage services (version v1.67.0)
- [`s3-tests`](https://github.com/ceph/s3-tests) by Ceph: A suite of tests for S3-compatible storage services (included under `vendor/ceph--s3-tests`)
- [`warp`](https://github.com/minio/warp) by MinIO: A tool for generating load on S3-compatible storage services (included under `vendor/minio--warp`)
- [`ossperf`](https://github.com/christianbaun/ossperf) by Christian Baun: A tool for measuring the performance of S3-compatible storage services (included under `vendor/christianbaun--ossperf`)

## Filesystem tests

`rclone test info` was used to test filenames and upload methods:

```
# Check control characters:
stringNeedsEscaping = ['/', '\x00']

# Check max filename length
maxFileLength = 998 // for 1 byte unicode characters
maxFileLength = 499 // for 2 byte unicode characters
maxFileLength = 332 // for 3 byte unicode characters
maxFileLength = 249 // for 4 byte unicode characters

# Check UTF-8 Normalization
canWriteUnnormalized = true
canReadUnnormalized = true
canReadRenormalized = false

# Check uploads with indeterminate file size:
canStream = true

# Check can store all possible base32768 characters:
base32768isOK = true // make sure maxFileLength for 2 byte unicode chars is the same as for 1 byte characters
```

### Performance

Throughput for various operations was tested using `warp` and `ossperf` on a Hyak Klone compute node and a laptop ("maoxps") on the UW network.

The tests were conducted during business hours on a weekday, so the results may not be representative of the service's full capacity, how one service compares to another, or how one tool compares to another. However, the tests indicate that KOPAH is at least as fast as the `us-west-2` endpoint.

#### warp

Used `warp mixed` to test throughput for various operations on a single thread.

| Endpoint  | Machine | Operation | Throughput (MiB/s) | Throughput (obj/s) |
| --------- | ------- | --------- | ------------------ | ------------------ |
| us-west-2 | klone   | GET       | 16.84              |                    |
| us-west-2 | klone   | PUT       | 5.46               |                    |
| us-west-2 | klone   | STAT      |                    | 1.12               |
| us-west-2 | klone   | DELETE    |                    | 0.36               |
| kopah     | klone   | GET       | 62.55              |                    |
| kopah     | klone   | PUT       | 21.01              |                    |
| kopah     | klone   | STAT      |                    |                    |
| kopah     | klone   | DELETE    |                    |                    |

| Endpoint  | Machine | Operation | Throughput (MiB/s) | Throughput (obj/s) |
| --------- | ------- | --------- | ------------------ | ------------------ |
| kopah     | maoxps  | GET       | 64.17              |                    |
| kopah     | maoxps  | PUT       | 21.26              |                    |
| kopah     | maoxps  | STAT      |                    | 4.31               |
| kopah     | maoxps  | DELETE    |                    | 1.43               |
| us-west-2 | maoxps  | GET       | 19.37              |                    |
| us-west-2 | maoxps  | PUT       | 30.1               |                    |
| us-west-2 | maoxps  | STAT      |                    | 1.34               |
| us-west-2 | maoxps  | DELETE    |                    | 0.42               |

### ossperf

Tested operations with 100 files of 16 MiB each using a single thread for KOPAH and us-west-2 endpoints on a single thread.

| Endpoint  | Machine | Create Bucket (s) | Put (s)    | List (s) | Get (s) | Delete (s) | Delete Bucket (s) | Upload (MiB/s) | Download (MiB/s) |
| --------- | ------- | ------------- | ------ | ---- | ------ | ------ | ------------- | -------------- | ---------------- |
|us-west-2|klone|1.11|131.59|.74|351.41|18.56|.72|102.00|38.19|
|kopah|klone|.18|39.16|.23|17.39|1.33|.24|58.52|771.63|

| Endpoint | Machine | Create Bucket (s) | Put (s)    | List (s) | Get (s)    | Delete (s) | Delete Bucket (s) | Upload (MiB/s) | Download (MiB/s) |
| --------- | ------- | ------------- | ------ | ---- | ------ | ------ | ------------- | -------------- | ---------------- |
|us-west-2|maoxps|1.03|107.50|.74|228.03|16.92|.72|124.86|58.86|
|kopah|maoxps|.21|38.83|.22|17.86|1.43|.20|345.68|751.58|

## S3 API Compatibility

### Storage classes

We attempted to use several standard AWS and Ceph storage classes (`STANDARD REDUCED_REDUNDANCY STANDARD_IA ONEZONE_IA INTELLIGENT_TIERING GLACIER DEEP_ARCHIVE LUKEWARM FROZEN`) using `s3cmd`, but only `STANDARD` was supported. See `try_storage_classes.sh` for the script used.

### `s3-tests` Test Suite

We tested Ceph's [`s3-tests` tool](https://github.com/ceph/s3-tests/tree/34589710546bd70479b47e3384ac9ca808e73773) against the KOPAH endpoint.

#### `test_s3.py`

The functional tests at `vendor/ceph--s3-tests/s3tests_boto3/functional/test_s3.py` resulted in:

`==== 124 failed, 426 passed, 10 skipped, 685 warnings in 1064.47s (0:17:44) ====`

##### Failures

```plain
test_account_usage
test_head_bucket_usage
test_object_write_to_nonexist_bucket
test_object_write_with_chunked_transfer_encoding
test_object_head_zero_bytes
test_object_set_get_unicode_metadata
test_post_object_upload_size_rgw_chunk_size_bug
test_get_object_ifnonematch_good
test_get_object_ifmodifiedsince_failed
test_object_put_acl_mtime
test_object_anon_put
test_bucket_create_exists_nonowner
test_object_acl_canned_bucketownerread
**test_object_acl_canned_bucketownerfullcontrol**
test_bucket_acl_grant_userid_read
test_bucket_acl_grant_userid_readacp
test_bucket_acl_grant_userid_write
test_bucket_acl_grant_userid_writeacp
test_bucket_acl_grant_email
test_logging_toggle
test_access_bucket_private_object_private
test_access_bucket_private_objectv2_private
test_access_bucket_private_object_publicread
test_access_bucket_private_objectv2_publicread
test_access_bucket_private_object_publicreadwrite
test_access_bucket_private_objectv2_publicreadwrite
test_access_bucket_publicread_object_private
test_access_bucket_publicread_object_publicread
test_access_bucket_publicread_object_publicreadwrite
test_access_bucket_publicreadwrite_object_private
test_access_bucket_publicreadwrite_object_publicread
test_access_bucket_publicreadwrite_object_publicreadwrite
test_list_buckets_invalid_auth
test_list_buckets_bad_auth
test_object_copy_zero_size
test_object_copy_not_owned_bucket
test_multipart_upload_contents
test_multipart_get_part
test_multipart_single_get_part
test_non_multipart_get_part
test_100_continue
test_cors_presigned_put_object_with_acl
test_cors_presigned_put_object_tenant_with_acl
test_set_bucket_tagging
test_atomic_dual_conditional_write_1mb
test_atomic_write_bucket_gone
test_versioning_obj_suspended_copy
test_versioning_obj_create_overwrite_multipart
test_versioning_multi_object_delete_with_marker_create
test_lifecycle_expiration
test_lifecyclev2_expiration
test_lifecycle_expiration_tags2
test_lifecycle_expiration_versioned_tags2
test_lifecycle_expiration_noncur_tags1
test_lifecycle_expiration_newer_noncurrent
test_lifecycle_expiration_size_gt
test_lifecycle_expiration_size_lt
test_lifecycle_expiration_date
test_lifecycle_noncur_expiration
test_lifecycle_deletemarker_expiration
test_lifecycle_multipart_expiration
test_encryption_sse_c_enforced_with_bucket_policy
test_encryption_sse_c_deny_algo_with_bucket_policy
test_sse_kms_method_head
test_sse_kms_present
test_sse_kms_not_declared
test_sse_kms_multipart_upload
test_sse_kms_multipart_invalid_chunks_1
test_sse_kms_multipart_invalid_chunks_2
test_sse_kms_post_object_authenticated_request
test_sse_kms_transfer_1b
test_sse_kms_transfer_1kb
test_sse_kms_transfer_1MB
test_sse_kms_transfer_13b
test_bucket_policy_different_tenant
test_bucket_policy_tenanted_bucket
test_bucket_policy_set_condition_operator_end_with_IfExists
test_bucket_policy_get_obj_existing_tag
test_bucket_policy_get_obj_tagging_existing_tag
test_bucket_policy_put_obj_tagging_existing_tag
test_bucket_policy_put_obj_copy_source
test_bucket_policy_put_obj_copy_source_meta
test_bucket_policy_put_obj_acl
test_bucket_policy_put_obj_grant
test_bucket_policy_put_obj_s3_noenc
test_bucket_policy_put_obj_s3_incorrect_algo_sse_s3
test_bucket_policy_put_obj_s3_kms
test_bucket_policy_put_obj_kms_noenc
test_bucket_policy_put_obj_kms_s3
test_bucket_policy_put_obj_request_obj_tag
test_bucket_policy_get_obj_acl_existing_tag
test_object_lock_put_obj_retention
test_object_lock_delete_multipart_object_with_retention
test_object_lock_delete_multipart_object_with_legal_hold_on
test_copy_object_ifmatch_failed
test_copy_object_ifnonematch_good
test_object_read_unreadable
test_get_nonpublicpolicy_principal_bucket_policy_status
test_bucket_policy_allow_notprincipal
test_get_undefined_public_block
test_get_public_block_deny_bucket_policy
test_block_public_policy_with_principal
test_ignore_public_acls
test_sse_s3_default_upload_1b
test_sse_s3_default_upload_1kb
test_sse_s3_default_upload_1mb
test_sse_s3_default_upload_8mb
test_sse_kms_default_upload_1b
test_sse_kms_default_upload_1kb
test_sse_kms_default_upload_1mb
test_sse_kms_default_upload_8mb
test_sse_s3_default_method_head
test_sse_s3_default_multipart_upload
test_sse_s3_default_post_object_authenticated_request
test_sse_kms_default_post_object_authenticated_request
test_sse_s3_encrypted_upload_1b
test_sse_s3_encrypted_upload_1kb
test_sse_s3_encrypted_upload_1mb
test_sse_s3_encrypted_upload_8mb
test_get_object_torrent
test_object_checksum_sha256
test_multipart_checksum_sha256
test_multipart_checksum_3parts
test_post_object_upload_checksum
```

##### Skipped

```plain
test_bucket_get_location
test_lifecycle_transition ("requires 3 or more storage classes")
test_lifecycle_transition_single_rule_multi_trans ("requires 3 or more storage classes")
test_lifecycle_set_noncurrent_transition ("requires 3 or more storage classes")
test_lifecycle_noncur_transition ("requires 3 or more storage classes")
test_lifecycle_plain_null_version_current_transition ("requires 3 or more storage classes")
test_lifecycle_cloud_transition ("requires 3 or more storage classes")
test_lifecycle_cloud_multiple_transition ("requires 3 or more storage classes")
test_lifecycle_noncur_cloud_transition ("requires 3 or more storage classes")
test_lifecycle_cloud_transition_large_obj ("requires 2 or more storage classes")
```

##### Passed

```plain
test_bucket_list_empty
test_bucket_list_distinct
test_bucket_list_many
test_bucket_listv2_many
test_basic_key_count
test_bucket_list_delimiter_basic
test_bucket_listv2_delimiter_basic
test_bucket_listv2_encoding_basic
test_bucket_list_encoding_basic
test_bucket_list_delimiter_prefix
test_bucket_listv2_delimiter_prefix
test_bucket_listv2_delimiter_prefix_ends_with_delimiter
test_bucket_list_delimiter_prefix_ends_with_delimiter
test_bucket_list_delimiter_alt
test_bucket_listv2_delimiter_alt
test_bucket_list_delimiter_prefix_underscore
test_bucket_listv2_delimiter_prefix_underscore
test_bucket_list_delimiter_percentage
test_bucket_listv2_delimiter_percentage
test_bucket_list_delimiter_whitespace
test_bucket_listv2_delimiter_whitespace
test_bucket_list_delimiter_dot
test_bucket_listv2_delimiter_dot
test_bucket_list_delimiter_unreadable
test_bucket_listv2_delimiter_unreadable
test_bucket_list_delimiter_empty
test_bucket_listv2_delimiter_empty
test_bucket_list_delimiter_none
test_bucket_listv2_delimiter_none
test_bucket_listv2_fetchowner_notempty
test_bucket_listv2_fetchowner_defaultempty
test_bucket_listv2_fetchowner_empty
test_bucket_list_delimiter_not_exist
test_bucket_listv2_delimiter_not_exist
test_bucket_list_delimiter_not_skip_special
test_bucket_list_prefix_basic
test_bucket_listv2_prefix_basic
test_bucket_list_prefix_alt
test_bucket_listv2_prefix_alt
test_bucket_list_prefix_empty
test_bucket_listv2_prefix_empty
test_bucket_list_prefix_none
test_bucket_listv2_prefix_none
test_bucket_list_prefix_not_exist
test_bucket_listv2_prefix_not_exist
test_bucket_list_prefix_unreadable
test_bucket_listv2_prefix_unreadable
test_bucket_list_prefix_delimiter_basic
test_bucket_listv2_prefix_delimiter_basic
test_bucket_list_prefix_delimiter_alt
test_bucket_listv2_prefix_delimiter_alt
test_bucket_list_prefix_delimiter_prefix_not_exist
test_bucket_listv2_prefix_delimiter_prefix_not_exist
test_bucket_list_prefix_delimiter_delimiter_not_exist
test_bucket_listv2_prefix_delimiter_delimiter_not_exist
test_bucket_list_prefix_delimiter_prefix_delimiter_not_exist
test_bucket_listv2_prefix_delimiter_prefix_delimiter_not_exist
test_bucket_list_maxkeys_one
test_bucket_listv2_maxkeys_one
test_bucket_list_maxkeys_zero
test_bucket_listv2_maxkeys_zero
test_bucket_list_maxkeys_none
test_bucket_listv2_maxkeys_none
test_bucket_list_unordered
test_bucket_listv2_unordered
test_bucket_list_maxkeys_invalid
test_bucket_list_marker_none
test_bucket_list_marker_empty
test_bucket_listv2_continuationtoken_empty
test_bucket_listv2_continuationtoken
test_bucket_listv2_both_continuationtoken_startafter
test_bucket_list_marker_unreadable
test_bucket_listv2_startafter_unreadable
test_bucket_list_marker_not_in_list
test_bucket_listv2_startafter_not_in_list
test_bucket_list_marker_after_list
test_bucket_listv2_startafter_after_list
test_bucket_list_return_data
test_bucket_list_return_data_versioning
test_bucket_list_objects_anonymous
test_bucket_listv2_objects_anonymous
test_bucket_list_objects_anonymous_fail
test_bucket_listv2_objects_anonymous_fail
test_bucket_notexist
test_bucketv2_notexist
test_bucket_delete_notexist
test_bucket_delete_nonempty
test_bucket_concurrent_set_canned_acl
test_bucket_create_delete
test_object_read_not_exist
test_object_requestid_matches_header_on_error
test_versioning_concurrent_multi_object_delete
test_multi_object_delete
test_multi_objectv2_delete
test_multi_object_delete_key_limit
test_multi_objectv2_delete_key_limit
test_object_write_check_etag
test_object_write_cache_control
test_object_write_expires
test_object_write_read_update_read_delete
test_object_set_get_metadata_none_to_good
test_object_set_get_metadata_none_to_empty
test_object_set_get_metadata_overwrite_to_empty
test_object_metadata_replaced_on_put
test_object_write_file
test_post_object_anonymous_request
test_post_object_authenticated_request
test_post_object_authenticated_no_content_type
test_post_object_authenticated_request_bad_access_key
test_post_object_set_success_code
test_post_object_set_invalid_success_code
test_post_object_upload_larger_than_chunk
test_post_object_set_key_from_filename
test_post_object_ignored_header
test_post_object_case_insensitive_condition_fields
test_post_object_escaped_field_values
test_post_object_success_redirect_action
test_post_object_invalid_signature
test_post_object_invalid_access_key
test_post_object_invalid_date_format
test_post_object_no_key_specified
test_post_object_missing_signature
test_post_object_missing_policy_condition
test_post_object_user_specified_header
test_post_object_request_missing_policy_specified_field
test_post_object_condition_is_case_sensitive
test_post_object_expires_is_case_sensitive
test_post_object_expired_policy
test_post_object_wrong_bucket
test_post_object_invalid_request_field_value
test_post_object_missing_expires_condition
test_post_object_missing_conditions_list
test_post_object_upload_size_limit_exceeded
test_post_object_missing_content_length_argument
test_post_object_invalid_content_length_argument
test_post_object_upload_size_below_minimum
test_post_object_empty_conditions
test_get_object_ifmatch_good
test_get_object_ifmatch_failed
test_get_object_ifnonematch_failed
test_get_object_ifmodifiedsince_good
test_get_object_ifunmodifiedsince_good
test_get_object_ifunmodifiedsince_failed
test_put_object_ifmatch_good
test_put_object_ifmatch_failed
test_put_object_ifmatch_overwrite_existed_good
test_put_object_ifmatch_nonexisted_failed
test_put_object_ifnonmatch_good
test_put_object_ifnonmatch_failed
test_put_object_ifnonmatch_nonexisted_good
test_put_object_ifnonmatch_overwrite_existed_failed
test_object_raw_get
test_object_raw_get_bucket_gone
test_object_delete_key_bucket_gone
test_object_raw_get_object_gone
test_bucket_head
test_bucket_head_notexist
test_bucket_head_extended
test_object_raw_get_bucket_acl
test_object_raw_get_object_acl
test_object_raw_authenticated
test_object_raw_response_headers
test_object_raw_authenticated_bucket_acl
test_object_raw_authenticated_object_acl
test_object_raw_authenticated_bucket_gone
test_object_raw_authenticated_object_gone
test_object_raw_get_x_amz_expires_not_expired
test_object_raw_get_x_amz_expires_not_expired_tenant
test_object_raw_get_x_amz_expires_out_range_zero
test_object_raw_get_x_amz_expires_out_max_range
test_object_raw_get_x_amz_expires_out_positive_range
test_object_anon_put_write_access
test_object_put_authenticated
test_object_presigned_put_object_with_acl
test_object_presigned_put_object_with_acl_tenant
test_object_raw_put_authenticated_expired
test_bucket_create_naming_bad_starts_nonalpha
test_bucket_create_naming_bad_short_one
test_bucket_create_naming_bad_short_two
test_bucket_create_naming_good_long_60
test_bucket_create_naming_good_long_61
test_bucket_create_naming_good_long_62
test_bucket_create_naming_good_long_63
test_bucket_list_long_name
test_bucket_create_naming_bad_ip
test_bucket_create_naming_dns_underscore
test_bucket_create_naming_dns_long
test_bucket_create_naming_dns_dash_at_end
test_bucket_create_naming_dns_dot_dot
test_bucket_create_naming_dns_dot_dash
test_bucket_create_naming_dns_dash_dot
test_bucket_create_exists
test_bucket_recreate_overwrite_acl
test_bucket_recreate_new_acl
test_bucket_acl_default
test_bucket_acl_canned_during_create
test_bucket_acl_canned
test_bucket_acl_canned_publicreadwrite
test_bucket_acl_canned_authenticatedread
test_object_acl_default
test_object_acl_canned_during_create
test_object_acl_canned
test_object_acl_canned_publicreadwrite
test_object_acl_canned_authenticatedread
test_object_acl_full_control_verify_owner
test_object_acl_full_control_verify_attributes
test_bucket_acl_canned_private_to_private
test_object_acl
test_object_acl_write
test_object_acl_writeacp
test_object_acl_read
test_object_acl_readacp
test_bucket_acl_grant_userid_fullcontrol
test_bucket_acl_grant_nonexist_user
test_object_header_acl_grants
test_bucket_header_acl_grants
test_bucket_acl_grant_email_not_exist
test_bucket_acl_revoke_all
test_buckets_create_then_list
test_buckets_list_ctime
test_list_buckets_anonymous
test_bucket_create_naming_good_starts_alpha
test_bucket_create_naming_good_starts_digit
test_bucket_create_naming_good_contains_period
test_bucket_create_naming_good_contains_hyphen
test_bucket_recreate_not_overriding
test_bucket_create_special_key_names
test_bucket_list_special_prefix
test_object_copy_16m
test_object_copy_same_bucket
test_object_copy_verify_contenttype
test_object_copy_to_itself
test_object_copy_to_itself_with_metadata
test_object_copy_diff_bucket
test_object_copy_not_owned_object_bucket
test_object_copy_canned_acl
test_object_copy_retaining_metadata
test_object_copy_replacing_metadata
test_object_copy_bucket_not_found
test_object_copy_key_not_found
test_object_copy_versioned_bucket
test_object_copy_versioned_url_encoding
test_object_copy_versioning_multipart_upload
test_multipart_upload_empty
test_multipart_upload_small
test_multipart_copy_small
test_multipart_copy_invalid_range
test_multipart_copy_improper_range
test_multipart_copy_without_range
test_multipart_copy_special_names
test_multipart_upload
test_multipart_copy_versioned
test_multipart_upload_resend_part
test_multipart_upload_multiple_sizes
test_multipart_copy_multiple_sizes
test_multipart_upload_size_too_small
test_multipart_upload_overwrite_existing_object
test_abort_multipart_upload
test_abort_multipart_upload_not_found
test_list_multipart_upload
test_list_multipart_upload_owner
test_multipart_upload_missing_part
test_multipart_upload_incorrect_etag
test_set_cors
test_cors_origin_response
test_cors_origin_wildcard
test_cors_header_option
test_cors_presigned_get_object
test_cors_presigned_get_object_tenant
test_cors_presigned_put_object
test_cors_presigned_put_object_tenant
test_atomic_read_1mb
test_atomic_read_4mb
test_atomic_read_8mb
test_atomic_write_1mb
test_atomic_write_4mb
test_atomic_write_8mb
test_atomic_dual_write_1mb
test_atomic_dual_write_4mb
test_atomic_dual_write_8mb
test_atomic_conditional_write_1mb
test_atomic_multipart_upload_write
test_multipart_resend_first_finishes_last
test_ranged_request_response_code
test_ranged_big_request_response_code
test_ranged_request_skip_leading_bytes_response_code
test_ranged_request_return_trailing_bytes_response_code
test_ranged_request_invalid_range
test_ranged_request_empty_object
test_versioning_bucket_create_suspend
test_versioning_obj_create_read_remove
test_versioning_obj_create_read_remove_head
test_versioning_obj_plain_null_version_removal
test_versioning_obj_plain_null_version_overwrite
test_versioning_obj_plain_null_version_overwrite_suspended
test_versioning_obj_suspend_versions
test_versioning_obj_create_versions_remove_all
test_versioning_obj_create_versions_remove_special_names
test_versioning_obj_list_marker
test_versioning_copy_obj_version
test_versioning_multi_object_delete
test_versioning_multi_object_delete_with_marker
test_versioned_object_acl
test_versioned_object_acl_no_version_specified
test_versioned_concurrent_object_create_concurrent_remove
test_versioned_concurrent_object_create_and_remove
test_lifecycle_set
test_lifecycle_get
test_lifecycle_get_no_id
test_lifecycle_expiration_versioning_enabled
test_lifecycle_expiration_tags1
test_lifecycle_id_too_long
test_lifecycle_same_id
test_lifecycle_invalid_status
test_lifecycle_set_date
test_lifecycle_set_invalid_date
test_lifecycle_expiration_days0
test_lifecycle_expiration_header_put
test_lifecycle_expiration_header_head
test_lifecycle_expiration_header_tags_head
test_lifecycle_expiration_header_and_tags_head
test_lifecycle_set_noncurrent
test_lifecycle_set_deletemarker
test_lifecycle_set_filter
test_lifecycle_set_empty_filter
test_lifecycle_set_multipart
test_lifecycle_transition_set_invalid_date
test_encrypted_transfer_1b
test_encrypted_transfer_1kb
test_encrypted_transfer_1MB
test_encrypted_transfer_13b
test_encryption_sse_c_method_head
test_encryption_sse_c_present
test_encryption_sse_c_other_key
test_encryption_sse_c_invalid_md5
test_encryption_sse_c_no_md5
test_encryption_sse_c_no_key
test_encryption_key_no_sse_c
test_encryption_sse_c_multipart_upload
test_encryption_sse_c_unaligned_multipart_upload
test_encryption_sse_c_multipart_invalid_chunks_1
test_encryption_sse_c_multipart_invalid_chunks_2
test_encryption_sse_c_multipart_bad_download
test_encryption_sse_c_post_object_authenticated_request
test_sse_kms_no_key
test_sse_kms_read_declare
test_bucket_policy
test_bucketv2_policy
test_bucket_policy_acl
test_bucketv2_policy_acl
test_bucket_policy_another_bucket
test_bucketv2_policy_another_bucket
test_get_obj_tagging
test_get_obj_head_tagging
test_put_max_tags
test_put_excess_tags
test_put_max_kvsize_tags
test_put_excess_key_tags
test_put_excess_val_tags
test_put_modify_tags
test_put_delete_tags
test_post_object_tags_anonymous_request
test_post_object_tags_authenticated_request
test_put_obj_with_tags
test_get_tags_acl_public
test_put_tags_acl_public
test_delete_tags_obj_public
test_versioning_bucket_atomic_upload_return_version_id
test_versioning_bucket_multipart_upload_return_version_id
test_put_obj_enc_conflict_c_s3
test_put_obj_enc_conflict_c_kms
test_put_obj_enc_conflict_s3_kms
test_put_obj_enc_conflict_bad_enc_kms
test_object_lock_put_obj_lock
test_object_lock_put_obj_lock_invalid_bucket
test_object_lock_put_obj_lock_with_days_and_years
test_object_lock_put_obj_lock_invalid_days
test_object_lock_put_obj_lock_invalid_years
test_object_lock_put_obj_lock_invalid_mode
test_object_lock_put_obj_lock_invalid_status
test_object_lock_suspend_versioning
test_object_lock_get_obj_lock
test_object_lock_get_obj_lock_invalid_bucket
test_object_lock_put_obj_retention_invalid_bucket
test_object_lock_put_obj_retention_invalid_mode
test_object_lock_get_obj_retention
test_object_lock_get_obj_retention_iso8601
test_object_lock_get_obj_retention_invalid_bucket
test_object_lock_put_obj_retention_versionid
test_object_lock_put_obj_retention_override_default_retention
test_object_lock_put_obj_retention_increase_period
test_object_lock_put_obj_retention_shorten_period
test_object_lock_put_obj_retention_shorten_period_bypass
test_object_lock_delete_object_with_retention
test_object_lock_delete_object_with_retention_and_marker
test_object_lock_multi_delete_object_with_retention
test_object_lock_put_legal_hold
test_object_lock_put_legal_hold_invalid_bucket
test_object_lock_put_legal_hold_invalid_status
test_object_lock_get_legal_hold
test_object_lock_get_legal_hold_invalid_bucket
test_object_lock_delete_object_with_legal_hold_on
test_object_lock_delete_object_with_legal_hold_off
test_object_lock_get_obj_metadata
test_object_lock_uploading_obj
test_object_lock_changing_mode_from_governance_with_bypass
test_object_lock_changing_mode_from_governance_without_bypass
test_object_lock_changing_mode_from_compliance
test_copy_object_ifmatch_good
test_copy_object_ifnonematch_failed
test_get_bucket_policy_status
test_get_public_acl_bucket_policy_status
test_get_authpublic_acl_bucket_policy_status
test_get_publicpolicy_acl_bucket_policy_status
test_get_nonpublicpolicy_acl_bucket_policy_status
test_put_public_block
test_block_public_put_bucket_acls
test_block_public_object_canned_acls
test_block_public_policy
test_multipart_upload_on_a_bucket_with_policy
test_put_bucket_encryption_s3
test_put_bucket_encryption_kms
test_get_bucket_encryption_s3
test_get_bucket_encryption_kms
test_delete_bucket_encryption_s3
test_delete_bucket_encryption_kms
```
