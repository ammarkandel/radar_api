# frozen_string_literal: true

class RadarController < ApplicationController
  def attack
    valid_params = radar_params

    attack_modes = valid_params["attack-mode"] || []
    radar_data   = valid_params["radar"] || []

    resolver = AttackResolver.new(attack_modes, radar_data)
    result   = resolver.call

    Rails.logger.info("[Radar] Mode: #{attack_modes.inspect} | Winner: #{result[:position].inspect}")

    render json: result
  end

  private

  def radar_params
    params.permit(
      { "attack-mode": [] },
      radar: [
        { position: [:x, :y] },
        { targets: [:type, :damage, :number] }
      ]
    )
  end
end
