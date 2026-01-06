# frozen_string_literal: true

class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :authenticate_user!, only: [:create, :update, :destroy], unless: :devise_controller?
  before_action :authorize!
  after_action :verify_authorized, except: [:index], unless: :devise_controller?
  after_action :verify_policy_scoped, only: :index, unless: :devise_controller?

  before_action :configure_permitted_parameters, if: :devise_controller?

  before_action :set_paper_trail_whodunnit

  # Allow pundit to authorize a non-logged in user
  def pundit_user
    current_user || User.new
  end

  protected

  def authorize!
    authorize(base_object) if defined?(base_object)
  end

  def serialize(target, serializer:)
    serializer.new(target).serializable_hash.to_json
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: {error: e.message}, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |invalid|
    render json: {error: invalid.record.errors},
      status: :unprocessable_entity
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: {error: e.message}, status: :unprocessable_entity
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  private

  def user_not_authorized
    render json: {error: "not authorized"}, status: :forbidden
  end
end
