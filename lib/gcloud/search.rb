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

require "gcloud"

#--
# Google Cloud Search
module Gcloud
  ##
  # Creates a new +Project+ instance connected to the Search service.
  # Each call creates a new connection.
  #
  # === Parameters
  #
  # +project+::
  #   Identifier for a Search project. If not present, the default project for
  #   the credentials is used. (+String+)
  # +keyfile+::
  #   Keyfile downloaded from Google Cloud. If file path the file must be
  #   readable. (+String+ or +Hash+)
  # +options+::
  #   An optional Hash for controlling additional behavior. (+Hash+)
  # <code>options[:scope]</code>::
  #   The OAuth 2.0 scopes controlling the set of resources and operations that
  #   the connection can access. See {Using OAuth 2.0 to Access Google
  #   APIs}[https://developers.google.com/identity/protocols/OAuth2]. (+String+
  #   or +Array+)
  #
  #   The default scope is:
  #
  #   TODO insert scope string
  #
  # === Returns
  #
  # Gcloud::Search::Project
  #
  # === Example
  #
  #   require "gcloud"
  #
  #   search = Gcloud.search "my-search-project",
  #                    "/path/to/keyfile.json"
  #
  #   zone = search.zone "example-com"
  #
  def self.search project = nil, keyfile = nil, options = {}
    # project ||= Gcloud::Search::Project.default_project
    # if keyfile.nil?
    #   credentials = Gcloud::Search::Credentials.default options
    # else
    #   credentials = Gcloud::Search::Credentials.new keyfile, options
    # end
    # Gcloud::Search::Project.new project, credentials
  end

  ##
  # = Google Cloud Search
  #
  # Google Cloud Search allows an application to quickly perform full-text and
  # geo-spatial searches without having to spin up instances
  # and without the hassle of managing and maintaining a search service.
  #
  # Cloud Search provides a model for indexing documents containing structured data,
  # with documents and indexes saved to a separate persistent store optimized
  # for search operations.
  #
  # The API supports full text matching on string fields and allows indexing
  # any number of documents in any number of indexes.
  #
  # Gcloud's goal is to provide an API that is familiar and comfortable to
  # Rubyists. Authentication is handled by Gcloud#search. You can provide
  # the project and credential information to connect to the Cloud Search service,
  # or if you are running on Google Compute Engine this configuration is taken
  # care of for you. You can read more about the options for connecting in the
  # {Authentication Guide}[link:AUTHENTICATION.md].
  #
  # == Listing Indexes
  #
  # Indexes are searchable collections of documents.
  #
  # List all indexes in the project:
  #
  #   require "gcloud"
  #
  #   gcloud = Gcloud.new
  #   search = gcloud.search
  #
  #   indexes = search.indexes  # API call
  #   indexes.each do |index|
  #     puts index.name
  #     index.fields.each do |field|
  #       puts "- #{field.name}"
  #     end
  #   end
  #
  # Create a new index:
  #
  #   require "gcloud"
  #
  #   gcloud = Gcloud.new
  #   search = gcloud.search
  #
  #   new_index = search.index "products"
  #
  # Indexes cannot be created, updated, or deleted directly on the server:
  # they are derived from the documents which are created "within" them.
  #
  # == Documents
  #
  # Create a document instance, which is not yet added to its index on
  # the server. You can provide your own unique document id (as shown below),
  # which can be handy for updating a document (actually replacing it) without
  # having to retrieve it first through a query in order to obtain its id.
  #
  #   require "gcloud"
  #
  #   gcloud = Gcloud.new
  #   search = gcloud.search
  #
  #   index = search.index "products"
  #   document = index.document "product-sku-000001"
  #   document.exists?  # API call
  #   #=> False
  #   document.rank
  #   #=> None
  #
  # Add one or more fields to the document. Since the document's id is not
  # a field and thus is not returned in query results, it is a good idea to also
  # set the value in a field when providing your own document id.
  #
  #   field = document.field "sku"
  #   field.add_value "product-sku-000001", tokenization: :atom
  #
  # Save the document into the index:
  #
  #   document.create  # API call
  #   document.exists  # API call
  #   #=> True
  #   document.rank      # set by the server
  #   #=> 1443648166
  #
  # List all documents in an index:
  #
  #   require "gcloud"
  #
  #   gcloud = Gcloud.new
  #   search = gcloud.search
  #
  #   documents = index.documents  # API call
  #   documents.map &:id #=> ["product-sku-000001"]
  #
  # Delete a document from its index:
  #
  #   require "gcloud"
  #
  #   gcloud = Gcloud.new
  #   search = gcloud.search
  #
  #   document = index.document "product-sku-000001"
  #   document.exists  # API call
  #   #=> True
  #   document.delete  # API call
  #   document.exists  # API call
  #   #=> False
  #
  # To update a document in place after manipulating its fields or rank, just
  # recreate it:  E.g.:
  #
  #   require "gcloud"
  #
  #   gcloud = Gcloud.new
  #   search = gcloud.search
  #
  #   document = index.document "product-sku-000001"
  #   document.exists  # API call
  #   #=> True
  #   document.rank = 12345
  #   field = document.field "price"
  #   field.add_value 24.95
  #   document.create  # API call
  #
  # == Fields
  #
  # Fields belong to documents and are the data that actually gets searched.
  #
  # Each field can have multiple values, which can be of the following types:
  #
  # - String
  # - Number
  # - Time
  # - Geovalue
  #
  # String values can be tokenized using one of three different types of
  # tokenization, which can be passed when the value is added:
  #
  # - :atom means "don't tokenize this string", treat it as one
  #   thing to compare against.
  #
  # - :text means "treat this string as normal text" and split words
  #   apart to be compared against.
  #
  # - :html means "treat this string as HTML", understanding the
  #   tags, and treating the rest of the content like Text.
  #
  # More than one value can be added to a field.
  #
  #   require "gcloud"
  #
  #   gcloud = Gcloud.new
  #   search = gcloud.search
  #
  #   index = search.index "products"
  #   document = index.document "product-sku-000001"
  #   field = document.field "description"
  #   field.add_value "The best T-shirt ever.", tokenization: :text
  #   field.add_value "<p>The best T-shirt ever.</p>", tokenization: :html
  #
  # == Searching
  #
  # After populating an index with documents, search through them by
  # issuing a search query:
  #
  #   require "gcloud"
  #
  #   gcloud = Gcloud.new
  #   search = gcloud.search
  #
  #   index = search.index "products"
  #   query = search.query "t-shirt"
  #   matching_documents = index.search query  # API call
  #   matching_documents.map &:id #=> ["product-sku-000001"]
  #
  # By default, all queries are sorted by the rank value set when the
  # document was created. For more information see the {REST API
  # documentation for Document.rank}[https://cloud.google.com/search/reference/rest/v1/projects/indexes/documents#resource_representation.google.cloudsearch.v1.Document.rank].
  #
  # To sort differently, use the :order_by option:
  #
  #   require "gcloud"
  #
  #   gcloud = Gcloud.new
  #   search = gcloud.search
  #
  #   ordered = search.query "t-shirt", order_by: ["price", "-avg_review"]
  #
  # Note that the - character before avg_review means that this query will
  # be sorted ascending by price and then descending by avg_review.
  #
  # To limit the fields to be returned in the match, use the :fields option:
  #
  #   require "gcloud"
  #
  #   gcloud = Gcloud.new
  #   search = gcloud.search
  #
  #   projected = search.query "t-shirt", fields: ["sku", "price"]
  module Search
  end
end
