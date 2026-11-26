# frozen_string_literal: true

class ResponseFormatter
  def initialize(position, strategies = [])
    @position = position
    @strategies = strategies
  end

  def call
    targets = strip_humans(@position[:targets])
    targets = apply_target_sorting(targets)

    {
      position: @position[:position],
      targets: targets.map { |target| target[:type] }
    }
  end

  private

  def strip_humans(targets)
    targets.reject { |target| target[:type] == "Human" }
  end

  def apply_target_sorting(targets)
    sorted = targets
    @strategies.each do |strategy|
      sorted = strategy.sort_targets(sorted) if strategy.respond_to?(:sort_targets)
    end

    if @strategies.none? { |strategy| strategy.respond_to?(:sort_targets) }
      sorted = sorted.sort_by { |target| -target[:damage] }
    end

    sorted
  end
end
