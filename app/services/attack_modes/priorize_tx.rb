# frozen_string_literal: true

module AttackModes
  class PriorizeTx < Base
    def filter?
      true
    end

    def call(positions)
      with_tx = positions.select do |pos|
        pos[:targets].any? { |target| target[:type] == "T-X" }
      end

      with_tx.any? ? with_tx : positions
    end

    def sort_targets(targets)
      tx_targets, other_targets = targets.partition { |target| target[:type] == "T-X" }
      by_damage(tx_targets) + by_damage(other_targets)
    end

    private

    def by_damage(targets)
      targets.sort_by { |target| -target[:damage] }
    end
  end
end
