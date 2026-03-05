class ApplicationController < ActionController::API
  rescue_from AttackResolver::InvalidModeCombination, with: :render_unprocessable
  rescue_from AttackResolver::NoPositionsError, with: :render_unprocessable
  rescue_from AttackResolver::ValidationError, with: :render_bad_request
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  def render_unprocessable(exception)
    render json: { error: exception.message }, status: :unprocessable_entity
  end

  def render_bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end
end
