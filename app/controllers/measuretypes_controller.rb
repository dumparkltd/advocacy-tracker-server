class MeasuretypesController < ApplicationController
  before_action :set_and_authorize_measuretype, only: [:show]

  # GET /measuretypes
  def index
    @measuretypes = policy_scope(base_object).order(created_at: :desc).page(params[:page])
    authorize @measuretypes

    render json: serialize(@measuretypes)
  end

  # GET /measuretypes/1
  def show
    render json: serialize(@measuretype)
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

  def set_and_authorize_measuretype
    @measuretype = policy_scope(base_object).find(params[:id])
    authorize @measuretype
  end

  def base_object
    Measuretype
  end

  def serialize(target, serializer: MeasuretypeSerializer)
    super
  end
end
