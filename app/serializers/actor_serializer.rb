class ActorSerializer
  include FastVersionedSerializer

  attributes(
    :activity_summary,
    :actortype_id,
    :address,
    :code,
    :description,
    :draft,
    :email,
    :gdp,
    :manager_id,
    :parent_id,
    :phone,
    :population,
    :prefix,
    :private,
    :title,
    :url,
    :is_archive,
    :public_api,
    :relationship_updated_at,
    :relationship_updated_by_id
  )

  set_type :actors
end
