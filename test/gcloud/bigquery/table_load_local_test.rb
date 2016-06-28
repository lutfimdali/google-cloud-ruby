# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a load of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "helper"

describe Gcloud::Bigquery::Table, :load, :local, :mock_bigquery do
  let(:dataset) { "dataset" }
  let(:table_id) { "table_id" }
  let(:table_name) { "Target Table" }
  let(:description) { "This is the target table" }
  let(:table_hash) { random_table_gapi dataset,
                                       table_id,
                                       table_name,
                                       description }
  let(:table) { Gcloud::Bigquery::Table.from_gapi table_hash,
                                                  bigquery.service }

  it "can upload a csv file" do
    mock_connection.post "/upload/bigquery/v2/projects/#{project}/jobs" do |env|
      json = JSON.parse(get_json_from_multipart_body(env))
      json["configuration"]["load"]["sourceUris"].must_equal []
      json["configuration"]["load"]["destinationTable"]["projectId"].must_equal table.project_id
      json["configuration"]["load"]["destinationTable"]["datasetId"].must_equal table.dataset_id
      json["configuration"]["load"]["destinationTable"]["tableId"].must_equal table.table_id
      json["configuration"]["load"].wont_include "create_disposition"
      json["configuration"]["load"].wont_include "write_disposition"
      json["configuration"]["load"]["sourceFormat"].must_equal "CSV"
      json["configuration"]["load"].wont_include "allowJaggedRows"
      json["configuration"]["load"].wont_include "allowQuotedNewlines"
      json["configuration"]["load"].wont_include "encoding"
      json["configuration"]["load"].wont_include "fieldDelimiter"
      json["configuration"]["load"].wont_include "ignoreUnknownValues"
      json["configuration"]["load"].wont_include "maxBadRecords"
      json["configuration"]["load"].wont_include "quote"
      json["configuration"]["load"].wont_include "schema"
      json["configuration"]["load"].wont_include "skipLeadingRows"
      json["configuration"].wont_include "dryRun"
      [200, {"Content-Type"=>"application/json", Location: "/resumable/upload/bigquery/v2/projects/#{project}/jobs"},
       load_job_json(table, "some/file/path.csv")]
    end

    temp_csv do |file|
      job = table.load file, format: :csv
      job.must_be_kind_of Gcloud::Bigquery::LoadJob
    end
  end

  it "can upload a csv file with CSV options" do
    mock_connection.post "/upload/bigquery/v2/projects/#{project}/jobs" do |env|
      json = JSON.parse(get_json_from_multipart_body(env))
      json["configuration"]["load"]["sourceUris"].must_equal []
      json["configuration"]["load"]["destinationTable"]["projectId"].must_equal table.project_id
      json["configuration"]["load"]["destinationTable"]["datasetId"].must_equal table.dataset_id
      json["configuration"]["load"]["destinationTable"]["tableId"].must_equal table.table_id
      json["configuration"]["load"].wont_include "create_disposition"
      json["configuration"]["load"].wont_include "write_disposition"
      json["configuration"]["load"]["sourceFormat"].must_equal "CSV"
      json["configuration"]["load"]["allowJaggedRows"].must_equal true
      json["configuration"]["load"]["allowQuotedNewlines"].must_equal true
      json["configuration"]["load"]["encoding"].must_equal "ISO-8859-1"
      json["configuration"]["load"]["fieldDelimiter"].must_equal "\t"
      json["configuration"]["load"]["ignoreUnknownValues"].must_equal true
      json["configuration"]["load"]["maxBadRecords"].must_equal 42
      json["configuration"]["load"]["quote"].must_equal "'"
      json["configuration"]["load"].wont_include "schema"
      json["configuration"]["load"]["skipLeadingRows"].must_equal 1
      json["configuration"].wont_include "dryRun"
      [200, {"Content-Type"=>"application/json", Location: "/resumable/upload/bigquery/v2/projects/#{project}/jobs"},
       load_job_json(table, "some/file/path.csv")]
    end

    temp_csv do |file|
      job = table.load file, format: :csv, jagged_rows: true, quoted_newlines: true,
        encoding: "ISO-8859-1", delimiter: "\t", ignore_unknown: true, max_bad_records: 42,
        quote: "'", skip_leading: 1
      job.must_be_kind_of Gcloud::Bigquery::LoadJob
    end
  end

  it "can upload a json file" do
    mock_connection.post "/upload/bigquery/v2/projects/#{project}/jobs" do |env|
      json = JSON.parse(get_json_from_multipart_body(env))
      json["configuration"]["load"]["sourceUris"].must_equal []
      json["configuration"]["load"]["destinationTable"]["projectId"].must_equal table.project_id
      json["configuration"]["load"]["destinationTable"]["datasetId"].must_equal table.dataset_id
      json["configuration"]["load"]["destinationTable"]["tableId"].must_equal table.table_id
      json["configuration"]["load"].wont_include "create_disposition"
      json["configuration"]["load"].wont_include "write_disposition"
      json["configuration"]["load"]["sourceFormat"].must_equal "NEWLINE_DELIMITED_JSON"
      json["configuration"]["load"].wont_include "allowJaggedRows"
      json["configuration"]["load"].wont_include "allowQuotedNewlines"
      json["configuration"]["load"].wont_include "encoding"
      json["configuration"]["load"].wont_include "fieldDelimiter"
      json["configuration"]["load"].wont_include "ignoreUnknownValues"
      json["configuration"]["load"].wont_include "maxBadRecords"
      json["configuration"]["load"].wont_include "quote"
      json["configuration"]["load"].wont_include "schema"
      json["configuration"]["load"].wont_include "skipLeadingRows"
      json["configuration"].wont_include "dryRun"
      [200, {"Content-Type"=>"application/json", Location: "/resumable/upload/bigquery/v2/projects/#{project}/jobs"},
       load_job_json(table, "some/file/path.json")]
    end

    temp_json do |file|
      job = table.load file, format: "JSON"
      job.must_be_kind_of Gcloud::Bigquery::LoadJob
    end
  end

  it "can upload a json file and derive the format" do
    mock_connection.post "/upload/bigquery/v2/projects/#{project}/jobs" do |env|
      json = JSON.parse(get_json_from_multipart_body(env))
      json["configuration"]["load"]["sourceUris"].must_equal []
      json["configuration"]["load"]["destinationTable"]["projectId"].must_equal table.project_id
      json["configuration"]["load"]["destinationTable"]["datasetId"].must_equal table.dataset_id
      json["configuration"]["load"]["destinationTable"]["tableId"].must_equal table.table_id
      json["configuration"]["load"].wont_include "create_disposition"
      json["configuration"]["load"].wont_include "write_disposition"
      json["configuration"]["load"]["sourceFormat"].must_equal "NEWLINE_DELIMITED_JSON"
      json["configuration"]["load"].wont_include "allowJaggedRows"
      json["configuration"]["load"].wont_include "allowQuotedNewlines"
      json["configuration"]["load"].wont_include "encoding"
      json["configuration"]["load"].wont_include "fieldDelimiter"
      json["configuration"]["load"].wont_include "ignoreUnknownValues"
      json["configuration"]["load"].wont_include "maxBadRecords"
      json["configuration"]["load"].wont_include "quote"
      json["configuration"]["load"].wont_include "schema"
      json["configuration"]["load"].wont_include "skipLeadingRows"
      json["configuration"].wont_include "dryRun"
      [200, {"Content-Type"=>"application/json", Location: "/resumable/upload/bigquery/v2/projects/#{project}/jobs"},
       load_job_json(table, "some/file/path.json")]
    end

    local_json = "acceptance/data/kitten-test-data.json"
    job = table.load local_json
    job.must_be_kind_of Gcloud::Bigquery::LoadJob
  end

  it "uses the default chunk_size" do
    # Mock the upload
    Gcloud::Upload.stub :default_chunk_size, 256*1024 do
      upload_request = false
      mock_connection.post "/upload/bigquery/v2/projects/#{project}/jobs" do |env|
        if upload_request
          # The content length is sent on the second request
          env.request_headers["Content-length"].to_i.must_equal Gcloud::Upload.default_chunk_size
        end
        upload_request = true
        [200, {"Content-Type"=>"application/json", Location: "/resumable/upload/bigquery/v2/projects/#{project}/jobs"},
         load_job_json(table, "some/file/path.json")]
      end

      temp_resumable_csv do |file|
        assert ::File.size?(file).to_i > Gcloud::Upload.resumable_threshold, "file is not resumable"
        job = table.load file, format: :csv
        job.must_be_kind_of Gcloud::Bigquery::LoadJob
      end
    end
  end

  it "uses a valid chunk_size" do
    # Mock the upload
    valid_chunk_size = 2 * 256 * 1024 # 256KB
    Gcloud::Upload.stub :default_chunk_size, 256*1024 do
      upload_request = false
      mock_connection.post "/upload/bigquery/v2/projects/#{project}/jobs" do |env|
        if upload_request
          # The content length is sent on the second request
          env.request_headers["Content-length"].to_i.must_equal valid_chunk_size
        end
        upload_request = true
        [200, {"Content-Type"=>"application/json", Location: "/resumable/upload/bigquery/v2/projects/#{project}/jobs"},
         load_job_json(table, "some/file/path.json")]
      end

      temp_resumable_csv do |file|
        assert ::File.size?(file).to_i > Gcloud::Upload.resumable_threshold, "file is not resumable"
        job = table.load file, format: :csv, chunk_size: valid_chunk_size
        job.must_be_kind_of Gcloud::Bigquery::LoadJob
      end
    end
  end

  it "does not error on an invalid chunk_size" do
    # Mock the upload
    valid_chunk_size = 2 * 256 * 1024 # 256KB
    invalid_chunk_size = valid_chunk_size + 1
    Gcloud::Upload.stub :default_chunk_size, 256*1024 do
      upload_request = false
      mock_connection.post "/upload/bigquery/v2/projects/#{project}/jobs" do |env|
        if upload_request
          # The content length is sent on the second request
          env.request_headers["Content-length"].to_i.must_equal valid_chunk_size
        end
        upload_request = true
        [200, {"Content-Type"=>"application/json", Location: "/resumable/upload/bigquery/v2/projects/#{project}/jobs"},
         load_job_json(table, "some/file/path.json")]
      end

      temp_resumable_csv do |file|
        assert ::File.size?(file).to_i > Gcloud::Upload.resumable_threshold, "file is not resumable"
        job = table.load file, format: :csv, chunk_size: invalid_chunk_size
        job.must_be_kind_of Gcloud::Bigquery::LoadJob
      end
    end
  end

  def load_job_json table, load_url
    hash = random_job_gapi
    hash["configuration"]["load"] = {
      source_uris: [load_url],
      destinationTable: {
        projectId: table.project_id,
        datasetId: table.dataset_id,
        tableId: table.table_id
      },
    }
    hash.to_json
  end

  def temp_csv
    Tempfile.open "import.csv" do |tmpfile|
      tmpfile.puts "id,name"
      1000.times do |x| # write enough to be larger than the chunk_size
        tmpfile.puts "#{x},#{SecureRandom.urlsafe_base64(rand(8..16))}"
      end
      yield tmpfile
    end
  end

  def temp_resumable_csv
    Tempfile.open "import.csv" do |tmpfile|
      tmpfile.puts "id,name"
      300000.times do |x| # write enough to be larger than Upload.resumable_threshold
        tmpfile.puts "#{x},#{SecureRandom.urlsafe_base64(rand(8..16))}"
      end
      yield tmpfile
    end
  end

  def temp_json
    Tempfile.open "import.json" do |tmpfile|
      h = {}
      1000.times { |x| h["key-#{x}"] = {name: SecureRandom.urlsafe_base64(rand(8..16)) } }
      tmpfile.write h.to_json
      yield tmpfile
    end
  end

  def get_json_from_multipart_body env
    body = env.body.read.split("\n")
    env.body.rewind
    json = body.detect { |line| line.start_with? "{\"" }
    json
  end
end
