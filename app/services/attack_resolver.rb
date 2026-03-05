# frozen_string_literal: true

class AttackResolver
  class InvalidModeCombination < StandardError; end
  class NoPositionsError < StandardError; end
  class ValidationError < StandardError; end

  MODE_REGISTRY = {
    "closest-first"   => AttackModes::ClosestFirst,
    "furthest-first"  => AttackModes::FurthestFirst,
    "avoid-crossfire" => AttackModes::AvoidCrossfire,
    "priorize-t-x"    => AttackModes::PriorizeTx
  }.freeze

  CONFLICTING_MODES = [
    Set["closest-first", "furthest-first"]
  ].freeze

  def initialize(attack_modes, radar_data)
    @attack_modes = Array(attack_modes)
    @radar_data   = radar_data
  end

  def call
    validate_input!
    validate_modes!

    positions  = RadarDataNormalizer.new(@radar_data).call
    strategies = resolve_strategies
    positions  = apply_strategies(strategies, positions)

    raise NoPositionsError, "No valid positions after applying attack modes" if positions.empty?

    winning_position = positions.first
    ResponseFormatter.new(winning_position, strategies).call
  end

  private

  def validate_input!
    if @radar_data.nil? || ((@radar_data.respond_to?(:empty?) && @radar_data.empty?) && !@radar_data.is_a?(Hash))
      raise ValidationError, "Radar data is required and must not be empty"
    end

    @radar_data = @radar_data.to_a if @radar_data.respond_to?(:to_a) && !@radar_data.is_a?(Array)
    raise ValidationError, "Radar data is required and must not be empty" if @radar_data.empty?
  end

  def validate_modes!
    CONFLICTING_MODES.each do |conflict_set|
      if conflict_set.subset?(Set.new(@attack_modes))
        raise InvalidModeCombination,
              "Cannot combine #{conflict_set.to_a.join(' and ')}"
      end
    end
  end

  def resolve_strategies
    @attack_modes.map do |mode|
      klass = MODE_REGISTRY[mode]
      raise InvalidModeCombination, "Unknown attack mode: #{mode}" unless klass

      klass.new
    end
  end

  def apply_strategies(strategies, positions)
    strategies.select(&:filter?).each { |f| positions = f.call(positions) }

    selectors = strategies.select(&:selector?)
    selectors = [AttackModes::ClosestFirst.new] if selectors.empty?
    selectors.each { |s| positions = s.call(positions) }

    positions
  end
end
