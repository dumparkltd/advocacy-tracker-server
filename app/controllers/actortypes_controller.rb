class ActortypesController < ApplicationController
  before_action :set_and_authorize_actortype, only: [:show]

  # GET /actortypes
  def index
    @actortypes = policy_scope(base_object).order(created_at: :desc).page(params[:page])
    authorize @actortypes

    render json: serialize(@actortypes)
  end

  # GET /actortypes/1
  def show
    render json: serialize(@actortype)
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

  def set_and_authorize_actortype
    @actortype = policy_scope(base_object).find(params[:id])
    authorize @actortype
  end

  def base_object
    Actortype
  end

  def serialize(target, serializer: ActortypeSerializer)
    super
  end
end
