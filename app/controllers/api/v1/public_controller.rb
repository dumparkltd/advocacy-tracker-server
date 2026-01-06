# frozen_string_literal: true

module Api
  module V1
    class PublicController < ActionController::API
      skip_before_action :authenticate_user!

      def topics
        indicators = Indicator.where(
          public_api: true,
          is_archive: false,
          private: false,
          draft: false
        )

        # Always validate during development (0 minutes cache)
        expires_in 0, public: true

        fresh_when(
          etag: indicators.maximum(:updated_at),
          last_modified: indicators.maximum(:updated_at)
        )

        # Rails cache layer (stays fast even with 0 minute browser cache)
        cache_key = "public/topics/#{indicators.maximum(:updated_at).to_i}/#{indicators.count}"
        json = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          indicators.order(:code).as_json(
            only: [
              :id,
              :code,
              :title,
              :description,
              :teaser_api,
              :annotation_api,
              :short_api,
              :updated_at,
            ]
          )
        end

        render json: json
      end
    end
  end
end
