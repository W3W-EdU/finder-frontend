module Registries
  class ManualsRegistry < Registry
    include CacheableRegistry

    delegate :[], to: :manuals

    def values
      manuals
    end

    def cache_key
      "registries/manuals"
    end

  private

    def cacheable_data
      manuals_as_hash
    end

    def manuals
      @manuals ||= fetch_from_cache
    end

    def report_error
      GovukStatsd.increment("registries.manuals_api_errors")
    end

    def manuals_as_hash
      GovukStatsd.time("registries.manuals.request_time") do
        fetch_manuals_from_rummager
          .reject { |manual| manual["_id"].empty? || manual["title"].empty? }
          .each_with_object({}) do |manual, manuals|
            manuals[manual["_id"]] = { "title" => manual["title"], "slug" => manual["_id"] }
          end
      end
    end

    def fetch_manuals_from_rummager
      params = {
        filter_document_type: %w[hmrc_manual manual service_manual_homepage service_manual_guide],
        fields: %w[title],
        count: 1500,
      }
      Services.rummager.search(params)["results"]
    end
  end
end
