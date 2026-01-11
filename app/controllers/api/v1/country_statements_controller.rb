# frozen_string_literal: true
module Api
  module V1
    class CountryStatementsController < ActionController::API
      def index
        countries = Actor.public_countries
        statements = Measure.public_statements

        # Get all relevant timestamps for cache invalidation
        country_max = Actor.where(actortype_id: Actor::COUNTRY_TYPE_ID).maximum(:updated_at)
        group_max = Actor.where(actortype_id: Actor::GROUP_TYPE_ID).maximum(:updated_at)
        statement_max = Measure.where(measuretype_id: Measure::STATEMENT_TYPE_ID).maximum(:updated_at)
        actor_measure_max = ActorMeasure.maximum(:updated_at)
        membership_max = Membership.maximum(:updated_at)
        country_relationship_max = countries.maximum(:relationship_updated_at) || Time.at(0)
        group_relationship_max = Actor.where(actortype_id: Actor::GROUP_TYPE_ID).maximum(:relationship_updated_at) || Time.at(0)

        last_updated = [
          country_max,
          group_max,
          statement_max,
          actor_measure_max,
          membership_max,
          country_relationship_max,
          group_relationship_max
        ].compact.max

        expires_in 0, public: true
        fresh_when(
          etag: last_updated,
          last_modified: last_updated
        )
        return if performed?

        cache_key = "public/v1/country_statements/#{last_updated.to_i}/#{statements.count}/#{countries.count}"
        json = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          results = []

          # 1. Direct country-statement relationships
          direct_relationships = ActorMeasure
            .joins("INNER JOIN actors ON actors.id = actor_measures.actor_id")
            .joins("INNER JOIN measures ON measures.id = actor_measures.measure_id")
            .where(actors: { id: countries.pluck(:id) })
            .where(measures: { id: statements.pluck(:id) })
            .select(
              'actors.id as country_id',
              'actors.code as country_code',
              'measures.id as statement_id',
              'measures.code as statement_code',
              'measures.date_start as date_start'
            )

          direct_relationships.each do |rel|
            results << {
              country_id: rel.country_id,
              country_code: rel.country_code,
              statement_id: rel.statement_id,
              statement_code: rel.statement_code,
              date_start: rel.date_start
            }
          end

          # 2. Indirect relationships via group memberships
          group_relationships = ActorMeasure
            .joins("INNER JOIN actors AS groups ON groups.id = actor_measures.actor_id")
            .joins("INNER JOIN measures ON measures.id = actor_measures.measure_id")
            .joins("INNER JOIN memberships ON memberships.memberof_id = groups.id")
            .joins("INNER JOIN actors AS countries ON countries.id = memberships.member_id")
            .where(groups: {
              actortype_id: Actor::GROUP_TYPE_ID,
              is_archive: false,
              private: false,
              draft: false
            })
            .where(countries: { id: countries.pluck(:id) })
            .where(measures: { id: statements.pluck(:id) })
            .select(
              'countries.id as country_id',
              'countries.code as country_code',
              'measures.id as statement_id',
              'measures.code as statement_code',
              'measures.date_start as date_start',
              'groups.id as group_id',
              'groups.code as group_code'
            )

          group_relationships.each do |rel|
            # Skip if this country-statement pair already exists as direct relationship
            next if direct_pairs.include?([rel.country_id, rel.statement_id])

            results << {
              country_id: rel.country_id,
              country_code: rel.country_code,
              statement_id: rel.statement_id,
              statement_code: rel.statement_code,
              via_group_id: rel.group_id,
              via_group_code: rel.group_code,
              date_start: rel.date_start
            }
          end

          results.sort_by! { |r| r[:date_start] }

          results.to_json
        end

        render json: json
      end
    end
  end
end
