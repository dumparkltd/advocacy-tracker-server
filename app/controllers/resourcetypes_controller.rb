class ResourcetypesController < ApplicationController
  before_action :set_and_authorize_resourcetype, only: [:show]

  # GET /resourcetypes
  def index
    @resourcetypes = policy_scope(base_object).order(created_at: :desc).page(params[:page])
    authorize @resourcetypes

    render json: serialize(@resourcetypes)
  end

  # GET /resourcetypes/1
  def show
    render json: serialize(@resourcetype)
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

  def set_and_authorize_resourcetype
    @resourcetype = policy_scope(base_object).find(params[:id])
    authorize @resourcetype
  end

  def base_object
    Resourcetype
  end

  def serialize(target, serializer: ResourcetypeSerializer)
    super
  end
end
