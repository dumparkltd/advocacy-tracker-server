class IndicatorSerializer
  include FastVersionedSerializer

  attributes(
    :code,
    :code_api,
    :title,
    :description,
    :description_api,
    :reference,
    :draft,
    :manager_id,
    :frequency_months,
    :start_date,
    :repeat,
    :end_date,
    :private,
    :is_archive,
    :public_api,
    :teaser_api,
    :annotation_api,
    :short_api,
    :relationship_updated_at,
    :relationship_updated_by_id
  )

  set_type :indicators
end
