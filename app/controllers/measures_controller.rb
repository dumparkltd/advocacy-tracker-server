# frozen_string_literal: true

class MeasuresController < ApplicationController
  # GET /measures
  def index
    @measures = policy_scope(base_object).order(created_at: :desc).page(params[:page])
    authorize @measures

    render json: serialize(@measures)
  end

  # GET /measures/1
  def show
    render json: serialize(@measure)
  end

  # POST /measures
  def create
    @measure = Measure.new
    @measure.measuretype_id = params.dig(:measure, :measuretype_id) if params.dig(:measure, :measuretype_id)
    @measure.assign_attributes(permitted_attributes(@measure))
    authorize @measure

    if @measure.save
      render json: serialize(@measure), status: :created, location: @measure
    else
      render json: @measure.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /measures/1
  def update
    if params[:measure][:updated_at] && DateTime.parse(params[:measure][:updated_at]).to_i != @measure.updated_at.to_i
      return render json: '{"error":"Record outdated"}', status: :unprocessable_entity
    end

    originally_draft = @measure.draft?
    if @measure.update!(permitted_attributes(@measure))
      send_published_notification!(@measure) if originally_draft && !@measure.draft?
      @measure.queue_task_updated_notifications!(user_id: current_user.id)

      render json: serialize(@measure)
    end
  end

  # DELETE /measures/1
  def destroy
    @measure.destroy
  end

  private

  def base_object
    if params[:category_id]
      Category.find(params[:category_id]).measures
    elsif params[:recommendation_id]
      Recommendation.find(params[:recommendation_id]).measures
    elsif params[:indicator_id]
      Indicator.find(params[:indicator_id]).measures
    else
      Measure
    end
  end

  def send_published_notification!(measure)
    return if measure.draft?

    measure.user_measures.each do |user_measure|
      if user_measure.user.id != current_user.id && user_measure.notify?
        UserMeasureMailer.published(user_measure).deliver_now
      end
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def authorize!
    @measure = policy_scope(base_object)&.find(params[:id]) if params[:id]

    authorize @measure || base_object
  end

  def serialize(target, serializer: MeasureSerializer)
    super
  end
end
