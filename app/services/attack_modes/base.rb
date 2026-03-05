# frozen_string_literal: true

module AttackModes
  class Base
    def filter?
      false
    end

    def selector?
      false
    end

    def call(positions)
      raise NotImplementedError, "#{self.class}#call must be implemented"
    end

    private

    def distance_from_origin(position)
      x = position.dig(:position, :x).to_f
      y = position.dig(:position, :y).to_f
      Math.sqrt(x**2 + y**2)
    end
  end
end
