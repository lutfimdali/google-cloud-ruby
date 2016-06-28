# Copyright 2015 Google Inc. All rights reserved.
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

describe Gcloud::Bigquery::Job, :mock_bigquery do
  # Create a job object with the project's mocked connection object
  let(:job_hash) { random_job_gapi }
  let(:job) { Gcloud::Bigquery::Job.from_gapi job_hash,
                                              bigquery.service }
  let(:job_id) { job.job_id }

  let(:failed_job_hash) do
    hash = random_job_gapi "1234567890", "DONE"
    hash["status"]["errorResult"] = {
      "reason"    => "r34s0n",
      "location"  => "l0c4t10n",
      debugInfo: "d3bugInf0",
      "message"   => "m3ss4g3"
    }
    hash["status"]["errors"] = [{
      "reason"    => "r34s0n",
      "location"  => "l0c4t10n",
      debugInfo: "d3bugInf0",
      "message"   => "m3ss4g3"
    }]
    hash
  end
  let(:failed_job) { Gcloud::Bigquery::Job.from_gapi failed_job_hash,
                                              bigquery.service }
  let(:failed_job_id) { failed_job.job_id }

  it "knows its attributes" do
    job.job_id.must_equal job_hash["jobReference"]["jobId"]
  end

  it "knows its state" do
    job.state.must_equal "running"
    job.must_be :running?
    job.wont_be :pending?
    job.wont_be :done?
    job.wont_be :failed?

    job.gapi["status"]["state"] = "RUNNING"
    job.state.must_equal "RUNNING"
    job.must_be :running?
    job.wont_be :pending?
    job.wont_be :done?
    job.wont_be :failed?

    job.gapi["status"]["state"] = "pending"
    job.state.must_equal "pending"
    job.wont_be :running?
    job.must_be :pending?
    job.wont_be :done?
    job.wont_be :failed?

    job.gapi["status"]["state"] = "PENDING"
    job.state.must_equal "PENDING"
    job.wont_be :running?
    job.must_be :pending?
    job.wont_be :done?
    job.wont_be :failed?

    job.gapi["status"]["state"] = "done"
    job.state.must_equal "done"
    job.wont_be :running?
    job.wont_be :pending?
    job.must_be :done?
    job.wont_be :failed?

    job.gapi["status"]["state"] = "DONE"
    job.state.must_equal "DONE"
    job.wont_be :running?
    job.wont_be :pending?
    job.must_be :done?
    job.wont_be :failed?

    job.gapi["status"]["state"] = nil
    job.state.must_equal nil
    job.wont_be :running?
    job.wont_be :pending?
    job.wont_be :done?
    job.wont_be :failed?
  end

  it "knows its creation and modification times" do
    job.gapi["statistics"]["creationTime"] = nil
    job.gapi["statistics"]["startTime"] = nil
    job.gapi["statistics"]["endTime"] = nil

    job.created_at.must_be :nil?
    job.started_at.must_be :nil?
    job.ended_at.must_be :nil?

    nowish = Time.now
    timestamp = (nowish.to_f * 1000).floor

    job.gapi["statistics"]["creationTime"] = timestamp
    job.gapi["statistics"]["startTime"] = timestamp
    job.gapi["statistics"]["endTime"] = timestamp

    job.created_at.must_be_close_to nowish
    job.started_at.must_be_close_to nowish
    job.ended_at.must_be_close_to nowish
  end

  it "knows its configuration" do
    job.config.must_be_kind_of Hash
    job.config["dryRun"].must_equal false
    job.configuration.must_be_kind_of Hash
    job.configuration["dryRun"].must_equal false
  end

  it "knows its statistics config" do
    job.statistics.must_be_kind_of Hash
    job.statistics["creationTime"].wont_be :nil?
    job.stats.must_be_kind_of Hash
    job.stats["creationTime"].wont_be :nil?
  end

  it "knows its error info if it has not failed" do
    job.wont_be :failed?
    job.error.must_be :nil?
    job.errors.count.must_equal 0
  end

  it "knows if it has failed" do
    failed_job.state.must_equal "DONE"
    failed_job.must_be :failed?
    failed_job.error.must_be_kind_of Hash
    failed_job.error.wont_be :empty?
    failed_job.error["reason"].must_equal "r34s0n"
    failed_job.error["location"].must_equal "l0c4t10n"
    failed_job.error["debugInfo"].must_equal "d3bugInf0"
    failed_job.error["message"].must_equal "m3ss4g3"
    failed_job.errors.count.must_equal 1
    failed_job.errors.first["reason"].must_equal "r34s0n"
    failed_job.errors.first["location"].must_equal "l0c4t10n"
    failed_job.errors.first["debugInfo"].must_equal "d3bugInf0"
    failed_job.errors.first["message"].must_equal "m3ss4g3"
  end

  it "can reload itself" do
    mock_connection.get "/bigquery/v2/projects/#{project}/jobs/#{job_id}" do |env|
      [200, {"Content-Type"=>"application/json"},
       random_job_gapi(job_id, "done").to_json]
    end

    job.must_be :running?
    job.reload!
    job.must_be :done?
  end

  it "can wait until done" do
    mock_connection.get "/bigquery/v2/projects/#{project}/jobs/#{job_id}" do |env|
      [200, {"Content-Type"=>"application/json"},
       random_job_gapi(job_id, "pending").to_json]
    end
    mock_connection.get "/bigquery/v2/projects/#{project}/jobs/#{job_id}" do |env|
      [200, {"Content-Type"=>"application/json"},
       random_job_gapi(job_id, "pending").to_json]
    end
    mock_connection.get "/bigquery/v2/projects/#{project}/jobs/#{job_id}" do |env|
      [200, {"Content-Type"=>"application/json"},
       random_job_gapi(job_id, "running").to_json]
    end
    mock_connection.get "/bigquery/v2/projects/#{project}/jobs/#{job_id}" do |env|
      [200, {"Content-Type"=>"application/json"},
       random_job_gapi(job_id, "running").to_json]
    end
    mock_connection.get "/bigquery/v2/projects/#{project}/jobs/#{job_id}" do |env|
      [200, {"Content-Type"=>"application/json"},
       random_job_gapi(job_id, "done").to_json]
    end

    # mock out the sleep method so the test doesn't actually block
    def job.sleep *args
    end

    job.must_be :running?
    job.wait_until_done!
    job.must_be :done?
  end

  it "can re-run itself" do
    mock_connection.post "/bigquery/v2/projects/#{project}/jobs" do |env|
      [200, {"Content-Type"=>"application/json"},
       random_job_gapi(job_id + "-rerun").to_json]
    end

    new_job = job.rerun!
    new_job.configuration.must_equal job.configuration
    new_job.job_id.wont_equal job.job_id
  end
end
