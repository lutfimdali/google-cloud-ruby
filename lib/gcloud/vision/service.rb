# Copyright 2016 Google Inc. All rights reserved.
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


require "gcloud/version"
require "google/apis/vision_v1"

module Gcloud
  module Vision
    ##
    # @private
    # Represents the service to Vision, exposing the API calls.
    class Service
      ##
      # Alias to the Google Client API module
      API = Google::Apis::VisionV1

      attr_accessor :project
      attr_accessor :credentials

      ##
      # Creates a new Service instance.
      def initialize project, credentials
        @project = project
        @credentials = credentials
        @service = API::VisionService.new
        @service.client_options.application_name    = "gcloud-ruby"
        @service.client_options.application_version = Gcloud::VERSION
        @service.authorization = @credentials.client
      end

      def service
        return mocked_service if mocked_service
        @service
      end
      attr_accessor :mocked_service

      ##
      # Returns API::BatchAnnotateImagesResponse
      def annotate requests
        request = API::BatchAnnotateImagesRequest.new(requests: requests)
        service.annotate_image request
      end

      def inspect
        "#{self.class}(#{@project})"
      end
    end
  end
end
