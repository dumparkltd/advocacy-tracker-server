# frozen_string_literal: true
module Api
  module V1
    class StatementsController < ActionController::API
      def index
        statements = Measure
          .public_statements
          .includes(measure_indicators: :indicator)

        topics = Indicator.public_topics.pluck(:id)

        expires_in 0, public: true
        fresh_when(
          etag: statements.maximum(:updated_at),
          last_modified: statements.maximum(:updated_at)
        )
        return if performed?

        cache_key = "public/v1/statements/#{statements.maximum(:updated_at).to_i}/#{statements.count}"
        json = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          statements.order(:code).map do |statement|
            result = {
              gpat_id: statement.id,
              code: statement.code,
              title: statement.title,
              date: statement.date_start,
              url: statement.url,
              quote: statement.quote_api,
              source: statement.source_api,
              updated_at: statement.updated_at
            }

            # Initialize ALL public topic positions as null
            topics.each do |topic_id|
              result["position_t#{topic_id}"] = nil
            end

            # Populate actual position values where they exist
            statement.measure_indicators.each do |measure_indicator|
              if topics.include?(measure_indicator.indicator_id)
                position_value = map_supportlevel_to_position(measure_indicator.supportlevel_id)
                result["position_t#{measure_indicator.indicator_id}"] = position_value
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
