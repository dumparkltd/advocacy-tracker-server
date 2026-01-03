class ActorCategoriesController < ApplicationController
  # GET /actor_categories
  def index
    @actor_categories = policy_scope(base_object).order(created_at: :desc).page(params[:page])
    authorize @actor_categories

    render json: serialize(@actor_categories)
  end

  # GET /actor_categories/1
  def show
    render json: serialize(@actor_category)
  end

  # POST /actor_categories
  def create
    @actor_category = ActorCategory.new
    @actor_category.assign_attributes(permitted_attributes(@actor_category))
    authorize @actor_category

    if @actor_category.save
      render json: serialize(@actor_category), status: :created, location: @actor_category
    else
      render json: @actor_category.errors, status: :unprocessable_entity
    end
  end

  # DELETE /actor_categories/1
  def destroy
    @actor_category.destroy
  end

  def update
    head :not_implemented
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def authorize!
    @actor_category = policy_scope(base_object)&.find(params[:id]) if params[:id]

    authorize @actor_category || base_object
  end

  def base_object
    ActorCategory
  end

  def serialize(target, serializer: ActorCategorySerializer)
    super
  end
end
