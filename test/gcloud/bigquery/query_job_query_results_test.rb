# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a extract of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "helper"

describe Gcloud::Bigquery::QueryJob, :query_results, :mock_bigquery do
  let(:job) { Gcloud::Bigquery::Job.from_gapi query_job_hash,
                                              bigquery.service }
  let(:job_id) { job.job_id }

  it "can retrieve query results" do
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      [200, {"Content-Type"=>"application/json"},
       query_data_json]
    end

    data = job.query_results
    data.class.must_equal Gcloud::Bigquery::QueryData
    data.count.must_equal 3
    data[0].must_be_kind_of Hash
    data[0]["name"].must_equal "Heidi"
    data[0]["age"].must_equal 36
    data[0]["score"].must_equal 7.65
    data[0]["active"].must_equal true
    data[1].must_be_kind_of Hash
    data[1]["name"].must_equal "Aaron"
    data[1]["age"].must_equal 42
    data[1]["score"].must_equal 8.15
    data[1]["active"].must_equal false
    data[2].must_be_kind_of Hash
    data[2]["name"].must_equal "Sally"
    data[2]["age"].must_equal nil
    data[2]["score"].must_equal nil
    data[2]["active"].must_equal nil
  end

  it "paginates data" do
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      env.params.wont_include "pageToken"
      [200, {"Content-Type"=>"application/json"},
       query_data_json]
    end
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      env.params.must_include "pageToken"
      env.params["pageToken"].must_equal "token1234567890"
      [200, {"Content-Type"=>"application/json"},
       query_data_json]
    end

    data1 = job.query_results
    data1.class.must_equal Gcloud::Bigquery::QueryData
    data1.token.wont_be :nil?
    data1.token.must_equal "token1234567890"
    data2 = job.query_results token: data1.token
    data2.class.must_equal Gcloud::Bigquery::QueryData
  end

  it "paginates data using next? and next" do
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      env.params.wont_include "pageToken"
      [200, {"Content-Type"=>"application/json"},
       query_data_json]
    end
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      env.params.must_include "pageToken"
      env.params["pageToken"].must_equal "token1234567890"
      [200, {"Content-Type"=>"application/json"},
       query_data_json(token: nil)]
    end

    data1 = job.query_results
    data1.class.must_equal Gcloud::Bigquery::QueryData
    data1.token.wont_be :nil?
    data1.next?.must_equal true
    data2 = data1.next
    data2.token.must_be :nil?
    data2.next?.must_equal false
    data2.class.must_equal Gcloud::Bigquery::QueryData
  end

  it "paginates data using all" do
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      env.params.wont_include "pageToken"
      [200, {"Content-Type"=>"application/json"},
       query_data_json]
    end
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      env.params.must_include "pageToken"
      env.params["pageToken"].must_equal "token1234567890"
      [200, {"Content-Type"=>"application/json"},
       query_data_json(token: nil)]
    end

    data = job.query_results.all.to_a
    data.count.must_equal 6
    data.each { |d| d.class.must_equal Hash }
  end

  it "paginates data using all using Enumerator" do
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      env.params.wont_include "pageToken"
      [200, {"Content-Type"=>"application/json"},
       query_data_json]
    end
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      env.params.must_include "pageToken"
      env.params["pageToken"].must_equal "token1234567890"
      [200, {"Content-Type"=>"application/json"},
       query_data_json]
    end

    data = job.query_results.all.take(5)
    data.count.must_equal 5
    data.each { |d| d.class.must_equal Hash }
  end

  it "iterates data using all with request_limit set" do
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      env.params.wont_include "pageToken"
      [200, {"Content-Type"=>"application/json"},
       query_data_json]
    end
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      env.params.must_include "pageToken"
      env.params["pageToken"].must_equal "token1234567890"
      [200, {"Content-Type"=>"application/json"},
       query_data_json]
    end

    data = job.query_results.all(request_limit: 1).to_a
    data.count.must_equal 6
    data.each { |d| d.class.must_equal Hash }
  end

  it "paginates data with max set" do
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      env.params.must_include "maxResults"
      env.params["maxResults"].must_equal "3"
      [200, {"Content-Type"=>"application/json"},
       query_data_json]
    end

    data = job.query_results max: 3
    data.class.must_equal Gcloud::Bigquery::QueryData
  end

  it "paginates data without max set" do
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      env.params.wont_include "maxResults"
      [200, {"Content-Type"=>"application/json"},
       query_data_json]
    end

    data = job.query_results
    data.class.must_equal Gcloud::Bigquery::QueryData
  end

  it "paginates data with start set" do
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      env.params.must_include "startIndex"
      env.params["startIndex"].must_equal "25"
      [200, {"Content-Type"=>"application/json"},
       query_data_json]
    end

    data = job.query_results start: 25
    data.class.must_equal Gcloud::Bigquery::QueryData
  end

  it "paginates data without start set" do
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      env.params.wont_include "startIndex"
      [200, {"Content-Type"=>"application/json"},
       query_data_json]
    end

    data = job.query_results
    data.class.must_equal Gcloud::Bigquery::QueryData
  end

  it "paginates data with timeout set" do
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      env.params.must_include "timeoutMs"
      env.params["timeoutMs"].must_equal "1000"
      [200, {"Content-Type"=>"application/json"},
       query_data_json]
    end

    data = job.query_results timeout: 1000
    data.class.must_equal Gcloud::Bigquery::QueryData
  end

  it "paginates data without timeout set" do
    mock_connection.get "/bigquery/v2/projects/#{project}/queries/#{job_id}" do |env|
      env.params.wont_include "timeoutMs"
      [200, {"Content-Type"=>"application/json"},
       query_data_json]
    end

    data = job.query_results
    data.class.must_equal Gcloud::Bigquery::QueryData
  end

  def query_job_hash
    hash = random_job_gapi("job9876543210")
    hash["configuration"]["query"] = {
      query: "SELECT name, age, score, active FROM [users]",
      destinationTable: {
        projectId: "target_project_id",
        datasetId: "target_dataset_id",
        "tableId"   => "target_table_id"
      },
      tableDefinitions: {},
      create_disposition: "CREATE_IF_NEEDED",
      write_disposition: "WRITE_EMPTY",
      defaultDataset: {
        datasetId: "my_dataset",
        projectId: project
      },
      priority: "BATCH",
      allow_large_results: true,
      use_query_cache: true,
      flatten_results: true
    }
    hash
  end

  def query_data_json token: "token1234567890"
    query_data_gapi(token: token).to_json
  end

  def query_data_gapi token: "token1234567890"
    {
      kind: "bigquery#getQueryResultsResponse",
      etag: "etag1234567890",
      jobReference: {
        projectId: project,
        jobId: "job9876543210"
      },
      schema: {
        fields: [
          {
            name: "name",
            type: "STRING",
            mode: "NULLABLE"
          },
          {
            name: "age",
            type: "INTEGER",
            mode: "NULLABLE"
          },
          {
            name: "score",
            type: "FLOAT",
            mode: "NULLABLE"
          },
          {
            name: "active",
            type: "BOOLEAN",
            mode: "NULLABLE"
          }
        ]
      },
      rows: [
        {
          f: [
            {
              v: "Heidi"
            },
            {
              v: "36"
            },
            {
              v: "7.65"
            },
            {
              v: "true"
            }
          ]
        },
        {
          f: [
            {
              v: "Aaron"
            },
            {
              v: "42"
            },
            {
              v: "8.15"
            },
            {
              v: "false"
            }
          ]
        },
        {
          f: [
            {
              v: "Sally"
            },
            {
              v: nil
            },
            {
              v: nil
            },
            {
              v: nil
            }
          ]
        }
      ],
      pageToken: token,
      totalRows: 3,
      totalBytesProcessed: 456789,
      jobComplete: true,
      cacheHit: false
    }
  end
end
