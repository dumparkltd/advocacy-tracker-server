class RecommendationRecommendationsController < ApplicationController
  def show
    render json: serialize(@recommendation_recommendation)
  end

  def index
    @recommendation_recommendations = policy_scope(base_object).all
    authorize @recommendation_recommendations
    render json: serialize(@recommendation_recommendations)
  end

  def create
    @recommendation_recommendation = RecommendationRecommendation.new
    @recommendation_recommendation.assign_attributes(permitted_attributes(@recommendation_recommendation))
    authorize @recommendation_recommendation

    if @recommendation_recommendation.save
      render json: @recommendation_recommendation, status: :created, location: @recommendation_recommendation
    else
      render json: @recommendation_recommendation.errors, status: :unprocessable_entity
    end
  end
  
  def update
    head :not_implemented
  end

  def destroy
    @recommendation_recommendation.destroy
  end

  private

  def authorize!
    @recommendation_recommendation = policy_scope(base_object)&.find(params[:id]) if params[:id]

    authorize @recommendation_recommendation || base_object
  end

  def base_object
    RecommendationRecommendation
  end

  def serialize(target, serializer: RecommendationRecommendationSerializer)
    super
  end
end
