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

describe Gcloud::Bigquery::CopyJob, :mock_bigquery do
  let(:job) { Gcloud::Bigquery::Job.from_gapi copy_job_gapi,
                                              bigquery.service }
  let(:job_id) { job.job_id }

  it "knows it is copy job" do
    job.must_be_kind_of Gcloud::Bigquery::CopyJob
  end

  it "knows its copy tables" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock

    mock.expect :get_table, source_table_gapi, ["source_project_id", "source_dataset_id", "source_table_id"]
    source = job.source
    source.must_be_kind_of Gcloud::Bigquery::Table
    source.project_id.must_equal "source_project_id"
    source.dataset_id.must_equal "source_dataset_id"
    source.table_id.must_equal   "source_table_id"

    mock.expect :get_table, destination_table_gapi, ["target_project_id", "target_dataset_id", "target_table_id"]
    destination = job.destination
    destination.must_be_kind_of Gcloud::Bigquery::Table
    destination.project_id.must_equal "target_project_id"
    destination.dataset_id.must_equal "target_dataset_id"
    destination.table_id.must_equal   "target_table_id"
    mock.verify
  end

  it "knows its create/write disposition flags" do
    job.must_be :create_if_needed?
    job.wont_be :create_never?
    job.wont_be :write_truncate?
    job.wont_be :write_append?
    job.must_be :write_empty?
  end

  it "knows its copy config" do
    job.config.must_be_kind_of Google::Apis::BigqueryV2::JobConfiguration
    job.config.copy.source_table.project_id.must_equal "source_project_id"
    job.config.copy.destination_table.table_id.must_equal "target_table_id"
    job.config.copy.create_disposition.must_equal "CREATE_IF_NEEDED"
  end

  def copy_job_gapi
    gapi = random_job_gapi
    gapi.configuration = Google::Apis::BigqueryV2::JobConfiguration.new(
      copy: Google::Apis::BigqueryV2::JobConfigurationTableCopy.new(
        source_table: table_reference_gapi(
          "source_project_id",
          "source_dataset_id",
          "source_table_id"
        ),
        destination_table: table_reference_gapi(
          "target_project_id",
          "target_dataset_id",
          "target_table_id"
        ),
        create_disposition: "CREATE_IF_NEEDED",
        write_disposition: "WRITE_EMPTY"
      )
    )
    gapi
  end
end
