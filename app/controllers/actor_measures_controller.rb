class ActorMeasuresController < ApplicationController
  skip_before_action :authorize!, only: [:create]
  
  # GET /actor_measures/:id
  def show
    authorize @actor_measure
    render json: serialize(@actor_measure)
  end

  # GET /actor_measures
  def index
    @actor_measures = policy_scope(base_object).all
    authorize @actor_measures
    render json: serialize(@actor_measures)
  end

  # POST /actor_measures
  def create
    @actor_measure = ActorMeasure.new
    @actor_measure.assign_attributes(permitted_attributes(@actor_measure))
    authorize @actor_measure

    if @actor_measure.save
      render json: serialize(@actor_measure), status: :created, location: @actor_measure
    else
      render json: @actor_measure.errors, status: :unprocessable_entity
    end
  end

  # DELETE /actor_measures/1
  def destroy
    @actor_measure.destroy
  end

  # PATCH/PUT /actor_categories/1
  def update
    if @actor_measure.update!(permitted_attributes(@actor_measure))
      render json: serialize(@actor_measure)
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def authorize!
    @actor_measure = policy_scope(base_object)&.find(params[:id]) if params[:id]

    authorize @actor_measure || base_object
  end

  def base_object
    ActorMeasure
  end

  def serialize(target, serializer: ActorMeasureSerializer)
    super
  end
end
