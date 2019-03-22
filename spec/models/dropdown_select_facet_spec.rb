require "spec_helper"

describe DropdownSelectFacet do
  let(:allowed_values) {
    [
      {
        'text' => "Allowed value 1",
        'value' => "allowed-value-1"
      },
      {
        'text' => "Allowed value 2",
        'value' => "allowed-value-2"
      },
      {
        'text' => "Remittals",
        'value' => "remittals"
      }
    ]
  }

  let(:facet_data) {
    {
      'type' => "text",
      'name' => "Test values",
      'key' => "test_values",
      'preposition' => "of value",
      'allowed_values' => allowed_values,
    }
  }


  describe "#sentence_fragment" do
    context "allowed value selected" do
      subject { DropdownSelectFacet.new(facet_data, "allowed-value-1") }

      specify {
        expect(subject.sentence_fragment['preposition']).to eql("of value")
        expect(subject.sentence_fragment['values'].first['label']).to eql("Allowed value 1")
        expect(subject.sentence_fragment['values'].first['parameter_key']).to eql("test_values")
      }
    end

    context "disallowed value selected" do
      subject { DropdownSelectFacet.new(facet_data, "disallowed-value-1") }
      specify { expect(subject.sentence_fragment).to be_nil }
    end
  end
end
