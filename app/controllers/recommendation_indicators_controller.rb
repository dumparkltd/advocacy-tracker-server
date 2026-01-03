class RecommendationIndicatorsController < ApplicationController
  def index
    @recommendation_indicators = policy_scope(base_object).order(created_at: :desc).page(params[:page])
    authorize @recommendation_indicators

    render json: serialize(@recommendation_indicators)
  end

  def show
    render json: serialize(@recommendation_indicator)
  end

  def create
    @recommendation_indicator = RecommendationIndicator.new
    @recommendation_indicator.assign_attributes(permitted_attributes(@recommendation_indicator))
    authorize @recommendation_indicator

    if @recommendation_indicator.save
      render json: serialize(@recommendation_indicator), status: :created, location: @recommendation_indicator
    else
      render json: @recommendation_indicator.errors, status: :unprocessable_entity
    end
  end

  def update
    head :not_implemented
  end

  def destroy
    @recommendation_indicator.destroy
  end

  private

  def authorize!
    @recommendation_indicator = policy_scope(base_object)&.find(params[:id]) if params[:id]

    authorize @recommendation_indicator || base_object
  end

  def base_object
    RecommendationIndicator
  end

  def serialize(target, serializer: RecommendationIndicatorSerializer)
    super
  end
end
