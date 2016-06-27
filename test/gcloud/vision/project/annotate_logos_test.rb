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

require "helper"

describe Gcloud::Vision::Project, :annotate, :logos, :mock_vision do
  let(:filepath) { "acceptance/data/logo.jpg" }

  it "detects logo detection" do
    feature = Google::Apis::VisionV1::Feature.new(type: "LOGO_DETECTION", max_results: 1)
    req = Google::Apis::VisionV1::BatchAnnotateImagesRequest.new(
      requests: [
        Google::Apis::VisionV1::AnnotateImageRequest.new(
          image: Google::Apis::VisionV1::Image.new(content: File.read(filepath, mode: "rb")),
          features: [feature]
        )
      ]
    )
    mock = Minitest::Mock.new
    mock.expect :annotate_image, logo_response_gapi, [req]

    vision.service.mocked_service = mock
    annotation = vision.annotate filepath, logos: 1
    mock.verify

    annotation.wont_be :nil?
    annotation.logo.wont_be :nil?
  end

  it "detects logo detection using mark alias" do
    feature = Google::Apis::VisionV1::Feature.new(type: "LOGO_DETECTION", max_results: 1)
    req = Google::Apis::VisionV1::BatchAnnotateImagesRequest.new(
      requests: [
        Google::Apis::VisionV1::AnnotateImageRequest.new(
          image: Google::Apis::VisionV1::Image.new(content: File.read(filepath, mode: "rb")),
          features: [feature]
        )
      ]
    )
    mock = Minitest::Mock.new
    mock.expect :annotate_image, logo_response_gapi, [req]

    vision.service.mocked_service = mock
    annotation = vision.mark filepath, logos: 1
    mock.verify

    annotation.wont_be :nil?
    annotation.logo.wont_be :nil?
  end

  it "detects logo detection using detect alias" do
    feature = Google::Apis::VisionV1::Feature.new(type: "LOGO_DETECTION", max_results: 1)
    req = Google::Apis::VisionV1::BatchAnnotateImagesRequest.new(
      requests: [
        Google::Apis::VisionV1::AnnotateImageRequest.new(
          image: Google::Apis::VisionV1::Image.new(content: File.read(filepath, mode: "rb")),
          features: [feature]
        )
      ]
    )
    mock = Minitest::Mock.new
    mock.expect :annotate_image, logo_response_gapi, [req]

    vision.service.mocked_service = mock
    annotation = vision.detect filepath, logos: 1
    mock.verify

    annotation.wont_be :nil?
    annotation.logo.wont_be :nil?
  end

  it "detects logo detection on multiple images" do
    feature = Google::Apis::VisionV1::Feature.new(type: "LOGO_DETECTION", max_results: 1)
    req = Google::Apis::VisionV1::BatchAnnotateImagesRequest.new(
      requests: [
        Google::Apis::VisionV1::AnnotateImageRequest.new(
          image: Google::Apis::VisionV1::Image.new(content: File.read(filepath, mode: "rb")),
          features: [feature]
        ),
        Google::Apis::VisionV1::AnnotateImageRequest.new(
          image: Google::Apis::VisionV1::Image.new(content: File.read(filepath, mode: "rb")),
          features: [feature]
        )
      ]
    )
    mock = Minitest::Mock.new
    mock.expect :annotate_image, logos_response_gapi, [req]

    vision.service.mocked_service = mock
    annotations = vision.annotate filepath, filepath, logos: 1
    mock.verify

    annotations.count.must_equal 2
    annotations.first.logo.wont_be :nil?
    annotations.last.logo.wont_be :nil?
  end

  it "uses the default configuration" do
    feature = Google::Apis::VisionV1::Feature.new(type: "LOGO_DETECTION", max_results: Gcloud::Vision.default_max_logos)
    req = Google::Apis::VisionV1::BatchAnnotateImagesRequest.new(
      requests: [
        Google::Apis::VisionV1::AnnotateImageRequest.new(
          image: Google::Apis::VisionV1::Image.new(content: File.read(filepath, mode: "rb")),
          features: [feature]
        )
      ]
    )
    mock = Minitest::Mock.new
    mock.expect :annotate_image, logo_response_gapi, [req]

    vision.service.mocked_service = mock
    annotation = vision.annotate filepath, logos: true
    mock.verify

    annotation.wont_be :nil?
    annotation.logo.wont_be :nil?
  end

  it "uses the default configuration when given a truthy value" do
    feature = Google::Apis::VisionV1::Feature.new(type: "LOGO_DETECTION", max_results: Gcloud::Vision.default_max_logos)
    req = Google::Apis::VisionV1::BatchAnnotateImagesRequest.new(
      requests: [
        Google::Apis::VisionV1::AnnotateImageRequest.new(
          image: Google::Apis::VisionV1::Image.new(content: File.read(filepath, mode: "rb")),
          features: [feature]
        )
      ]
    )
    mock = Minitest::Mock.new
    mock.expect :annotate_image, logo_response_gapi, [req]

    vision.service.mocked_service = mock
    annotation = vision.annotate filepath, logos: "9999"
    mock.verify

    annotation.wont_be :nil?
    annotation.logo.wont_be :nil?
  end

  it "uses the updated configuration" do
    feature = Google::Apis::VisionV1::Feature.new(type: "LOGO_DETECTION", max_results: 25)
    req = Google::Apis::VisionV1::BatchAnnotateImagesRequest.new(
      requests: [
        Google::Apis::VisionV1::AnnotateImageRequest.new(
          image: Google::Apis::VisionV1::Image.new(content: File.read(filepath, mode: "rb")),
          features: [feature]
        )
      ]
    )
    mock = Minitest::Mock.new
    mock.expect :annotate_image, logo_response_gapi, [req]

    vision.service.mocked_service = mock
    Gcloud::Vision.stub :default_max_logos, 25 do
      annotation = vision.annotate filepath, logos: true
      annotation.wont_be :nil?
      annotation.logo.wont_be :nil?
    end
    mock.verify
  end

  def logo_response_gapi
    MockVision::API::BatchAnnotateImagesResponse.new(
      responses: [
        MockVision::API::AnnotateImageResponse.new(
          logo_annotations: [
            logo_annotation_response
          ]
        )
      ]
    )
  end

  def logos_response_gapi
    MockVision::API::BatchAnnotateImagesResponse.new(
      responses: [
        MockVision::API::AnnotateImageResponse.new(
          logo_annotations: [
            logo_annotation_response
          ]
        ),
        MockVision::API::AnnotateImageResponse.new(
          logo_annotations: [
            logo_annotation_response
          ]
        )
      ]
    )
  end

end
