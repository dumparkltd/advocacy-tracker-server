class MembershipsController < ApplicationController
  # GET /memberships
  def index
    @memberships = policy_scope(base_object).order(created_at: :desc).page(params[:page])
    authorize @memberships

    render json: serialize(@memberships)
  end

  # GET /memberships/1
  def show
    render json: serialize(@membership)
  end

  # POST /memberships
  def create
    @membership = Membership.new
    @membership.assign_attributes(permitted_attributes(@membership))
    authorize @membership

    if @membership.save
      render json: serialize(@membership), status: :created, location: @membership
    else
      render json: @membership.errors, status: :unprocessable_entity
    end
  end
  
  def update
    head :not_implemented
  end

  # DELETE /memberships/1
  def destroy
    @membership.destroy
  end


  private

  # Use callbacks to share common setup or constraints between actions.
  def authorize!
    @membership = policy_scope(base_object)&.find(params[:id]) if params[:id]

    authorize @membership || base_object
  end

  def base_object
    Membership
  end

  def serialize(target, serializer: MembershipSerializer)
    super
  end
end
