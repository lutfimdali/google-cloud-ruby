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


require "google/cloud/bigquery/schema/field"

module Google
  module Cloud
    module Bigquery
      ##
      # # Table Schema
      #
      # A builder for BigQuery table schemas, passed to block arguments to
      # {Dataset#create_table} and {Table#schema}. Supports nested and
      # repeated fields via a nested block.
      #
      # @see https://cloud.google.com/bigquery/preparing-data-for-bigquery
      #   Preparing Data for BigQuery
      #
      # @example
      #   require "google/cloud/bigquery"
      #
      #   bigquery = Google::Cloud::Bigquery.new
      #   dataset = bigquery.dataset "my_dataset"
      #   table = dataset.create_table "my_table"
      #
      #   table.schema do |schema|
      #     schema.string "first_name", mode: :required
      #     schema.record "cities_lived", mode: :repeated do |cities_lived|
      #       cities_lived.string "place", mode: :required
      #       cities_lived.integer "number_of_years", mode: :required
      #     end
      #   end
      #
      class Schema
        ##
        # The fields of the table schema.
        def fields
          if frozen?
            Array(@gapi.fields).map { |f| Field.from_gapi(f).freeze }.freeze
          else
            Array(@gapi.fields).map { |f| Field.from_gapi f }
          end
        end

        ##
        # The names of the fields as symbols.
        def headers
          fields.map(&:name).map(&:to_sym)
        end

        ##
        # Retreive a fields by name.
        def field name
          f = fields.find { |fld| fld.name == name.to_s }
          return nil if f.nil?
          yield f if block_given?
          f
        end

        ##
        # Whether the schema has no fields defined.
        def empty?
          fields.empty?
        end

        ##
        # Adds a string field to the schema.
        #
        # @param [String] name The field name. The name must contain only
        #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
        #   start with a letter or underscore. The maximum length is 128
        #   characters.
        # @param [String] description A description of the field.
        # @param [Symbol] mode The field's mode. The possible values are
        #   `:nullable`, `:required`, and `:repeated`. The default value is
        #   `:nullable`.
        def string name, description: nil, mode: :nullable
          add_field name, :string, description: description, mode: mode
        end

        ##
        # Adds an integer field to the schema.
        #
        # @param [String] name The field name. The name must contain only
        #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
        #   start with a letter or underscore. The maximum length is 128
        #   characters.
        # @param [String] description A description of the field.
        # @param [Symbol] mode The field's mode. The possible values are
        #   `:nullable`, `:required`, and `:repeated`. The default value is
        #   `:nullable`.
        def integer name, description: nil, mode: :nullable
          add_field name, :integer, description: description, mode: mode
        end

        ##
        # Adds a floating-point number field to the schema.
        #
        # @param [String] name The field name. The name must contain only
        #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
        #   start with a letter or underscore. The maximum length is 128
        #   characters.
        # @param [String] description A description of the field.
        # @param [Symbol] mode The field's mode. The possible values are
        #   `:nullable`, `:required`, and `:repeated`. The default value is
        #   `:nullable`.
        def float name, description: nil, mode: :nullable
          add_field name, :float, description: description, mode: mode
        end

        ##
        # Adds a boolean field to the schema.
        #
        # @param [String] name The field name. The name must contain only
        #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
        #   start with a letter or underscore. The maximum length is 128
        #   characters.
        # @param [String] description A description of the field.
        # @param [Symbol] mode The field's mode. The possible values are
        #   `:nullable`, `:required`, and `:repeated`. The default value is
        #   `:nullable`.
        def boolean name, description: nil, mode: :nullable
          add_field name, :boolean, description: description, mode: mode
        end

        ##
        # Adds a bytes field to the schema.
        #
        # @param [String] name The field name. The name must contain only
        #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
        #   start with a letter or underscore. The maximum length is 128
        #   characters.
        # @param [String] description A description of the field.
        # @param [Symbol] mode The field's mode. The possible values are
        #   `:nullable`, `:required`, and `:repeated`. The default value is
        #   `:nullable`.
        def bytes name, description: nil, mode: :nullable
          add_field name, :bytes, description: description, mode: mode
        end

        ##
        # Adds a timestamp field to the schema.
        #
        # @param [String] name The field name. The name must contain only
        #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
        #   start with a letter or underscore. The maximum length is 128
        #   characters.
        # @param [String] description A description of the field.
        # @param [Symbol] mode The field's mode. The possible values are
        #   `:nullable`, `:required`, and `:repeated`. The default value is
        #   `:nullable`.
        def timestamp name, description: nil, mode: :nullable
          add_field name, :timestamp, description: description, mode: mode
        end

        ##
        # Adds a time field to the schema.
        #
        # @param [String] name The field name. The name must contain only
        #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
        #   start with a letter or underscore. The maximum length is 128
        #   characters.
        # @param [String] description A description of the field.
        # @param [Symbol] mode The field's mode. The possible values are
        #   `:nullable`, `:required`, and `:repeated`. The default value is
        #   `:nullable`.
        def time name, description: nil, mode: :nullable
          add_field name, :time, description: description, mode: mode
        end

        ##
        # Adds a datetime field to the schema.
        #
        # @param [String] name The field name. The name must contain only
        #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
        #   start with a letter or underscore. The maximum length is 128
        #   characters.
        # @param [String] description A description of the field.
        # @param [Symbol] mode The field's mode. The possible values are
        #   `:nullable`, `:required`, and `:repeated`. The default value is
        #   `:nullable`.
        def datetime name, description: nil, mode: :nullable
          add_field name, :datetime, description: description, mode: mode
        end

        ##
        # Adds a date field to the schema.
        #
        # @param [String] name The field name. The name must contain only
        #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
        #   start with a letter or underscore. The maximum length is 128
        #   characters.
        # @param [String] description A description of the field.
        # @param [Symbol] mode The field's mode. The possible values are
        #   `:nullable`, `:required`, and `:repeated`. The default value is
        #   `:nullable`.
        def date name, description: nil, mode: :nullable
          add_field name, :date, description: description, mode: mode
        end

        ##
        # Adds a record field to the schema. A block must be passed describing
        # the nested fields of the record. For more information about nested
        # and repeated records, see [Preparing Data for BigQuery
        # ](https://cloud.google.com/bigquery/preparing-data-for-bigquery).
        #
        # @param [String] name The field name. The name must contain only
        #   letters (a-z, A-Z), numbers (0-9), or underscores (_), and must
        #   start with a letter or underscore. The maximum length is 128
        #   characters.
        # @param [String] description A description of the field.
        # @param [Symbol] mode The field's mode. The possible values are
        #   `:nullable`, `:required`, and `:repeated`. The default value is
        #   `:nullable`.
        # @yield [field] a block for setting the nested record's schema
        # @yieldparam [Field] field the object accepting the
        #   nested schema
        #
        # @example
        #   require "google/cloud/bigquery"
        #
        #   bigquery = Google::Cloud::Bigquery.new
        #   dataset = bigquery.dataset "my_dataset"
        #   table = dataset.create_table "my_table"
        #
        #   table.schema do |schema|
        #     schema.string "first_name", mode: :required
        #     schema.record "cities_lived", mode: :repeated do |cities_lived|
        #       cities_lived.string "place", mode: :required
        #       cities_lived.integer "number_of_years", mode: :required
        #     end
        #   end
        #
        def record name, description: nil, mode: nil
          # TODO: do we need to fail if no block was given?
          fail ArgumentError, "a block is required" unless block_given?

          nested_field = add_field name, :record, description: description,
                                                  mode: mode
          yield nested_field
          nested_field
        end

        # @private
        def changed?
          return false if frozen?
          @original_json != @gapi.to_json
        end

        # @private
        # @param [Google::Apis::BigqueryV2::TableSchema, nil] gapi Returns an
        #   empty schema if nil or no arg is provided. The default is nil.
        #
        def self.from_gapi gapi = nil
          gapi ||= Google::Apis::BigqueryV2::TableSchema.new fields: []
          gapi.fields ||= []
          new.tap do |s|
            s.instance_variable_set :@gapi, gapi
            s.instance_variable_set :@original_json, gapi.to_json
          end
        end

        # @private
        def to_gapi
          @gapi
        end

        # @private
        def == other
          return false unless other.is_a? Schema
          to_gapi.to_json == other.to_gapi.to_json
        end

        protected

        def frozen_check!
          return unless frozen?
          fail ArgumentError, "Cannot modify a frozen schema"
        end

        def add_field name, type, description: nil, mode: :nullable
          frozen_check!

          new_gapi = Google::Apis::BigqueryV2::TableFieldSchema.new(
            name: String(name),
            type: verify_type(type),
            description: description,
            mode: verify_mode(mode),
            fields: [])

          # Remove any existing field of this name
          @gapi.fields ||= []
          @gapi.fields.reject! { |f| f.name == new_gapi.name }

          # Add to the nested fields
          @gapi.fields << new_gapi

          # return the public API object
          Field.from_gapi new_gapi
        end

        def verify_type type
          type = type.to_s.upcase
          unless Field::TYPES.include? type
            fail ArgumentError,
                 "Type '#{type}' not found in #{TYPES.inspect}"
          end
          type
        end

        def verify_mode mode
          mode = :nullable if mode.nil?
          mode = mode.to_s.upcase
          unless Field::MODES.include? mode
            fail ArgumentError "Unable to determine mode for '#{mode}'"
          end
          mode
        end
      end
    end
  end
end
