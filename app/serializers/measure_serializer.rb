class MeasureSerializer
  include FastVersionedSerializer

  attributes(
    :amount_comment,
    :amount,
    :code,
    :comment,
    :date_comment,
    :date_end,
    :date_start,
    :description,
    :draft,
    :has_reference_landbased_ml,
    :indicator_summary,
    :measuretype_id,
    :notifications,
    :outcome,
    :parent_id,
    :private,
    :reference_landbased_ml,
    :reference_ml,
    :status_comment,
    :status_lbs_protocol,
    :target_comment,
    :target_date_comment,
    :target_date,
    :title,
    :url,
    :is_archive,
    :is_official,
    :public_api,
    :source_api,
    :quote_api,
    :relationship_updated_at,
    :relationship_updated_by_id
  )

  set_type :measures
end
