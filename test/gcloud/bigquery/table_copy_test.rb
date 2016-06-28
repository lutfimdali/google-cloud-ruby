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

describe Gcloud::Bigquery::Table, :copy, :mock_bigquery do
  let(:source_dataset) { "source_dataset" }
  let(:source_table_id) { "source_table_id" }
  let(:source_table_name) { "Source Table" }
  let(:source_description) { "This is the source table" }
  let(:source_table_gapi) { random_table_gapi source_dataset,
                                              source_table_id,
                                              source_table_name,
                                              source_description }
  let(:source_table) { Gcloud::Bigquery::Table.from_gapi source_table_gapi,
                                                         bigquery.service }
  let(:target_dataset) { "target_dataset" }
  let(:target_table_id) { "target_table_id" }
  let(:target_table_name) { "Target Table" }
  let(:target_description) { "This is the target table" }
  let(:target_table_gapi) { random_table_gapi target_dataset,
                                              target_table_id,
                                              target_table_name,
                                              target_description }
  let(:target_table) { Gcloud::Bigquery::Table.from_gapi target_table_gapi,
                                                         bigquery.service }
  let(:target_table_other_proj_gapi) { random_table_gapi target_dataset,
                                              target_table_id,
                                              target_table_name,
                                              target_description,
                                              "target-project" }
  let(:target_table_other_proj) { Gcloud::Bigquery::Table.from_gapi target_table_other_proj_gapi,
                                                         bigquery.service }

  it "can copy itself" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock

    job_gapi = copy_job_gapi(source_table, target_table)
    mock.expect :insert_job, job_gapi, [project, job_gapi]

    job = source_table.copy target_table
    mock.verify

    job.must_be_kind_of Gcloud::Bigquery::CopyJob
  end

  it "can copy to a table identified by a string" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock

    job_gapi = copy_job_gapi(source_table, target_table_other_proj)
    mock.expect :insert_job, job_gapi, ["test-project", job_gapi]

    job = source_table.copy "target-project:target_dataset.target_table_id"
    mock.verify

    job.must_be_kind_of Gcloud::Bigquery::CopyJob
  end

  it "can copy to a table name string only" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    new_target_table = Gcloud::Bigquery::Table.from_gapi(
      random_table_gapi(source_dataset,
                        "new_target_table_id",
                        target_table_name,
                        target_description),
      bigquery.service
    )

    job_gapi = copy_job_gapi(source_table, new_target_table)
    mock.expect :insert_job, job_gapi, [project, job_gapi]

    job = source_table.copy "new_target_table_id"
    mock.verify

    job.must_be_kind_of Gcloud::Bigquery::CopyJob
  end

  it "can copy itself as a dryrun" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock

    job_gapi = copy_job_gapi(source_table, target_table)
    job_gapi.configuration.dry_run = true
    mock.expect :insert_job, job_gapi, [project, job_gapi]

    job = source_table.copy target_table, dryrun: true
    mock.verify

    job.must_be_kind_of Gcloud::Bigquery::CopyJob
  end

  it "can copy itself with create disposition" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock

    job_gapi = copy_job_gapi(source_table, target_table)
    job_gapi.configuration.copy.create_disposition = "CREATE_NEVER"
    mock.expect :insert_job, job_gapi, [project, job_gapi]

    job = source_table.copy target_table, create: "CREATE_NEVER"
    mock.verify

    job.must_be_kind_of Gcloud::Bigquery::CopyJob
  end

  it "can copy itself with create disposition symbol" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock

    job_gapi = copy_job_gapi(source_table, target_table)
    job_gapi.configuration.copy.create_disposition = "CREATE_NEVER"
    mock.expect :insert_job, job_gapi, [project, job_gapi]

    job = source_table.copy target_table, create: :never
    mock.verify

    job.must_be_kind_of Gcloud::Bigquery::CopyJob
  end

  focus
  it "can copy itself with write disposition" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock

    job_gapi = copy_job_gapi(source_table, target_table)
    job_gapi.configuration.copy.write_disposition = "WRITE_TRUNCATE"
    mock.expect :insert_job, job_gapi, [project, job_gapi]

    job = source_table.copy target_table, write: "WRITE_TRUNCATE"
    mock.verify

    job.must_be_kind_of Gcloud::Bigquery::CopyJob
  end

  it "can copy itself with write disposition symbol" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock

    job_gapi = copy_job_gapi(source_table, target_table)
    job_gapi.configuration.copy.write_disposition = "WRITE_TRUNCATE"
    mock.expect :insert_job, job_gapi, [project, job_gapi]

    job = source_table.copy target_table, write: :truncate
    mock.verify

    job.must_be_kind_of Gcloud::Bigquery::CopyJob
  end

  def copy_job_gapi source, target
    Google::Apis::BigqueryV2::Job.new(
      configuration: Google::Apis::BigqueryV2::JobConfiguration.new(
        copy: Google::Apis::BigqueryV2::JobConfigurationTableCopy.new(
          source_table: table_reference_gapi(
            source.project_id,
            source.dataset_id,
            source.table_id
          ),
          destination_table: table_reference_gapi(
            target.project_id,
            target.dataset_id,
            target.table_id
          ),
          create_disposition: nil,
          write_disposition: nil
        ),
        dry_run: nil
      )
    )
  end
end
