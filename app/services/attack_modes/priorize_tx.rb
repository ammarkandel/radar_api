# frozen_string_literal: true

module AttackModes
  class PriorizeTx < Base
    def filter?
      true
    end

    def call(positions)
      with_tx = positions.select do |pos|
        pos[:targets].any? { |t| t[:type] == "T-X" }
      end

      with_tx.any? ? with_tx : positions
    end

    def sort_targets(targets)
      tx_targets    = targets.select { |t| t[:type] == "T-X" }
                             .sort_by { |t| -(t[:damage]) }
      other_targets = targets.reject { |t| t[:type] == "T-X" }
                             .sort_by { |t| -(t[:damage]) }
      tx_targets + other_targets
    end
  end
end
