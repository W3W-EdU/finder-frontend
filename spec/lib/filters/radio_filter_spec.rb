require "spec_helper"

describe Filters::RadioFilter do
  subject(:radio_filter) do
    described_class.new(facet, params)
  end

  let(:facet) { { "allowed_values" => allowed_values, "key" => "radio_key" } }
  let(:params) { nil }
  let(:default_value) { %w[policy_papers] }
  let(:option_lookup) do
    { "open_consultations" => %w[open closed], "policy_papers" => %w[guidance] }
  end
  let(:allowed_values) do
    [
      {
        "label" => "Policy papers",
        "value" => "policy_papers",
        "default" => true,
      },
      {
        "label" => "Consultations (open)",
        "value" => "open_consultations",
      },
      {
        "label" => "Consultations (closed)",
        "value" => "closed_consultations",
      },
    ]
  end

  describe "#active?" do
    context "when no default allowed value is set" do
      let(:allowed_values) { [] }

      context "when params is nil" do
        it "is false" do
          expect(radio_filter).not_to be_active
        end
      end

      context "when params is empty" do
        let(:params) { [] }

        it "is false" do
          expect(radio_filter).not_to be_active
        end
      end
    end

    context "when a default allowed value is set" do
      context "when params is nil" do
        it "is true" do
          expect(radio_filter).to be_active
        end
      end

      context "when params is an array" do
        let(:params) { [] }

        it "is true" do
          expect(radio_filter).to be_active
        end
      end
    end
  end

  describe "#key" do
    context "when a filter_key is present" do
      let(:facet) do
        {
          "filter_key" => "alpha",
          "key" => "beta",
          "allowed_values" => allowed_values,
        }
      end

      it "returns filter_key" do
        expect(radio_filter.key).to eq("alpha")
      end
    end

    context "when a filter_key is not present" do
      let(:facet) do
        {
          "key" => "beta",
          "allowed_values" => allowed_values,
        }
      end

      it "returns key" do
        expect(radio_filter.key).to eq("beta")
      end
    end
  end

  describe "#value" do
    context "without option lookup" do
      context "when an allowed option is provided" do
        let(:params) { "open_consultations" }

        it "returns the option as an array" do
          expect(radio_filter.query_hash).to eq("radio_key" => %w[open_consultations])
        end
      end

      context "when no option is provided and a default value is set" do
        it "returns the default value" do
          expect(radio_filter.query_hash).to eq("radio_key" => default_value)
        end
      end

      context "when the option is not a string and a default value is set" do
        let(:params) { [] }

        it "returns the default value" do
          expect(radio_filter.query_hash).to eq("radio_key" => default_value)
        end
      end

      context "when a disallowed param is provided" do
        let(:params) { "does_not_exist" }

        context "a default option is set" do
          it "returns the default value" do
            expect(radio_filter.query_hash).to eq("radio_key" => default_value)
          end
        end

        context "a default option is NOT provided" do
          let(:allowed_values) { [] }

          it "returns an empty array" do
            expect(radio_filter.query_hash).to eq("radio_key" => [])
          end
        end
      end
    end

    context "with option lookup" do
      let(:facet) do
        {
          "option_lookup" => option_lookup,
          "allowed_values" => allowed_values,
          "key" => "radio_key",
        }
      end

      context "when no option is selected" do
        it "returns the corresponding default values from the option_lookup" do
          expect(radio_filter.query_hash).to eq("radio_key" => %w[guidance])
        end
      end

      context "when a disallowed value is provided" do
        let(:params) { "does_not_exist" }

        context "when a default value is set" do
          it "returns the corresponding default values from the option_lookup" do
            expect(radio_filter.query_hash).to eq("radio_key" => %w[guidance])
          end
        end

        context "when a default value is not set" do
          let(:allowed_values) { [] }

          it "returns an empty array" do
            expect(radio_filter.query_hash).to eq("radio_key" => [])
          end
        end
      end

      context "when an allowed option is selected" do
        let(:params) { "open_consultations" }

        it "returns the corresponding values from the option_lookup" do
          expect(radio_filter.query_hash).to eq("radio_key" => %w[open closed])
        end
      end
    end
  end
end
