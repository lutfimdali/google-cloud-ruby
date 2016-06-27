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

describe Gcloud::Vision::Annotation::SafeSearch, :mock_vision do
  # Run through JSON to turn all keys to strings...
  let(:gapi) { safe_search_annotation_response }
  let(:safe_search) { Gcloud::Vision::Annotation::SafeSearch.from_gapi gapi }

  it "knows the given attributes" do
    safe_search.wont_be :nil?

    safe_search.wont_be :adult?
    safe_search.wont_be :spoof?
    safe_search.must_be :medical?
    safe_search.must_be :violence?

    safe_search.adult.must_equal "VERY_UNLIKELY"
    safe_search.spoof.must_equal "UNLIKELY"
    safe_search.medical.must_equal "POSSIBLE"
    safe_search.violence.must_equal "LIKELY"
  end
end
