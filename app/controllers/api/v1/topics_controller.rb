# frozen_string_literal: true

module Api
  module V1
    class TopicsController < ActionController::API
      def index
        topics = Indicator.public_topics

        last_updated = Indicator.maximum(:updated_at)
        # Always validate during development (0 minutes cache)
        expires_in 0, public: true

        fresh_when(
          etag: last_updated,
          last_modified: last_updated
        )
        return if performed?

        # Rails cache layer (stays fast even with 0 minute browser cache)
        cache_key = "public/v1/topics/#{last_updated.to_i}/#{topics.count}"
        json = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          topics.order(:code).map do |topic|
            {
              gpat_id: topic.id,
              code: topic.code,
              code_api: topic.code_api,
              title: topic.title,
              description: topic.description_api,
              teaser: topic.teaser_api,
              annotation: topic.annotation_api,
              short_title: topic.short_api,
              updated_at: topic.updated_at
            }
          end.to_json
        end

        render json: json
      end
    end
  end
end
