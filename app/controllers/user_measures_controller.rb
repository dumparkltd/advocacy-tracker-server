class UserMeasuresController < ApplicationController
  skip_before_action :authorize!, only: [:create]
  
  # GET /user_measures
  def index
    @user_measures = policy_scope(base_object).order(created_at: :desc).page(params[:page])
    authorize @user_measures

    render json: serialize(@user_measures)
  end

  # GET /user_measures/1
  def show
    render json: serialize(@user_measure)
  end

  # POST /user_measures
  def create
    @user_measure = base_object.new
    @user_measure.assign_attributes(permitted_attributes(@user_measure))
    authorize @user_measure

    if @user_measure.save
      if @user_measure.user.id != current_user.id && @user_measure.notify?
        UserMeasureMailer.created(@user_measure).deliver_now
      end

      render json: serialize(@user_measure), status: :created, location: @user_measure
    else
      render json: @user_measure.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /user_measures/1
  def update
    if @user_measure.update!(permitted_attributes(@user_measure))
      render json: serialize(@user_measure)
    end
  end

  # DELETE /user_measures/1
  def destroy
    @user_measure.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def authorize!
    @user_measure = policy_scope(base_object).find(params[:id]) if params[:id]

    authorize @user_measure || base_object
  end

  def base_object
    UserMeasure
  end

  def serialize(target, serializer: UserMeasureSerializer)
    super
  end
end
