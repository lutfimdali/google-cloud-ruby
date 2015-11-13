#--
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

require "gcloud/search/result/list"

module Gcloud
  module Search
    ##
    # = Result
    #
    # See Gcloud#search
    class Result
      ##
      # The raw data object.
      attr_accessor :raw #:nodoc:

      ##
      # Creates a new Result instance.
      def initialize #:nodoc:
        @raw = {}
      end

      ##
      # The ID of the Document referenced by this result.
      def doc_id
        @raw["docId"]
      end

      ##
      # The token for the next page of results.
      def token
        @raw["nextPageToken"]
      end

      ##
      # A shorter version of the pagination token returned by #token. Helpful
      # for comparison and logging, but not valid for the next page of results.
      def truncated_token
        "#{token[0...(token.index('_') || 24)]}..." if token
      end

      def inspect #:nodoc:
        "#{self.class}(doc_id: #{doc_id}, token: #{truncated_token}...)"
      end

      ##
      # New Result from a raw data object.
      def self.from_hash hash #:nodoc:
        new.tap do |d|
          d.raw = hash
        end
      end

      ##
      # Returns the Result data as a hash
      def to_hash #:nodoc:
        @raw.dup
      end
    end
  end
end