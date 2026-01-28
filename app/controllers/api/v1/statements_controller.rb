# frozen_string_literal: true
module Api
  module V1
    class StatementsController < ActionController::API
      def index
        statements = Measure
          .public_statements
          .includes(
            measure_indicators: :indicator,
            parent_measure_measures: :other_measure
          )

        topics = Indicator.public_topics

        # Combine all relevant timestamps for cache invalidation
        statement_max = Measure.where(measuretype_id: Measure::STATEMENT_TYPE_ID).maximum(:updated_at)
        relationship_max = statements.maximum(:relationship_updated_at) || Time.at(0)
        topic_max = Indicator.maximum(:updated_at)
        statement_topic_max = statements.joins(:measure_indicators).maximum('measure_indicators.updated_at')
        event_max = Measure.where(measuretype_id: Measure::EVENT_TYPE_ID).maximum(:updated_at)
        measure_measure_max = MeasureMeasure.maximum(:updated_at)

        last_updated = [
          statement_max,
          relationship_max,
          topic_max,
          statement_topic_max,
          event_max,
          measure_measure_max
        ].compact.max

        expires_in 0, public: true

        fresh_when(
          etag: last_updated,
          last_modified: last_updated
        )
        return if performed?

        cache_key = "public/v1/statements/#{last_updated.to_i}/#{statements.count}/#{topics.count}"
        json = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          statements.order(:code).map do |statement|
            parent_event = statement.parent_measures.find { |m| m.event? }

            result = {
              gpat_id: statement.id,
              code: statement.code,
              title: statement.title,
              date: statement.date_start,
              url: statement.url,
              quote: statement.quote_api,
              source: statement.source_api,
              event_id: parent_event&.id,
              updated_at: statement.updated_at
            }

            # Initialize ALL public topic positions as null
            topics.each do |topic|
              result["position_t#{topic.code_api.presence || topic.id}"] = nil
            end

            # Populate actual position values where they exist
            statement.measure_indicators.each do |measure_indicator|
              topic = topics.find { |t| t.id == measure_indicator.indicator_id }
              next unless topic

              topic_key = topic.code_api.presence || topic.id
              position_value = map_supportlevel_to_position(measure_indicator.supportlevel_id)
              result["position_t#{topic_key}"] = position_value
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
