# frozen_string_literal: true
module Api
  module V1
    class CountriesController < ActionController::API
      def index
        countries = Actor.public_countries

        expires_in 0, public: true
        fresh_when(
          etag: countries.maximum(:updated_at),
          last_modified: countries.maximum(:updated_at)
        )

        return if performed?

        cache_key = "public/v1/countries/#{countries.maximum(:updated_at).to_i}/#{countries.count}"
        json = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          countries.order(:code).map do |country|
            {
              gpat_id: country.id,
              code: country.code,
              name: country.title,
              updated_at: country.updated_at
            }
          end.to_json
        end

        render json: json
      end
    end
  end
end
