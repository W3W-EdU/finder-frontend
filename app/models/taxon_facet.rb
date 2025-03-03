class TaxonFacet < FilterableFacet
  LEVEL_ONE_TAXON_KEY = "level_one_taxon".freeze
  LEVEL_TWO_TAXON_KEY = "level_two_taxon".freeze

  def initialize(facet, value_hash)
    @value_hash = value_hash
    super(facet)
  end

  def name
    facet["name"]
  end

  def topics
    level_one_taxons.unshift(default_topic_value)
  end

  def subtopics
    return [default_subtopic_value] unless level_two_taxons

    level_two_taxons.unshift(default_subtopic_value)
  end

  def sentence_fragment
    return nil if selected_level_one_value.nil?

    {
      "type" => "taxon",
      "preposition" => preposition,
      "values" => value_fragments,
      "word_connectors" => and_word_connectors,
    }
  end

  def has_filters?
    selected_level_one_value.present?
  end

  def applied_filters
    return [] unless has_filters?

    level_one_filter = {
      name: "Topic",
      label: selected_level_one_value[:text],
      query_params: {
        # Note that removing a topic should always remove the subtopic too
        LEVEL_ONE_TAXON_KEY => selected_level_one_value[:value],
        LEVEL_TWO_TAXON_KEY => selected_level_two_value&.fetch(:value),
      }.compact,
    }

    if selected_level_two_value
      level_two_filter = {
        name: "Subtopic",
        label: selected_level_two_value[:text],
        query_params: { LEVEL_TWO_TAXON_KEY => selected_level_two_value[:value] },
      }
    end

    [level_one_filter, level_two_filter].compact
  end

  def query_params
    {
      LEVEL_ONE_TAXON_KEY => (selected_level_one_value || {})[:value],
      LEVEL_TWO_TAXON_KEY => (selected_level_two_value || {})[:value],
    }
  end

  def ga4_section
    "Topic"
  end

private

  def value_fragments
    [
      value_fragment(selected_level_one_value, LEVEL_ONE_TAXON_KEY),
      value_fragment(selected_level_two_value, LEVEL_TWO_TAXON_KEY),
    ].compact
  end

  def value_fragment(value, key)
    return nil if value.nil?

    {
      "label" => value[:text],
      "parameter_key" => key,
      "value" => value[:value],
    }
  end

  def level_one_taxons
    @level_one_taxons ||= registry.taxonomy_tree.values.map do |v|
      {
        value: v["content_id"],
        text: v["title"],
        subtopics: v["children"],
        selected: v["content_id"] == @value_hash[LEVEL_ONE_TAXON_KEY],
      }
    end
  end

  def level_two_taxons
    @level_two_taxons ||= level_one_taxons
      .map { |v| v[:subtopics] }
      .compact
      .flatten
      .map do |v|
        {
          text: v["title"],
          value: v["content_id"],
          data_attributes: {
            topic_parent: v["parent"],
          },
          selected: v["content_id"] == @value_hash[LEVEL_TWO_TAXON_KEY],
        }
      end
  end

  def selected_level_two_value
    @selected_level_two_value ||= level_two_taxons.find do |v|
      v[:value] == @value_hash[LEVEL_TWO_TAXON_KEY]
    end
  end

  def selected_level_one_value
    @selected_level_one_value ||= level_one_taxons.find do |v|
      v[:value] == @value_hash[LEVEL_ONE_TAXON_KEY]
    end
  end

  def default_subtopic_value
    { text: "All subtopics", value: "", parent: "" }
  end

  def default_topic_value
    { text: "All topics", value: "" }
  end

  def registry
    @registry ||= Registries::BaseRegistries.new.all["part_of_taxonomy_tree"]
  end
end
