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
require "google/apis/dns_v1"

module Gcloud
  module Dns
    ##
    # @private
    # Represents the service to DNS, exposing the API calls.
    class Service
      ##
      # Alias to the Google Client API module
      API = Google::Apis::DnsV1

      attr_accessor :project
      attr_accessor :credentials

      ##
      # Creates a new Service instance.
      def initialize project, credentials
        @project = project
        @credentials = credentials
        @service = API::DnsService.new
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
      # Returns Google::Apis::DnsV1::Project
      def get_project project_id = @project
        service.get_project project_id
      end

      ##
      # Returns Google::Apis::DnsV1::ManagedZone
      def get_zone zone_id
        service.get_managed_zone @project, zone_id
      end

      ##
      # Returns Google::Apis::DnsV1::ListManagedZonesResponse
      def list_zones token: nil, max: nil
        service.list_managed_zones @project, max_results: max, page_token: token
      end

      ##
      # Returns Google::Apis::DnsV1::ManagedZone
      def create_zone zone_name, zone_dns, description: nil,
                      name_server_set: nil
        managed_zone = Google::Apis::DnsV1::ManagedZone.new(
          kind: "dns#managedZone",
          name: zone_name,
          dns_name: zone_dns,
          description: (description || ""),
          name_server_set: name_server_set
        )
        service.create_managed_zone @project, managed_zone
      end

      def delete_zone zone_id
        service.delete_managed_zone @project, zone_id
      end

      ##
      # Returns Google::Apis::DnsV1::Change
      def get_change zone_id, change_id
        service.get_change @project, zone_id, change_id
      end

      ##
      # Returns Google::Apis::DnsV1::ListChangesResponse
      def list_changes zone_id, token: nil, max: nil, order: nil, sort: nil
        service.list_changes @project, zone_id, max_results: max,
                                                page_token: token,
                                                sort_by: sort,
                                                sort_order: order
      end

      ##
      # Returns Google::Apis::DnsV1::Change
      def create_change zone_id, additions, deletions
        change = Google::Apis::DnsV1::Change.new(
          kind: "dns#change",
          additions: Array(additions),
          deletions: Array(deletions)
        )
        service.create_change @project, zone_id, change
      end

      ##
      # Returns Google::Apis::DnsV1::ListResourceRecordSetsResponse
      def list_records zone_id, name = nil, type = nil, token: nil, max: nil
        service.list_resource_record_sets @project, zone_id, max_results: max,
                                                             name: name,
                                                             page_token: token,
                                                             type: type
      end

      ##
      # Fully Qualified Domain Name
      def self.fqdn name, origin_dns
        name = name.to_s.strip
        return name if self.ip_addr? name
        name = origin_dns if name.empty?
        name = origin_dns if name == "@"
        name = "#{name}.#{origin_dns}" unless name.include? "."
        name = "#{name}." unless name.end_with? "."
        name
      end

      require "ipaddr"
      # Fix to make ip_addr? work on ruby 1.9
      IPAddr::Error = ArgumentError unless defined? IPAddr::Error

      def self.ip_addr? name
        IPAddr.new name
        true
      rescue IPAddr::Error
        false
      end

      def inspect
        "#{self.class}(#{@project})"
      end
    end
  end
end
