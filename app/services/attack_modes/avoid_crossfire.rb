# frozen_string_literal: true

module AttackModes
  class AvoidCrossfire < Base
    def filter?
      true
    end

    def call(positions)
      positions.reject do |pos|
        pos[:targets].any? { |t| t[:type] == "Human" }
      end
    end
  end
end
