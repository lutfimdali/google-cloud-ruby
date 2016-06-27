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
require "pathname"
describe Gcloud::Vision::Image, :faces, :mock_vision do
  let(:filepath) { "acceptance/data/face.jpg" }
  let(:image)    { vision.image filepath }

  it "detects multiple faces" do
    feature = Google::Apis::VisionV1::Feature.new(type: "FACE_DETECTION", max_results: 10)
    req = Google::Apis::VisionV1::BatchAnnotateImagesRequest.new(
      requests: [
        Google::Apis::VisionV1::AnnotateImageRequest.new(
          image: Google::Apis::VisionV1::Image.new(content: File.read(filepath, mode: "rb")),
          features: [feature]
        )
      ]
    )
    mock = Minitest::Mock.new
    mock.expect :annotate_image, faces_response_gapi, [req]

    vision.service.mocked_service = mock
    faces = image.faces 10
    mock.verify

    faces.count.must_equal 5
  end

  it "detects multiple faces without specifying a count" do
    feature = Google::Apis::VisionV1::Feature.new(type: "FACE_DETECTION", max_results: 100)
    req = Google::Apis::VisionV1::BatchAnnotateImagesRequest.new(
      requests: [
        Google::Apis::VisionV1::AnnotateImageRequest.new(
          image: Google::Apis::VisionV1::Image.new(content: File.read(filepath, mode: "rb")),
          features: [feature]
        )
      ]
    )
    mock = Minitest::Mock.new
    mock.expect :annotate_image, faces_response_gapi, [req]

    vision.service.mocked_service = mock
    faces = image.faces
    mock.verify

    faces.count.must_equal 5
  end

  it "detects a face" do
    feature = Google::Apis::VisionV1::Feature.new(type: "FACE_DETECTION", max_results: 1)
    req = Google::Apis::VisionV1::BatchAnnotateImagesRequest.new(
      requests: [
        Google::Apis::VisionV1::AnnotateImageRequest.new(
          image: Google::Apis::VisionV1::Image.new(content: File.read(filepath, mode: "rb")),
          features: [feature]
        )
      ]
    )
    mock = Minitest::Mock.new
    mock.expect :annotate_image, face_response_gapi, [req]

    vision.service.mocked_service = mock
    face = image.face
    mock.verify

    face.wont_be :nil?
  end

  def face_response_gapi
    Google::Apis::VisionV1::BatchAnnotateImagesResponse.new(
      responses: [
        Google::Apis::VisionV1::AnnotateImageResponse.new(
          face_annotations: [
            face_annotation_response
          ]
        )
      ]
    )
  end

  def faces_response_gapi
    Google::Apis::VisionV1::BatchAnnotateImagesResponse.new(
      responses: [
        Google::Apis::VisionV1::AnnotateImageResponse.new(
          face_annotations: [
            face_annotation_response,
            face_annotation_response,
            face_annotation_response,
            face_annotation_response,
            face_annotation_response
          ]
        )
      ]
    )
  end
end
