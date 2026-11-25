class UserActorsController < ApplicationController
  skip_before_action :authorize!, only: [:create]

  # GET /user_actors
  def index
    @user_actors = policy_scope(base_object).order(created_at: :desc).page(params[:page])
    authorize @user_actors

    render json: serialize(@user_actors)
  end

  # GET /user_actors/1
  def show
    render json: serialize(@user_actor)
  end

  # POST /user_actors
  def create
    @user_actor = base_object.new
    @user_actor.assign_attributes(permitted_attributes(@user_actor))
    authorize @user_actor

    if @user_actor.save
      render json: serialize(@user_actor), status: :created, location: @user_actor
    else
      render json: @user_actor.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /user_actors/1
  def update
    if @user_actor.update!(permitted_attributes(@user_actor))
      render json: serialize(@user_actor)
    end
  end

  # DELETE /user_actors/1
  def destroy
    @user_actor.destroy
  end

  private

  def authorize!
    @user_actor = policy_scope(base_object)&.find(params[:id]) if params[:id]

    authorize @user_actor || base_object
  end

  def base_object
    UserActor
  end

  def serialize(target, serializer: UserActorSerializer)
    super
  end
end
