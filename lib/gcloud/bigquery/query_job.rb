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


module Gcloud
  module Bigquery
    ##
    # # QueryJob
    #
    # A {Job} subclass representing a query operation that may be performed
    # on a {Table}. A QueryJob instance is created when you call
    # {Project#query_job}, {Dataset#query_job}, or {View#data}.
    #
    # @see https://cloud.google.com/bigquery/querying-data Querying Data
    # @see https://cloud.google.com/bigquery/docs/reference/v2/jobs Jobs API
    #   reference
    #
    class QueryJob < Job
      ##
      # Checks if the priority for the query is `BATCH`.
      def batch?
        val = config.query.priority
        val == "BATCH"
      end

      ##
      # Checks if the priority for the query is `INTERACTIVE`.
      def interactive?
        val = config.query.priority
        return true if val.nil?
        val == "INTERACTIVE"
      end

      ##
      # Checks if the the query job allows arbitrarily large results at a slight
      # cost to performance.
      def large_results?
        val = config.query.allow_large_results
        return false if val.nil?
        val
      end

      ##
      # Checks if the query job looks for an existing result in the query cache.
      # For more information, see [Query
      # Caching](https://cloud.google.com/bigquery/querying-data#querycaching).
      def cache?
        val = config.query.use_query_cache
        return false if val.nil?
        val
      end

      ##
      # Checks if the query job flattens nested and repeated fields in the query
      # results. The default is `true`. If the value is `false`, #large_results?
      # should return `true`.
      def flatten?
        val = config.query.flatten_results
        return true if val.nil?
        val
      end

      ##
      # Checks if the query results are from the query cache.
      def cache_hit?
        stats.query.cache_hit
      end

      ##
      # The number of bytes processed by the query.
      def bytes_processed
        stats.query.total_bytes_processed
      end

      ##
      # The table in which the query results are stored.
      def destination
        table = config.query.destination_table
        return nil unless table
        retrieve_table table.project_id,
                       table.dataset_id,
                       table.table_id
      end

      ##
      # Retrieves the query results for the job.
      #
      # @param [String] token Page token, returned by a previous call,
      #   identifying the result set.
      # @param [Integer] max Maximum number of results to return.
      # @param [Integer] start Zero-based index of the starting row to read.
      # @param [Integer] timeout How long to wait for the query to complete, in
      #   milliseconds, before returning. Default is 10,000 milliseconds (10
      #   seconds).
      #
      # @return [Gcloud::Bigquery::QueryData]
      #
      # @example
      #   require "gcloud"
      #
      #   gcloud = Gcloud.new
      #   bigquery = gcloud.bigquery
      #
      #   q = "SELECT word FROM publicdata:samples.shakespeare"
      #   job = bigquery.query_job q
      #
      #   job.wait_until_done!
      #   data = job.query_results
      #   data.each do |row|
      #     puts row["word"]
      #   end
      #   data = data.next if data.next?
      #
      def query_results token: nil, max: nil, start: nil, timeout: nil
        ensure_service!
        options = { token: token, max: max, start: start, timeout: timeout }
        gapi = service.job_query_results job_id, options
        QueryData.from_gapi gapi, service
      end
    end
  end
end
