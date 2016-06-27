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

describe Gcloud::Storage::File, :signed_url, :mock_storage do
  let(:bucket_name) { "bucket" }
  let(:bucket_gapi) { Google::Apis::StorageV1::Bucket.from_json random_bucket_hash(bucket_name).to_json }
  let(:bucket) { Gcloud::Storage::Bucket.from_gapi bucket_gapi, storage.service }

  let(:file_name) { "file.ext" }
  let(:file_gapi) { Google::Apis::StorageV1::Object.from_json random_file_hash(bucket.name, file_name).to_json }
  let(:file) { Gcloud::Storage::File.from_gapi file_gapi, storage.service }

  it "uses the credentials' issuer and signing_key to generate signed_url" do
    signing_key_mock = Minitest::Mock.new
    signing_key_mock.expect :sign, "native-signature", [OpenSSL::Digest::SHA256, String]
    credentials.issuer = "native_client_email"
    credentials.signing_key = signing_key_mock

    signed_url = file.signed_url

    signed_url_params = CGI::parse(URI(signed_url).query)
    signed_url_params["GoogleAccessId"].must_equal ["native_client_email"]
    signed_url_params["Signature"].must_equal [Base64.encode64("native-signature").delete("\n")]

    signing_key_mock.verify
  end

  it "allows issuer and signing_key to be passed in as options" do
    credentials.issuer = "native_client_email"
    credentials.signing_key = PoisonSigningKey.new

    signing_key_mock = Minitest::Mock.new
    signing_key_mock.expect :sign, "option-signature", [OpenSSL::Digest::SHA256, String]

    signed_url = file.signed_url issuer: "option_issuer",
                                 signing_key: signing_key_mock

    signed_url_params = CGI::parse(URI(signed_url).query)
    signed_url_params["GoogleAccessId"].must_equal ["option_issuer"]
    signed_url_params["Signature"].must_equal [Base64.encode64("option-signature").delete("\n")]

    signing_key_mock.verify
  end

  it "allows client_email and private to be passed in as options" do
    credentials.issuer = "native_client_email"
    credentials.signing_key = PoisonSigningKey.new

    signing_key_mock = Minitest::Mock.new
    signing_key_mock.expect :sign, "option-signature", [OpenSSL::Digest::SHA256, String]

    OpenSSL::PKey::RSA.stub :new, signing_key_mock do

      signed_url = file.signed_url client_email: "option_client_email",
                                   private_key: "option_private_key"

      signed_url_params = CGI::parse(URI(signed_url).query)
      signed_url_params["GoogleAccessId"].must_equal ["option_client_email"]
      signed_url_params["Signature"].must_equal [Base64.encode64("option-signature").delete("\n")]

    end

    signing_key_mock.verify
  end

  it "raises when missing issuer" do
    credentials.issuer = nil
    credentials.signing_key = PoisonSigningKey.new

    expect {
      file.signed_url
    }.must_raise Gcloud::Storage::SignedUrlUnavailable
  end

  it "raises when missing signing_key" do
    credentials.issuer = "native_issuer"
    credentials.signing_key = nil

    expect {
      file.signed_url
    }.must_raise Gcloud::Storage::SignedUrlUnavailable
  end

  class PoisonSigningKey
    def sign kind, sig
      raise "The wrong signing_key was used"
    end
  end
end
