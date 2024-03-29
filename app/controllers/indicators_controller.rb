class IndicatorsController < ApplicationController
  # GET /indicators
  def index
    @indicators = policy_scope(base_object).order(created_at: :desc).page(params[:page])
    authorize @indicators

    render json: serialize(@indicators)
  end

  # GET /indicators/1
  def show
    render json: serialize(@indicator)
  end

  # POST /indicators
  def create
    @indicator = Indicator.new
    @indicator.assign_attributes(permitted_attributes(@indicator))
    authorize @indicator

    if @indicator.save
      render json: serialize(@indicator),
        status: :created, location: @indicator
    else
      render json: @indicator.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /indicators/1
  def update
    if params[:indicator][:updated_at] && DateTime.parse(params[:indicator][:updated_at]).to_i != @indicator.updated_at.to_i
      return render json: '{"error":"Record outdated"}', status: :unprocessable_entity
    end

    if @indicator.update!(permitted_attributes(@indicator))
      render json: serialize(@indicator)
    end
  end

  # DELETE /indicators/1
  def destroy
    @indicator.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def authorize!
    @indicator = policy_scope(base_object)&.find(params[:id]) if params[:id]

    authorize @indicator || base_object
  end

  def base_object
    if params[:measure_id]
      Measure.find(params[:measure_id]).indicators
    else
      Indicator
    end
  end

  def serialize(target, serializer: IndicatorSerializer)
    super
  end
end
