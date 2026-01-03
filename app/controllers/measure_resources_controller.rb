class MeasureResourcesController < ApplicationController
  # GET /measure_resources
  def index
    @measure_resources = policy_scope(base_object).order(created_at: :desc).page(params[:page])
    authorize @measure_resources

    render json: serialize(@measure_resources)
  end

  # GET /measure_resources/1
  def show
    render json: serialize(@measure_resource)
  end

  # POST /measure_resources
  def create
    @measure_resource = MeasureResource.new
    @measure_resource.assign_attributes(permitted_attributes(@measure_resource))
    authorize @measure_resource

    if @measure_resource.save
      render json: serialize(@measure_resource), status: :created, location: @measure_resource
    else
      render json: @measure_resource.errors, status: :unprocessable_entity
    end
  end
  
  def update
    head :not_implemented
  end

  # DELETE /measure_resources/1
  def destroy
    @measure_resource.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def authorize!
    @measure_resource = policy_scope(base_object)&.find(params[:id]) if params[:id]

    authorize @measure_resource || base_object
  end

  def base_object
    MeasureResource
  end

  def serialize(target, serializer: MeasureResourceSerializer)
    super
  end
end
