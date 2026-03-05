# frozen_string_literal: true

module AttackModes
  class FurthestFirst < Base
    def selector?
      true
    end

    def call(positions)
      positions.sort_by { |pos| -distance_from_origin(pos) }
    end
  end
end
