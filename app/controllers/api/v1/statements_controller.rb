# frozen_string_literal: true
module Api
  module V1
    class StatementsController < ActionController::API
      def index
        measures = Measure.where(
          measuretype_id: 1,
          public_api: true,
          is_archive: false,
          private: false,
          draft: false
        ).includes(measure_indicators: :indicator)

        public_topics = Indicator.where(
          public_api: true,
          is_archive: false,
          private: false,
          draft: false
        ).pluck(:id)

        expires_in 0, public: true
        fresh_when(
          etag: measures.maximum(:updated_at),
          last_modified: measures.maximum(:updated_at)
        )

        cache_key = "public/v1/statements/#{measures.maximum(:updated_at).to_i}/#{measures.count}"
        json = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          measures.order(:code).map do |measure|
            result = {
              title: measure.title,
              date: measure.date_start,
              url: measure.url,
              quote_api: measure.quote_api,
              source_api: measure.source_api,
              updated_at: measure.updated_at
            }

            # Initialize ALL public topic positions as null
            public_topics.each do |topic_id|
              result["position_t#{topic_id}"] = nil
            end

            # Populate actual position values where they exist
            measure.measure_indicators.each do |mi|
              if public_topics.include?(mi.indicator_id)
                position_value = map_supportlevel_to_position(mi.supportlevel_id)
                result["position_t#{mi.indicator_id}"] = position_value
              end
            end

            result
          end.to_json
        end

        render json: json
      end

      private

      def map_supportlevel_to_position(supportlevel_id)
        case supportlevel_id
        when 1 then 3 # "strong" > "Called for"
        when 2 then 2 # "quite positive" > "Supported"
        when 3 then 0 # "on the fence" > "no support"
        when 4 then -1 # "sceptical" > "no support*"
        when 5 then -1 # "opponent" > "no support*"
        when 99 then 0 # "no statement" > "no support"
        else 0 # "no support"
        end
      end
    end
  end
end
