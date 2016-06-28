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


require "gcloud/bigquery/query_data"
require "gcloud/bigquery/job/list"
require "gcloud/bigquery/errors"

module Gcloud
  module Bigquery
    ##
    # # Job
    #
    # Represents a generic Job that may be performed on a {Table}.
    #
    # The subclasses of Job represent the specific BigQuery job types:
    # {CopyJob}, {ExtractJob}, {LoadJob}, and {QueryJob}.
    #
    # A job instance is created when you call {Project#query_job},
    # {Dataset#query_job}, {Table#copy}, {Table#extract}, {Table#load}, or
    # {View#data}.
    #
    # @see https://cloud.google.com/bigquery/docs/managing_jobs_datasets_projects
    #   Managing Jobs, Datasets, and Projects
    # @see https://cloud.google.com/bigquery/docs/reference/v2/jobs Jobs API
    #   reference
    #
    # @example
    #   require "gcloud"
    #
    #   gcloud = Gcloud.new
    #   bigquery = gcloud.bigquery
    #
    #   q = "SELECT COUNT(word) as count FROM publicdata:samples.shakespeare"
    #   job = bigquery.query_job q
    #
    #   job.wait_until_done!
    #
    #   if job.failed?
    #     puts job.error
    #   else
    #     puts job.query_results.first
    #   end
    #
    class Job
      ##
      # @private The Service object.
      attr_accessor :service

      ##
      # @private The Google API Client object.
      attr_accessor :gapi

      ##
      # @private Create an empty Job object.
      def initialize
        @service = nil
        @gapi = {}
      end

      ##
      # The ID of the job.
      def job_id
        @gapi.job_reference.job_id
      end

      ##
      # The ID of the project containing the job.
      def project_id
        @gapi.job_reference.project_id
      end

      ##
      # The current state of the job. The possible values are `PENDING`,
      # `RUNNING`, and `DONE`. A `DONE` state does not mean that the job
      # completed successfully. Use {#failed?} to discover if an error occurred
      # or if the job was successful.
      def state
        return nil if @gapi.status.nil?
        @gapi.status.state
      end

      ##
      # Checks if the job's state is `RUNNING`.
      def running?
        return false if state.nil?
        "running".casecmp(state).zero?
      end

      ##
      # Checks if the job's state is `PENDING`.
      def pending?
        return false if state.nil?
        "pending".casecmp(state).zero?
      end

      ##
      # Checks if the job's state is `DONE`. When `true`, the job has stopped
      # running. However, a `DONE` state does not mean that the job completed
      # successfully.  Use {#failed?} to detect if an error occurred or if the
      # job was successful.
      def done?
        return false if state.nil?
        "done".casecmp(state).zero?
      end

      ##
      # Checks if an error is present.
      def failed?
        !error.nil?
      end

      ##
      # The time when the job was created.
      def created_at
        return nil if @gapi.statistics.nil?
        return nil if @gapi.statistics.creation_time.nil?
        Time.at(@gapi.statistics.creation_time / 1000.0)
      end

      ##
      # The time when the job was started.
      # This field is present after the job's state changes from `PENDING`
      # to either `RUNNING` or `DONE`.
      def started_at
        return nil if @gapi.statistics.nil?
        return nil if @gapi.statistics.start_time.nil?
        Time.at(@gapi.statistics.start_time / 1000.0)
      end

      ##
      # The time when the job ended.
      # This field is present when the job's state is `DONE`.
      def ended_at
        return nil if @gapi.statistics.nil?
        return nil if @gapi.statistics.end_time.nil?
        Time.at(@gapi.statistics.end_time / 1000.0)
      end

      ##
      # The configuration for the job. Returns a hash.
      #
      # @see https://cloud.google.com/bigquery/docs/reference/v2/jobs Jobs API
      #   reference
      def configuration
        hash = @gapi.configuration || {}
        hash = hash.to_hash if hash.respond_to? :to_hash
        hash
      end
      alias_method :config, :configuration

      ##
      # The statistics for the job. Returns a hash.
      #
      # @see https://cloud.google.com/bigquery/docs/reference/v2/jobs Jobs API
      #   reference
      def statistics
        hash = @gapi.statistics || {}
        hash = hash.to_hash if hash.respond_to? :to_hash
        hash
      end
      alias_method :stats, :statistics

      ##
      # The job's status. Returns a hash. The values contained in the hash are
      # also exposed by {#state}, {#error}, and {#errors}.
      def status
        hash = @gapi.status || {}
        hash = hash.to_hash if hash.respond_to? :to_hash
        hash
      end

      ##
      # The last error for the job, if any errors have occurred. Returns a
      # hash.
      #
      # @see https://cloud.google.com/bigquery/docs/reference/v2/jobs Jobs API
      #   reference
      #
      # @return [Hash] Returns a hash containing `reason` and `message` keys:
      #
      #   {
      #     "reason"=>"notFound",
      #     "message"=>"Not found: Table publicdata:samples.BAD_ID"
      #   }
      #
      def error
        status.error_result
      end

      ##
      # The errors for the job, if any errors have occurred. Returns an array
      # of hash objects. See {#error}.
      def errors
        Array status.errors
      end

      ##
      # Created a new job with the current configuration.
      def rerun!
        ensure_service!
        gapi = service.insert_job configuration
        Job.from_gapi gapi, service
      end

      ##
      # Reloads the job with current data from the BigQuery service.
      def reload!
        ensure_service!
        gapi = service.get_job job_id
        @gapi = gapi
      end
      alias_method :refresh!, :reload!

      ##
      # Refreshes the job until the job is `DONE`.
      # The delay between refreshes will incrementally increase.
      #
      # @example
      #   require "gcloud"
      #
      #   gcloud = Gcloud.new
      #   bigquery = gcloud.bigquery
      #   dataset = bigquery.dataset "my_dataset"
      #   table = dataset.table "my_table"
      #
      #   extract_job = table.extract "gs://my-bucket/file-name.json",
      #                               format: "json"
      #   extract_job.wait_until_done!
      #   extract_job.done? #=> true
      def wait_until_done!
        backoff = ->(retries) { sleep 2 * retries + 5 }
        retries = 0
        until done?
          backoff.call retries
          retries += 1
          reload!
        end
      end

      ##
      # @private New Job from a Google API Client object.
      def self.from_gapi gapi, conn
        klass = klass_for gapi
        klass.new.tap do |f|
          f.gapi = gapi
          f.service = conn
        end
      end

      protected

      ##
      # Raise an error unless an active connection is available.
      def ensure_service!
        fail "Must have active connection" unless service
      end

      ##
      # Get the subclass for a job type
      def self.klass_for gapi
        if gapi.configuration.copy
          return CopyJob
        elsif gapi.configuration.extract
          return ExtractJob
        elsif gapi.configuration.load
          return LoadJob
        elsif gapi.configuration.query
          return QueryJob
        end
        Job
      end

      def retrieve_table project_id, dataset_id, table_id
        ensure_service!
        gapi = service.get_project_table project_id, dataset_id, table_id
        Table.from_gapi gapi, service
      rescue Google::Apis::ClientError => e
        raise e unless e.status_code == 404 # TODO: convert e to Gcloud::Error
        nil
      end
    end
  end
end

# We need Job to be defined before loading these.
require "gcloud/bigquery/copy_job"
require "gcloud/bigquery/extract_job"
require "gcloud/bigquery/load_job"
require "gcloud/bigquery/query_job"
