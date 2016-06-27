# Copyright 2014 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "helper"
require "json"
require "uri"

describe Gcloud::Storage::Bucket, :update, :mock_storage do
  let(:bucket_name) { "new-bucket-#{Time.now.to_i}" }
  let(:bucket_url_root) { "https://www.googleapis.com/storage/v1" }
  let(:bucket_url) { "#{bucket_url_root}/b/#{bucket_name}" }
  let(:bucket_location) { "US" }
  let(:bucket_storage_class) { "STANDARD" }
  let(:bucket_logging_bucket) { "bucket-name-logging" }
  let(:bucket_logging_prefix) { "AccessLog" }
  let(:bucket_website_main) { "index.html" }
  let(:bucket_website_404) { "404.html" }
  let(:bucket_cors_gapi) { Google::Apis::StorageV1::Bucket::CorsConfiguration.new(
    max_age_seconds: 300,
    origin: ["http://example.org", "https://example.org"],
    http_method: ["*"],
    response_header: ["X-My-Custom-Header"]) }
  let(:bucket_cors_hash) { JSON.parse bucket_cors_gapi.to_json }

  let(:bucket_hash) { random_bucket_hash bucket_name, bucket_url_root, bucket_location, bucket_storage_class }
  let(:bucket_gapi) { Google::Apis::StorageV1::Bucket.from_json bucket_hash.to_json }
  let(:bucket) { Gcloud::Storage::Bucket.from_gapi bucket_gapi, storage.service }

  let(:bucket_with_cors_hash) { random_bucket_hash bucket_name, bucket_url_root, bucket_location, bucket_storage_class,
                                                   nil, nil, nil, nil, nil, [bucket_cors_hash] }
  let(:bucket_with_cors_gapi) { Google::Apis::StorageV1::Bucket.from_json bucket_with_cors_hash.to_json }
  let(:bucket_with_cors) { Gcloud::Storage::Bucket.from_gapi bucket_with_cors_gapi, storage.service }

  it "updates its versioning" do
    mock = Minitest::Mock.new
    patch_bucket_gapi = Google::Apis::StorageV1::Bucket.new versioning: true
    returned_bucket_gapi = Google::Apis::StorageV1::Bucket.from_json \
      random_bucket_hash(bucket_name, bucket_url, bucket_location, bucket_storage_class, true).to_json
    mock.expect :patch_bucket, returned_bucket_gapi,
      [bucket_name, patch_bucket_gapi, predefined_acl: nil, predefined_default_object_acl: nil]

    bucket.service.mocked_service = mock

    bucket.versioning?.must_equal nil
    bucket.versioning = true
    bucket.versioning?.must_equal true

    mock.verify
  end

  it "updates its logging bucket" do
    mock = Minitest::Mock.new
    patch_logging_gapi = Google::Apis::StorageV1::Bucket::Logging.new log_bucket: bucket_logging_bucket
    patch_bucket_gapi = Google::Apis::StorageV1::Bucket.new logging: patch_logging_gapi
    returned_bucket_gapi = Google::Apis::StorageV1::Bucket.from_json \
      random_bucket_hash(bucket_name, bucket_url, bucket_location, bucket_storage_class, nil, bucket_logging_bucket).to_json
    mock.expect :patch_bucket, returned_bucket_gapi,
      [bucket_name, patch_bucket_gapi, predefined_acl: nil, predefined_default_object_acl: nil]

    bucket.service.mocked_service = mock

    bucket.logging_bucket.must_equal nil
    bucket.logging_bucket = bucket_logging_bucket
    bucket.logging_bucket.must_equal bucket_logging_bucket

    mock.verify
  end

  it "updates its logging prefix" do
    mock = Minitest::Mock.new
    patch_logging_gapi = Google::Apis::StorageV1::Bucket::Logging.new log_object_prefix: bucket_logging_prefix
    patch_bucket_gapi = Google::Apis::StorageV1::Bucket.new logging: patch_logging_gapi
    returned_bucket_gapi = Google::Apis::StorageV1::Bucket.from_json \
      random_bucket_hash(bucket_name, bucket_url, bucket_location, bucket_storage_class, nil, nil, bucket_logging_prefix).to_json
    mock.expect :patch_bucket, returned_bucket_gapi,
      [bucket_name, patch_bucket_gapi, predefined_acl: nil, predefined_default_object_acl: nil]

    bucket.service.mocked_service = mock

    bucket.logging_prefix.must_equal nil
    bucket.logging_prefix = bucket_logging_prefix
    bucket.logging_prefix.must_equal bucket_logging_prefix

    mock.verify
  end

  it "updates its logging bucket and prefix" do
    mock = Minitest::Mock.new
    patch_logging_gapi = Google::Apis::StorageV1::Bucket::Logging.new log_bucket: bucket_logging_bucket, log_object_prefix: bucket_logging_prefix
    patch_bucket_gapi = Google::Apis::StorageV1::Bucket.new logging: patch_logging_gapi
    returned_bucket_gapi = Google::Apis::StorageV1::Bucket.from_json \
      random_bucket_hash(bucket_name, bucket_url, bucket_location, bucket_storage_class, nil, bucket_logging_bucket, bucket_logging_prefix).to_json
    mock.expect :patch_bucket, returned_bucket_gapi,
      [bucket_name, patch_bucket_gapi.class, predefined_acl: nil, predefined_default_object_acl: nil]

    bucket.service.mocked_service = mock

    bucket.logging_bucket.must_equal nil
    bucket.logging_prefix.must_equal nil

    bucket.update do |b|
      b.logging_bucket = bucket_logging_bucket
      b.logging_prefix = bucket_logging_prefix
    end

    bucket.logging_bucket.must_equal bucket_logging_bucket
    bucket.logging_prefix.must_equal bucket_logging_prefix

    mock.verify
  end

  it "updates its website main page" do
    mock = Minitest::Mock.new
    patch_website_gapi = Google::Apis::StorageV1::Bucket::Website.new main_page_suffix: bucket_website_main
    patch_bucket_gapi = Google::Apis::StorageV1::Bucket.new website: patch_website_gapi
    returned_bucket_gapi = Google::Apis::StorageV1::Bucket.from_json \
      random_bucket_hash(bucket_name, bucket_url, bucket_location, bucket_storage_class, nil, nil, nil, bucket_website_main).to_json
    mock.expect :patch_bucket, returned_bucket_gapi,
      [bucket_name, patch_bucket_gapi, predefined_acl: nil, predefined_default_object_acl: nil]

    bucket.service.mocked_service = mock

    bucket.website_main.must_equal nil
    bucket.website_main = bucket_website_main
    bucket.website_main.must_equal bucket_website_main

    mock.verify
  end

  it "updates its website not found 404 page" do
    mock = Minitest::Mock.new
    patch_website_gapi = Google::Apis::StorageV1::Bucket::Website.new not_found_page: bucket_website_404
    patch_bucket_gapi = Google::Apis::StorageV1::Bucket.new website: patch_website_gapi
    returned_bucket_gapi = Google::Apis::StorageV1::Bucket.from_json \
      random_bucket_hash(bucket_name, bucket_url, bucket_location, bucket_storage_class, nil, nil, nil, nil, bucket_website_404).to_json
    mock.expect :patch_bucket, returned_bucket_gapi,
      [bucket_name, patch_bucket_gapi, predefined_acl: nil, predefined_default_object_acl: nil]

    bucket.service.mocked_service = mock

    bucket.website_404.must_equal nil
    bucket.website_404 = bucket_website_404
    bucket.website_404.must_equal bucket_website_404

    mock.verify
  end

  it "updates its website main page and not found 404 page" do
    mock = Minitest::Mock.new
    patch_website_gapi = Google::Apis::StorageV1::Bucket::Website.new main_page_suffix: bucket_website_main, not_found_page: bucket_website_404
    patch_bucket_gapi = Google::Apis::StorageV1::Bucket.new website: patch_website_gapi
    returned_bucket_gapi = Google::Apis::StorageV1::Bucket.from_json \
      random_bucket_hash(bucket_name, bucket_url, bucket_location, bucket_storage_class, nil, nil, nil, bucket_website_main, bucket_website_404).to_json
    mock.expect :patch_bucket, returned_bucket_gapi,
      [bucket_name, patch_bucket_gapi, predefined_acl: nil, predefined_default_object_acl: nil]

    bucket.service.mocked_service = mock

    bucket.website_main.must_equal nil
    bucket.website_404.must_equal nil

    bucket.update do |b|
      b.website_main = bucket_website_main
      b.website_404 = bucket_website_404
    end

    bucket.website_main.must_equal bucket_website_main
    bucket.website_404.must_equal bucket_website_404

    mock.verify
  end

  it "updates multiple attributes in a block" do
    mock = Minitest::Mock.new
    patch_logging_gapi = Google::Apis::StorageV1::Bucket::Logging.new log_bucket: bucket_logging_bucket, log_object_prefix: bucket_logging_prefix
    patch_website_gapi = Google::Apis::StorageV1::Bucket::Website.new main_page_suffix: bucket_website_main, not_found_page: bucket_website_404
    patch_bucket_gapi = Google::Apis::StorageV1::Bucket.new versioning: true, logging: patch_logging_gapi, website: patch_website_gapi
    returned_bucket_gapi = Google::Apis::StorageV1::Bucket.from_json \
      random_bucket_hash(bucket_name, bucket_url, bucket_location, bucket_storage_class, true, bucket_logging_bucket, bucket_logging_prefix, bucket_website_main, bucket_website_404).to_json
    mock.expect :patch_bucket, returned_bucket_gapi,
      [bucket_name, patch_bucket_gapi, predefined_acl: nil, predefined_default_object_acl: nil]

    bucket.service.mocked_service = mock

    bucket.versioning?.must_equal nil
    bucket.logging_bucket.must_equal nil
    bucket.logging_prefix.must_equal nil
    bucket.website_main.must_equal nil
    bucket.website_404.must_equal nil

    bucket.update do |b|
      b.versioning = true
      b.logging_prefix = bucket_logging_prefix
      b.logging_bucket = bucket_logging_bucket
      b.website_main = bucket_website_main
      b.website_404 = bucket_website_404
    end

    bucket.versioning?.must_equal true
    bucket.logging_bucket.must_equal bucket_logging_bucket
    bucket.logging_prefix.must_equal bucket_logging_prefix
    bucket.website_main.must_equal bucket_website_main
    bucket.website_404.must_equal bucket_website_404

    mock.verify
  end

  it "sets the cors rules" do
    mock = Minitest::Mock.new
    patch_bucket_gapi = Google::Apis::StorageV1::Bucket.new cors_configurations: [bucket_cors_gapi]
    returned_bucket_gapi = Google::Apis::StorageV1::Bucket.from_json \
      random_bucket_hash(bucket_name, bucket_url, bucket_location, bucket_storage_class, nil, nil, nil, nil, nil, [bucket_cors_hash]).to_json
    mock.expect :patch_bucket, returned_bucket_gapi,
      [bucket_name, patch_bucket_gapi, predefined_acl: nil, predefined_default_object_acl: nil]
    bucket.service.mocked_service = mock

    bucket.cors.must_equal []
    bucket.cors do |c|
      c.add_rule ["http://example.org", "https://example.org"],
                 "*",
                 headers: ["X-My-Custom-Header"],
                 max_age: 300
    end

    mock.verify
  end

  it "can't update cors outside of a block" do
    err = expect {
      bucket_with_cors.cors.first.max_age = 600
    }.must_raise RuntimeError
    err.message.must_match "can't modify frozen"
  end

  it "can update cors inside of a block" do
    mock = Minitest::Mock.new
    patch_bucket_gapi = Google::Apis::StorageV1::Bucket.new cors_configurations: [
      Google::Apis::StorageV1::Bucket::CorsConfiguration.new(
        max_age_seconds: 600, http_method: ["PUT"], origin: ["http://example.org", "https://example.org", "https://example.com"], response_header: ["X-My-Custom-Header", "X-Another-Custom-Header"]
      ),
      Google::Apis::StorageV1::Bucket::CorsConfiguration.new(
        max_age_seconds: 1800, http_method: [], origin: [], response_header: []
      )
    ]
    returned_bucket_gapi = Google::Apis::StorageV1::Bucket.from_json \
      random_bucket_hash(bucket_name, bucket_url, bucket_location, bucket_storage_class, nil, nil, nil, nil, nil, [bucket_cors_hash]).to_json
    mock.expect :patch_bucket, returned_bucket_gapi,
      [bucket_name, patch_bucket_gapi, predefined_acl: nil, predefined_default_object_acl: nil]
    bucket_with_cors.service.mocked_service = mock

    bucket_with_cors.cors.class.must_equal Gcloud::Storage::Bucket::Cors
    bucket_with_cors.update do |b|
      b.cors.first.class.must_equal Gcloud::Storage::Bucket::Cors::Rule
      b.cors.first.max_age = 600
      b.cors.first.origin << "https://example.com"
      b.cors.first.methods = ["PUT"]
      b.cors.first.headers << "X-Another-Custom-Header"
      # Add a second rule
      b.cors << Gcloud::Storage::Bucket::Cors::Rule.new(nil, nil)
    end

    mock.verify
  end

  it "adds CORS rules in a nested block in update" do
    mock = Minitest::Mock.new
    patch_bucket_gapi = Google::Apis::StorageV1::Bucket.new cors_configurations: [
      Google::Apis::StorageV1::Bucket::CorsConfiguration.new(
        max_age_seconds: 1800, http_method: ["GET"], origin: ["http://example.org"], response_header: []
      ),
      Google::Apis::StorageV1::Bucket::CorsConfiguration.new(
        max_age_seconds: 300, http_method: ["PUT", "DELETE"], origin: ["http://example.org", "https://example.org"], response_header: ["X-My-Custom-Header"]
      ),
      Google::Apis::StorageV1::Bucket::CorsConfiguration.new(
        max_age_seconds: 1800, http_method: ["*"], origin: ["http://example.com"], response_header: ["X-Another-Custom-Header"]
      )
    ]
    returned_bucket_gapi = Google::Apis::StorageV1::Bucket.from_json \
      random_bucket_hash(bucket_name, bucket_url, bucket_location, bucket_storage_class, nil, nil, nil, nil, nil, [bucket_cors_hash]).to_json
    mock.expect :patch_bucket, returned_bucket_gapi,
      [bucket_name, patch_bucket_gapi, predefined_acl: nil, predefined_default_object_acl: nil]
    bucket_with_cors.service.mocked_service = mock

    bucket_with_cors.update do |b|
      b.cors.delete_if { |c| c.max_age = 300 }
      b.cors do |c|
        c.add_rule "http://example.org", "GET"
        c.add_rule ["http://example.org", "https://example.org"],
                   ["PUT", "DELETE"],
                   headers: ["X-My-Custom-Header"],
                   max_age: 300
        c.add_rule "http://example.com",
                   "*",
                   headers: "X-Another-Custom-Header"
      end
    end

    mock.verify
  end

  it "adds CORS rules in a block to cors" do
    mock = Minitest::Mock.new
    patch_bucket_gapi = Google::Apis::StorageV1::Bucket.new cors_configurations: [
      Google::Apis::StorageV1::Bucket::CorsConfiguration.new(
        max_age_seconds: 1800, http_method: ["GET"], origin: ["http://example.org"], response_header: []
      ),
      Google::Apis::StorageV1::Bucket::CorsConfiguration.new(
        max_age_seconds: 300, http_method: ["PUT", "DELETE"], origin: ["http://example.org", "https://example.org"], response_header: ["X-My-Custom-Header"]
      ),
      Google::Apis::StorageV1::Bucket::CorsConfiguration.new(
        max_age_seconds: 1800, http_method: ["*"], origin: ["http://example.com"], response_header: ["X-Another-Custom-Header"]
      )
    ]
    returned_bucket_gapi = Google::Apis::StorageV1::Bucket.from_json \
      random_bucket_hash(bucket_name, bucket_url, bucket_location, bucket_storage_class, nil, nil, nil, nil, nil, [bucket_cors_hash]).to_json
    mock.expect :patch_bucket, returned_bucket_gapi,
      [bucket_name, patch_bucket_gapi, predefined_acl: nil, predefined_default_object_acl: nil]
    bucket.service.mocked_service = mock

    returned_cors = bucket.cors do |c|
      c.add_rule "http://example.org", "GET"
      c.add_rule ["http://example.org", "https://example.org"],
                 ["PUT", "DELETE"],
                 headers: ["X-My-Custom-Header"],
                 max_age: 300
      c.add_rule "http://example.com",
                 "*",
                 headers: "X-Another-Custom-Header"
    end
    returned_cors.frozen?.must_equal true
    returned_cors.first.frozen?.must_equal true

    mock.verify
  end

  it "updates CORS rules in a block to cors" do
    mock = Minitest::Mock.new
    patch_bucket_gapi = Google::Apis::StorageV1::Bucket.new cors_configurations: [
      Google::Apis::StorageV1::Bucket::CorsConfiguration.new(
        max_age_seconds: 1800, http_method: ["GET"], origin: ["http://example.net"], response_header: []
      )
    ]
    returned_bucket_gapi = Google::Apis::StorageV1::Bucket.from_json \
      random_bucket_hash(bucket_name, bucket_url, bucket_location, bucket_storage_class, nil, nil, nil, nil, nil, [bucket_cors_hash]).to_json
    mock.expect :patch_bucket, returned_bucket_gapi,
      [bucket_name, patch_bucket_gapi, predefined_acl: nil, predefined_default_object_acl: nil]
    bucket.service.mocked_service = mock

    bucket_with_cors.cors.size.must_equal 1
    bucket_with_cors.cors[0].origin.must_equal ["http://example.org", "https://example.org"]
    bucket_with_cors.cors do |c|
      c.add_rule "http://example.net", "GET"
      c.add_rule "http://example.net", "POST"
      # Remove the last CORS rule from the array
      c.pop
      # Remove all existing rules with the https protocol
      c.delete_if { |r| r.origin.include? "http://example.org" }
    end

    mock.verify
  end
end
