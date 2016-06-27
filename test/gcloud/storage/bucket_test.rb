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

describe Gcloud::Storage::Bucket, :mock_storage do
  let(:bucket_hash) { random_bucket_hash }
  let(:bucket_json) { bucket_hash.to_json }
  let(:bucket_gapi) { Google::Apis::StorageV1::Bucket.from_json bucket_json }
  let(:bucket) { Gcloud::Storage::Bucket.from_gapi bucket_gapi, storage.service }

  let(:bucket_name) { "new-bucket-#{Time.now.to_i}" }
  let(:bucket_url_root) { "https://www.googleapis.com/storage/v1" }
  let(:bucket_url) { "#{bucket_url_root}/b/#{bucket_name}" }
  let(:bucket_cors) { [{ "maxAgeSeconds" => 300,
                         "method" => ["*"],
                         "origin" => ["http://example.org", "https://example.org"],
                         "responseHeader" => ["X-My-Custom-Header"] }] }
  let(:bucket_location) { "US" }
  let(:bucket_logging_bucket) { "bucket-name-logging" }
  let(:bucket_logging_prefix) { "AccessLog" }
  let(:bucket_storage_class) { "STANDARD" }
  let(:bucket_versioning) { true }
  let(:bucket_website_main) { "index.html" }
  let(:bucket_website_404) { "404.html" }
  let(:bucket_complete_hash) { random_bucket_hash bucket_name, bucket_url_root,
                                                  bucket_location, bucket_storage_class, bucket_versioning,
                                                  bucket_logging_bucket, bucket_logging_prefix, bucket_website_main,
                                                  bucket_website_404, bucket_cors }
  let(:bucket_complete_json) { bucket_complete_hash.to_json }
  let(:bucket_complete_gapi) { Google::Apis::StorageV1::Bucket.from_json bucket_complete_json }
  let(:bucket_complete) { Gcloud::Storage::Bucket.from_gapi bucket_complete_gapi, storage.service }

  let(:encryption_key) { "y\x03\"\x0E\xB6\xD3\x9B\x0E\xAB*\x19\xFAv\xDEY\xBEI\xF8ftA|[z\x1A\xFBE\xDE\x97&\xBC\xC7" }
  let(:encryption_key_sha256) { "5\x04_\xDF\x1D\x8A_d\xFEK\e6p[XZz\x13s]E\xF6\xBB\x10aQH\xF6o\x14f\xF9" }
  let(:key_options) do { header: {
      "x-goog-encryption-algorithm"  => "AES256",
      "x-goog-encryption-key"        => Base64.encode64(encryption_key),
      "x-goog-encryption-key-sha256" => Base64.encode64(encryption_key_sha256)
    } }
  end

  it "knows its attributes" do
    bucket_complete.id.must_equal bucket_complete_hash["id"]
    bucket_complete.name.must_equal bucket_name
    bucket_complete.created_at.must_be_within_delta bucket_complete_hash["timeCreated"].to_datetime
    bucket_complete.api_url.must_equal bucket_url
    bucket_complete.location.must_equal bucket_location
    bucket_complete.logging_bucket.must_equal bucket_logging_bucket
    bucket_complete.logging_prefix.must_equal bucket_logging_prefix
    bucket_complete.storage_class.must_equal bucket_storage_class
    bucket_complete.versioning?.must_equal bucket_versioning
    bucket_complete.website_main.must_equal bucket_website_main
    bucket_complete.website_404.must_equal bucket_website_404
  end

  it "return frozen cors" do
    bucket_complete.cors.each do |cors|
      cors.must_be_kind_of Gcloud::Storage::Bucket::Cors::Rule
      cors.frozen?.must_equal true
    end
    bucket_complete.cors.frozen?.must_equal true
  end

  it "can delete itself" do
    mock = Minitest::Mock.new
    mock.expect :delete_bucket, nil, [bucket.name]

    bucket.service.mocked_service = mock

    bucket.delete

    mock.verify
  end

  it "creates a file" do
    new_file_name = random_file_path

    Tempfile.open ["gcloud-ruby", ".txt"] do |tmpfile|
      tmpfile.write "Hello world"
      tmpfile.rewind

      mock = Minitest::Mock.new
      mock.expect :insert_object, create_file_gapi(bucket.name, new_file_name),
        [bucket.name, empty_file_gapi, name: new_file_name, predefined_acl: nil, upload_source: tmpfile, content_encoding: nil, content_type: "text/plain", options: {}]

      bucket.service.mocked_service = mock

      bucket.create_file tmpfile, new_file_name

      mock.verify
    end
  end

  it "creates a file with upload_file alias" do
    new_file_name = random_file_path

    Tempfile.open ["gcloud-ruby", ".txt"] do |tmpfile|
      tmpfile.write "Hello world"
      tmpfile.rewind

      mock = Minitest::Mock.new
      mock.expect :insert_object, create_file_gapi(bucket.name, new_file_name),
        [bucket.name, empty_file_gapi, name: new_file_name, predefined_acl: nil, upload_source: tmpfile, content_encoding: nil, content_type: "text/plain", options: {}]

      bucket.service.mocked_service = mock

      bucket.upload_file tmpfile, new_file_name

      mock.verify
    end
  end

  it "creates a file with new_file alias" do
    new_file_name = random_file_path

    Tempfile.open ["gcloud-ruby", ".txt"] do |tmpfile|
      tmpfile.write "Hello world"
      tmpfile.rewind

      mock = Minitest::Mock.new
      mock.expect :insert_object, create_file_gapi(bucket.name, new_file_name),
        [bucket.name, empty_file_gapi, name: new_file_name, predefined_acl: nil, upload_source: tmpfile, content_encoding: nil, content_type: "text/plain", options: {}]

      bucket.service.mocked_service = mock

      bucket.new_file tmpfile, new_file_name

      mock.verify
    end
  end

  it "creates a file with predefined acl" do
    new_file_name = random_file_path

    Tempfile.open ["gcloud-ruby", ".txt"] do |tmpfile|
      tmpfile.write "Hello world"
      tmpfile.rewind

      mock = Minitest::Mock.new
      mock.expect :insert_object, create_file_gapi(bucket.name, new_file_name),
        [bucket.name, empty_file_gapi, name: new_file_name, predefined_acl: "private", upload_source: tmpfile, content_encoding: nil, content_type: "text/plain", options: {}]

      bucket.service.mocked_service = mock

      bucket.create_file tmpfile, new_file_name, acl: "private"

      mock.verify
    end
  end

  it "creates a file with predefined acl alias" do
    new_file_name = random_file_path

    Tempfile.open ["gcloud-ruby", ".txt"] do |tmpfile|
      tmpfile.write "Hello world"
      tmpfile.rewind

      mock = Minitest::Mock.new
      mock.expect :insert_object, create_file_gapi(bucket.name, new_file_name),
        [bucket.name, empty_file_gapi, name: new_file_name, predefined_acl: "publicRead", upload_source: tmpfile, content_encoding: nil, content_type: "text/plain", options: {}]

      bucket.service.mocked_service = mock

      bucket.create_file tmpfile, new_file_name, acl: :public

      mock.verify
    end
  end

  it "creates a file with md5" do
    new_file_name = random_file_path

    Tempfile.open ["gcloud-ruby", ".txt"] do |tmpfile|
      tmpfile.write "Hello world"
      tmpfile.rewind

      mock = Minitest::Mock.new
      mock.expect :insert_object, create_file_gapi(bucket.name, new_file_name),
        [bucket.name, empty_file_gapi(md5: "HXB937GQDFxDFqUGi//weQ=="), name: new_file_name, predefined_acl: nil, upload_source: tmpfile, content_encoding: nil, content_type: "text/plain", options: {}]

      bucket.service.mocked_service = mock

      bucket.create_file tmpfile, new_file_name, md5: "HXB937GQDFxDFqUGi//weQ=="

      mock.verify
    end
  end

  it "creates a file with crc32c" do
    new_file_name = random_file_path

    Tempfile.open ["gcloud-ruby", ".txt"] do |tmpfile|
      tmpfile.write "Hello world"
      tmpfile.rewind

      mock = Minitest::Mock.new
      mock.expect :insert_object, create_file_gapi(bucket.name, new_file_name),
        [bucket.name, empty_file_gapi(crc32c: "Lm1F3g=="), name: new_file_name, predefined_acl: nil, upload_source: tmpfile, content_encoding: nil, content_type: "text/plain", options: {}]

      bucket.service.mocked_service = mock

      bucket.create_file tmpfile, new_file_name, crc32c: "Lm1F3g=="

      mock.verify
    end
  end

  it "creates a file with attributes" do
    new_file_name = random_file_path

    Tempfile.open ["gcloud-ruby", ".txt"] do |tmpfile|
      tmpfile.write "Hello world"
      tmpfile.rewind

      options = {
        cache_control: "public, max-age=3600",
        content_disposition: "attachment; filename=filename.ext",
        content_encoding: "gzip",
        content_language: "en",
        content_type: "image/png"
      }

      mock = Minitest::Mock.new
      mock.expect :insert_object, create_file_gapi(bucket.name, new_file_name),
        [bucket.name, empty_file_gapi(options), name: new_file_name, predefined_acl: nil, upload_source: tmpfile, content_encoding: options[:content_encoding], content_type: options[:content_type], options: {}]

      bucket.service.mocked_service = mock

      bucket.create_file tmpfile, new_file_name, options

      mock.verify
    end
  end

  it "creates a file with metadata" do
    new_file_name = random_file_path

    Tempfile.open ["gcloud-ruby", ".txt"] do |tmpfile|
      tmpfile.write "Hello world"
      tmpfile.rewind

      metadata = {
        "player" => "Bob",
        score: 10
      }

      mock = Minitest::Mock.new
      mock.expect :insert_object, create_file_gapi(bucket.name, new_file_name),
        [bucket.name, empty_file_gapi(metadata: metadata), name: new_file_name, predefined_acl: nil, upload_source: tmpfile, content_encoding: nil, content_type: "text/plain", options: {}]

      bucket.service.mocked_service = mock

      bucket.create_file tmpfile, new_file_name, metadata: metadata

      mock.verify
    end
  end

  it "creates a file with customer-supplied encryption key" do
    new_file_name = random_file_path

    Tempfile.open ["gcloud-ruby", ".txt"] do |tmpfile|
      tmpfile.write "Hello world"
      tmpfile.rewind

      mock = Minitest::Mock.new
      mock.expect :insert_object, create_file_gapi(bucket.name, new_file_name),
        [bucket.name, empty_file_gapi, name: new_file_name, predefined_acl: nil, upload_source: tmpfile, content_encoding: nil, content_type: "text/plain", options: key_options]

      bucket.service.mocked_service = mock

      bucket.create_file tmpfile, new_file_name, encryption_key: encryption_key

      mock.verify
    end
  end

  it "creates a file with customer-supplied encryption key and sha" do
    new_file_name = random_file_path

    Tempfile.open ["gcloud-ruby", ".txt"] do |tmpfile|
      tmpfile.write "Hello world"
      tmpfile.rewind

      mock = Minitest::Mock.new
      mock.expect :insert_object, create_file_gapi(bucket.name, new_file_name),
        [bucket.name, empty_file_gapi, name: new_file_name, predefined_acl: nil, upload_source: tmpfile, content_encoding: nil, content_type: "text/plain", options: key_options]

      bucket.service.mocked_service = mock

      bucket.create_file tmpfile, new_file_name, encryption_key: encryption_key, encryption_key_sha256: encryption_key_sha256

      mock.verify
    end
  end

  it "raises when given a file that does not exist" do
    bad_file_path = "/this/file/does/not/exist.ext"

    refute ::File.file?(bad_file_path)

    err = expect {
      bucket.create_file bad_file_path
    }.must_raise ArgumentError
    err.message.must_match bad_file_path
  end

  it "lists files" do
    num_files = 3

    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(num_files),
      [bucket.name, delimiter: nil, max_results: nil, page_token: nil, prefix: nil, versions: nil]

    bucket.service.mocked_service = mock

    files = bucket.files

    mock.verify

    files.size.must_equal num_files
  end

  it "lists files with find_files alias" do
    num_files = 3

    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(num_files),
      [bucket.name, delimiter: nil, max_results: nil, page_token: nil, prefix: nil, versions: nil]

    bucket.service.mocked_service = mock

    files = bucket.find_files

    mock.verify

    files.size.must_equal num_files
  end

  it "lists files with prefix set" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3, nil, ["/prefix/path1/", "/prefix/path2/"]),
      [bucket.name, delimiter: nil, max_results: nil, page_token: nil, prefix: "/prefix/", versions: nil]

    bucket.service.mocked_service = mock

    files = bucket.files prefix: "/prefix/"

    mock.verify

    files.count.must_equal 3
    files.prefixes.wont_be :empty?
    files.prefixes.must_include "/prefix/path1/"
    files.prefixes.must_include "/prefix/path2/"
  end

  it "lists files with delimiter set" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3, nil, ["/prefix/path1/", "/prefix/path2/"]),
      [bucket.name, delimiter: "/", max_results: nil, page_token: nil, prefix: nil, versions: nil]

    bucket.service.mocked_service = mock

    files = bucket.files delimiter: "/"

    mock.verify

    files.count.must_equal 3
    files.prefixes.wont_be :empty?
    files.prefixes.must_include "/prefix/path1/"
    files.prefixes.must_include "/prefix/path2/"
  end

  it "lists files with max set" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3, "next_page_token"),
      [bucket.name, delimiter: nil, max_results: 3, page_token: nil, prefix: nil, versions: nil]

    bucket.service.mocked_service = mock

    files = bucket.files max: 3

    mock.verify

    files.count.must_equal 3
    files.token.wont_be :nil?
    files.token.must_equal "next_page_token"
  end

  it "lists files with versions set" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3),
      [bucket.name, delimiter: nil, max_results: nil, page_token: nil, prefix: nil, versions: true]

    bucket.service.mocked_service = mock

    files = bucket.files versions: true

    mock.verify

    files.count.must_equal 3
  end

  it "paginates files" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3, "next_page_token"),
      [bucket.name, delimiter: nil, max_results: nil, page_token: nil, prefix: nil, versions: nil]
    mock.expect :list_objects, list_files_gapi(2),
      [bucket.name, delimiter: nil, max_results: nil, page_token: "next_page_token", prefix: nil, versions: nil]

    bucket.service.mocked_service = mock

    first_files = bucket.files
    second_files = bucket.files token: first_files.token

    mock.verify

    first_files.count.must_equal 3
    first_files.token.wont_be :nil?
    first_files.token.must_equal "next_page_token"

    second_files.count.must_equal 2
    second_files.token.must_be :nil?
  end

  it "paginates files with next? and next" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3, "next_page_token"),
      [bucket.name, delimiter: nil, max_results: nil, page_token: nil, prefix: nil, versions: nil]
    mock.expect :list_objects, list_files_gapi(2),
      [bucket.name, delimiter: nil, max_results: nil, page_token: "next_page_token", prefix: nil, versions: nil]

    bucket.service.mocked_service = mock

    first_files = bucket.files
    second_files = first_files.next

    mock.verify

    first_files.count.must_equal 3
    first_files.next?.must_equal true

    second_files.count.must_equal 2
    second_files.next?.must_equal false
  end

  it "paginates files with next? and next and prefix set" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3, "next_page_token"),
      [bucket.name, delimiter: nil, max_results: nil, page_token: nil, prefix: "/prefix/", versions: nil]
    mock.expect :list_objects, list_files_gapi(2),
      [bucket.name, delimiter: nil, max_results: nil, page_token: "next_page_token", prefix: "/prefix/", versions: nil]

    bucket.service.mocked_service = mock

    first_files = bucket.files prefix: "/prefix/"
    second_files = first_files.next

    mock.verify

    first_files.count.must_equal 3
    first_files.next?.must_equal true

    second_files.count.must_equal 2
    second_files.next?.must_equal false
  end

  it "paginates files with next? and next and delimiter set" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3, "next_page_token"),
      [bucket.name, delimiter: "/", max_results: nil, page_token: nil, prefix: nil, versions: nil]
    mock.expect :list_objects, list_files_gapi(2),
      [bucket.name, delimiter: "/", max_results: nil, page_token: "next_page_token", prefix: nil, versions: nil]

    bucket.service.mocked_service = mock

    first_files = bucket.files delimiter: "/"
    second_files = first_files.next

    mock.verify

    first_files.count.must_equal 3
    first_files.next?.must_equal true

    second_files.count.must_equal 2
    second_files.next?.must_equal false
  end

  it "paginates files with next? and next and max set" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3, "next_page_token"),
      [bucket.name, delimiter: nil, max_results: 3, page_token: nil, prefix: nil, versions: nil]
    mock.expect :list_objects, list_files_gapi(2),
      [bucket.name, delimiter: nil, max_results: 3, page_token: "next_page_token", prefix: nil, versions: nil]

    bucket.service.mocked_service = mock

    first_files = bucket.files max: 3
    second_files = first_files.next

    mock.verify

    first_files.count.must_equal 3
    first_files.next?.must_equal true

    second_files.count.must_equal 2
    second_files.next?.must_equal false
  end

  it "paginates files with next? and next and versions set" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3, "next_page_token"),
      [bucket.name, delimiter: nil, max_results: nil, page_token: nil, prefix: nil, versions: true]
    mock.expect :list_objects, list_files_gapi(2),
      [bucket.name, delimiter: nil, max_results: nil, page_token: "next_page_token", prefix: nil, versions: true]

    bucket.service.mocked_service = mock

    first_files = bucket.files versions: true
    second_files = first_files.next

    mock.verify

    first_files.count.must_equal 3
    first_files.next?.must_equal true

    second_files.count.must_equal 2
    second_files.next?.must_equal false
  end

  it "paginates files with all" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3, "next_page_token"),
      [bucket.name, delimiter: nil, max_results: nil, page_token: nil, prefix: nil, versions: nil]
    mock.expect :list_objects, list_files_gapi(2),
      [bucket.name, delimiter: nil, max_results: nil, page_token: "next_page_token", prefix: nil, versions: nil]

    bucket.service.mocked_service = mock

    files = bucket.files.all.to_a

    mock.verify

    files.count.must_equal 5
  end

  it "paginates files with all and prefix set" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3, "next_page_token"),
      [bucket.name, delimiter: nil, max_results: nil, page_token: nil, prefix: "/prefix/", versions: nil]
    mock.expect :list_objects, list_files_gapi(2),
      [bucket.name, delimiter: nil, max_results: nil, page_token: "next_page_token", prefix: "/prefix/", versions: nil]

    bucket.service.mocked_service = mock

    files = bucket.files(prefix: "/prefix/").all.to_a

    mock.verify

    files.count.must_equal 5
  end

  it "paginates files with all and delimiter set" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3, "next_page_token"),
      [bucket.name, delimiter: "/", max_results: nil, page_token: nil, prefix: nil, versions: nil]
    mock.expect :list_objects, list_files_gapi(2),
      [bucket.name, delimiter: "/", max_results: nil, page_token: "next_page_token", prefix: nil, versions: nil]

    bucket.service.mocked_service = mock

    files = bucket.files(delimiter: "/").all.to_a

    mock.verify

    files.count.must_equal 5
  end

  it "paginates files with all and max set" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3, "next_page_token"),
      [bucket.name, delimiter: nil, max_results: 3, page_token: nil, prefix: nil, versions: nil]
    mock.expect :list_objects, list_files_gapi(2),
      [bucket.name, delimiter: nil, max_results: 3, page_token: "next_page_token", prefix: nil, versions: nil]

    bucket.service.mocked_service = mock

    files = bucket.files(max: 3).all.to_a

    mock.verify

    files.count.must_equal 5
  end

  it "paginates files with all and versions set" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3, "next_page_token"),
      [bucket.name, delimiter: nil, max_results: nil, page_token: nil, prefix: nil, versions: true]
    mock.expect :list_objects, list_files_gapi(2),
      [bucket.name, delimiter: nil, max_results: nil, page_token: "next_page_token", prefix: nil, versions: true]

    bucket.service.mocked_service = mock

    files = bucket.files(versions: true).all.to_a

    mock.verify

    files.count.must_equal 5
  end

  it "paginates files with all using Enumerator" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3, "next_page_token"),
      [bucket.name, delimiter: nil, max_results: nil, page_token: nil, prefix: nil, versions: nil]
    mock.expect :list_objects, list_files_gapi(3, "second_page_token"),
      [bucket.name, delimiter: nil, max_results: nil, page_token: "next_page_token", prefix: nil, versions: nil]

    bucket.service.mocked_service = mock

    files = bucket.files.all.take(5)

    mock.verify

    files.count.must_equal 5
  end

  it "paginates files with all and request_limit set" do
    mock = Minitest::Mock.new
    mock.expect :list_objects, list_files_gapi(3, "next_page_token"),
      [bucket.name, delimiter: nil, max_results: nil, page_token: nil, prefix: nil, versions: nil]
    mock.expect :list_objects, list_files_gapi(3, "second_page_token"),
      [bucket.name, delimiter: nil, max_results: nil, page_token: "next_page_token", prefix: nil, versions: nil]

    bucket.service.mocked_service = mock

    files = bucket.files.all(request_limit: 1).to_a

    mock.verify

    files.count.must_equal 6
  end

  it "finds a file" do
    file_name = "file.ext"

    mock = Minitest::Mock.new
    mock.expect :get_object, find_file_gapi(bucket.name, file_name),
      [bucket.name, file_name, generation: nil, options: {}]

    bucket.service.mocked_service = mock

    file = bucket.file file_name

    mock.verify

    file.name.must_equal file_name
  end

  it "finds a file with find_file alias" do
    file_name = "file.ext"

    mock = Minitest::Mock.new
    mock.expect :get_object, find_file_gapi(bucket.name, file_name),
      [bucket.name, file_name, generation: nil, options: {}]

    bucket.service.mocked_service = mock

    file = bucket.find_file file_name

    mock.verify

    file.name.must_equal file_name
  end

  it "finds a file with generation" do
    file_name = "file.ext"
    generation = 123

    mock = Minitest::Mock.new
    mock.expect :get_object, find_file_gapi(bucket.name, file_name),
      [bucket.name, file_name, generation: generation, options: {}]

    bucket.service.mocked_service = mock

    file = bucket.file file_name, generation: generation

    mock.verify

    file.name.must_equal file_name
  end

  it "finds a file with customer-supplied encryption key" do
    file_name = "file.ext"

    mock = Minitest::Mock.new
    mock.expect :get_object, find_file_gapi(bucket.name, file_name),
      [bucket.name, file_name, generation: nil, options: key_options]

    bucket.service.mocked_service = mock

    file = bucket.file file_name, encryption_key: encryption_key

    mock.verify

    file.name.must_equal file_name
  end

  it "finds a file with customer-supplied encryption key and sha" do
    file_name = "file.ext"

    mock = Minitest::Mock.new
    mock.expect :get_object, find_file_gapi(bucket.name, file_name),
      [bucket.name, file_name, generation: nil, options: key_options]

    bucket.service.mocked_service = mock

    file = bucket.file file_name, encryption_key: encryption_key, encryption_key_sha256: encryption_key_sha256

    mock.verify

    file.name.must_equal file_name
  end

  it "can reload itself" do
    bucket_name = "found-bucket"
    new_url_root = "https://www.googleapis.com/storage/v2"

    mock = Minitest::Mock.new
    mock.expect :get_bucket, Google::Apis::StorageV1::Bucket.from_json(random_bucket_hash(bucket_name).to_json),
      [bucket_name]
    mock.expect :get_bucket, Google::Apis::StorageV1::Bucket.from_json(random_bucket_hash(bucket_name, new_url_root).to_json),
      [bucket_name]

    bucket.service.mocked_service = mock

    bucket = storage.bucket bucket_name
    bucket.api_url.must_equal "https://www.googleapis.com/storage/v1/b/#{bucket_name}"

    bucket.reload!

    bucket.api_url.must_equal "#{new_url_root}/b/#{bucket_name}"
    mock.verify
  end

  def create_file_gapi bucket=nil, name = nil
    Google::Apis::StorageV1::Object.from_json random_file_hash(bucket, name).to_json
  end

  def empty_file_gapi cache_control: nil, content_disposition: nil,
                      content_encoding: nil, content_language: nil,
                      content_type: nil, crc32c: nil, md5: nil, metadata: nil
    Google::Apis::StorageV1::Object.new(
      cache_control: cache_control, content_type: content_type,
      content_disposition: content_disposition, md5_hash: md5,
      content_encoding: content_encoding, crc32c: crc32c,
      content_language: content_language, metadata: metadata)
  end

  def find_file_gapi bucket=nil, name = nil
    Google::Apis::StorageV1::Object.from_json random_file_hash(bucket, name).to_json
  end

  def list_files_gapi count = 2, token = nil, prefixes = nil
    files = count.times.map { Google::Apis::StorageV1::Object.from_json random_file_hash.to_json }
    Google::Apis::StorageV1::Objects.new kind: "storage#objects", items: files, next_page_token: token, prefixes: prefixes
  end
end
