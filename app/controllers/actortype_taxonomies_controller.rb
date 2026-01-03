class ActortypeTaxonomiesController < ApplicationController
  # GET /actortypes_taxonomies/:id
  def show
    @actortype_taxonomy = policy_scope(base_object).find(params[:id])
    authorize @actortype_taxonomy
    render json: serialize(@actortype_taxonomy)
  end

  # GET /actortypes_taxonomies
  def index
    @actortype_taxonomies = policy_scope(base_object).all
    authorize @actortype_taxonomies
    render json: serialize(@actortype_taxonomies)
  end

  def create
    head :not_implemented
  end

  def update
    head :not_implemented
  end

  def destroy
    head :not_implemented
  end

  private

  def base_object
    ActortypeTaxonomy
  end

  def serialize(target, serializer: ActortypeTaxonomySerializer)
    super
  end
end
