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


require "gcloud/gce"
require "gcloud/vision/service"
require "gcloud/vision/credentials"
require "gcloud/vision/annotate"
require "gcloud/vision/image"
require "gcloud/vision/annotation"
require "gcloud/errors"

module Gcloud
  module Vision
    ##
    # # Project
    #
    # Google Cloud Vision allows easy integration of vision detection features
    # within developer applications, including image labeling, face and landmark
    # detection, optical character recognition (OCR), and tagging of explicit
    # content.
    #
    # @example
    #   require "gcloud"
    #
    #   gcloud = Gcloud.new
    #   vision = gcloud.vision
    #
    #   image = vision.image "path/to/landmark.jpg"
    #
    #   annotation = vision.annotate image, labels: true
    #
    #   annotation.labels.map &:description
    #   #=> ["stone carving", "ancient history", "statue", "sculpture",
    #   #=>  "monument", "landmark"]
    #
    # See Gcloud#vision
    class Project
      ##
      # @private The Service object.
      attr_accessor :service

      ##
      # @private Creates a new Project instance.
      def initialize project, credentials
        project = project.to_s # Always cast to a string
        fail ArgumentError, "project is missing" if project.empty?
        @service = Service.new project, credentials
      end

      # The Vision project connected to.
      #
      # @example
      #   require "gcloud"
      #
      #   gcloud = Gcloud.new "my-todo-project",
      #                       "/path/to/keyfile.json"
      #   vision = gcloud.vision
      #
      #   vision.project #=> "my-todo-project"
      #
      def project
        service.project
      end

      ##
      # @private Default project.
      def self.default_project
        ENV["VISION_PROJECT"] ||
          ENV["GCLOUD_PROJECT"] ||
          ENV["GOOGLE_CLOUD_PROJECT"] ||
          Gcloud::GCE.project_id
      end

      ##
      # Returns a new image from the given source.
      #
      # Cloud Vision sets upper limits on file size as well as on the total
      # combined size of all images in a request. Reducing your file size can
      # significantly improve throughput; however, be careful not to reduce
      # image quality in the process. See [Best Practices - Image
      # Sizing](https://cloud.google.com/vision/docs/image-best-practices#image_sizing)
      # for current file size limits.
      #
      # Note that an object in Google Cloud Storage is a single entity;
      # permissions affect only that object. "Directory permissions" do not
      # exist (though default bucket permissions do exist). Make sure the code
      # which performs your request has access to that image.
      #
      # @see https://cloud.google.com/vision/docs/image-best-practices Best
      #   Practices
      #
      # @param [String, IO, StringIO, Tempfile, Gcloud::Storage::File] source A
      #   string file path or Cloud Storage URI of the form
      #   `"gs://bucketname/path/to/image_filename"`; or a File, IO, StringIO,
      #   or Tempfile instance; or an instance of Gcloud::Storage::File.
      #
      # @return [Image] An image for the Vision service.
      #
      # @example With a Google Cloud Storage URI:
      #   require "gcloud"
      #
      #   gcloud = Gcloud.new
      #   vision = gcloud.vision
      #
      #   image = vision.image "gs://bucket-name/path_to_image_object"
      #
      # @example With a local file path:
      #   require "gcloud"
      #
      #   gcloud = Gcloud.new
      #   vision = gcloud.vision
      #
      #   image = vision.image "path/to/landmark.jpg"
      #
      def image source
        return source if source.is_a? Image
        Image.from_source source, self
      end

      ##
      # Performs detection of Cloud Vision [features](https://cloud.google.com/vision/reference/rest/v1/images/annotate#Feature)
      # on the given image(s). If no options for features are provided, **all**
      # image detection features will be performed, with a default of `10`
      # results for faces, landmarks, logos, and labels. If any feature option
      # is provided, only the specified feature detections will be performed.
      # Please review [Pricing](https://cloud.google.com/vision/docs/pricing)
      # before use, as a separate charge is incurred for each feature performed
      # on an image.
      #
      # Cloud Vision sets upper limits on file size as well as on the total
      # combined size of all images in a request. Reducing your file size can
      # significantly improve throughput; however, be careful not to reduce
      # image quality in the process. See [Best Practices - Image
      # Sizing](https://cloud.google.com/vision/docs/image-best-practices#image_sizing)
      # for current file size limits.
      #
      # @see https://cloud.google.com/vision/docs/requests-and-responses Cloud
      #   Vision API Requests and Responses
      # @see https://cloud.google.com/vision/reference/rest/v1/images/annotate#AnnotateImageRequest
      #   AnnotateImageRequest
      # @see https://cloud.google.com/vision/docs/pricing Cloud Vision Pricing
      #
      # @param [Image, Object] images The image or images to annotate. This can
      #   be an {Image} instance, or any other type that converts to an {Image}.
      #   See {#image} for details.
      # @param [Boolean, Integer] faces Whether to perform the facial detection
      #   feature. The maximum number of results is configured in
      #   {Gcloud::Vision.default_max_faces}, or may be provided here. Optional.
      # @param [Boolean, Integer] landmarks Whether to perform the landmark
      #   detection feature. The maximum number of results is configured in
      #   {Gcloud::Vision.default_max_landmarks}, or may be provided here.
      #   Optional.
      # @param [Boolean, Integer] logos Whether to perform the logo detection
      #   feature. The maximum number of results is configured in
      #   {Gcloud::Vision.default_max_logos}, or may be provided here. Optional.
      # @param [Boolean, Integer] labels Whether to perform the label detection
      #   feature. The maximum number of results is configured in
      #   {Gcloud::Vision.default_max_labels}, or may be provided here.
      #   Optional.
      # @param [Boolean] text Whether to perform the text (OCR) feature.
      #   Optional.
      # @param [Boolean] safe_search Whether to perform the safe search feature.
      #   Optional.
      # @param [Boolean] properties Whether to perform the image properties
      #   feature (currently, the image's dominant colors.) Optional.
      #
      # @yield [annotate] A block for requests that involve multiple feature
      #   configurations. See {Annotate#annotate}.
      # @yieldparam [Annotate] annotate the Annotate object
      #
      # @return [Annotation, Array<Annotation>] The results for all image
      #   detections, returned as a single {Annotation} instance for one image,
      #   or as an array of {Annotation} instances, one per image, for multiple
      #   images.
      #
      # @example With a single image:
      #   require "gcloud"
      #
      #   gcloud = Gcloud.new
      #   vision = gcloud.vision
      #
      #   image = vision.image "path/to/landmark.jpg"
      #
      #   annotation = vision.annotate image, labels: true
      #
      #   annotation.labels.map &:description
      #   #=> ["stone carving", "ancient history", "statue", "sculpture",
      #   #=>  "monument", "landmark"]
      #
      # @example With multiple images:
      #   require "gcloud"
      #
      #   gcloud = Gcloud.new
      #   vision = gcloud.vision
      #
      #   face_image = vision.image "path/to/face.jpg"
      #   landmark_image = vision.image "path/to/landmark.jpg"
      #
      #   annotations = vision.annotate face_image, landmark_image, labels: true
      #
      #   annotations[0].labels.count #=> 4
      #   annotations[1].labels.count #=> 6
      #
      # @example With multiple images and configurations passed in a block:
      #   require "gcloud"
      #
      #   gcloud = Gcloud.new
      #   vision = gcloud.vision
      #
      #   face_image = vision.image "path/to/face.jpg"
      #   landmark_image = vision.image "path/to/landmark.jpg"
      #   text_image = vision.image "path/to/text.png"
      #
      #   annotations = vision.annotate do |annotate|
      #      annotate.annotate face_image, faces: true, labels: true
      #      annotate.annotate landmark_image, landmarks: true
      #      annotate.annotate text_image, text: true
      #   end
      #
      #   annotations[0].faces.count #=> 1
      #   annotations[0].labels.count #=> 4
      #   annotations[1].landmarks.count #=> 1
      #   annotations[2].text.words.count #=> 28
      #
      # @example Maximum result values can also be provided:
      #   require "gcloud"
      #
      #   gcloud = Gcloud.new
      #   vision = gcloud.vision
      #
      #   image = vision.image "path/to/landmark.jpg"
      #
      #   annotation = vision.annotate image, labels: 3
      #
      #   annotation.labels.map &:description
      #   #=> ["stone carving", "ancient history", "statue"]
      #
      def annotate *images, faces: false, landmarks: false, logos: false,
                   labels: false, text: false, safe_search: false,
                   properties: false
        a = Annotate.new self
        a.annotate(*images, faces: faces, landmarks: landmarks, logos: logos,
                            labels: labels, text: text,
                            safe_search: safe_search, properties: properties)

        yield a if block_given?

        gapi = service.annotate a.requests
        annotations = Array(gapi.responses).map do |g|
          fail Error.from_error(g.error) if g.error
          Annotation.from_gapi g
        end
        return annotations.first if annotations.count == 1
        annotations
      end
      alias_method :mark, :annotate
      alias_method :detect, :annotate

      protected

      ##
      # Raise an error unless an active connection is available.
      def ensure_service!
        fail "Must have active connection" unless service
      end
    end
  end
end
