# frozen_string_literal: true

class RadarDataNormalizer
  def initialize(radar_data)
    @radar_data = radar_data
  end

  def call
    @radar_data.map { |entry| normalize_entry(entry) }
  end

  private

  def normalize_entry(entry)
    entry = entry.to_unsafe_h if entry.respond_to?(:to_unsafe_h)
    entry = entry.deep_symbolize_keys if entry.respond_to?(:deep_symbolize_keys)

    {
      position: extract_position(entry),
      targets: extract_targets(entry)
    }
  end

  def extract_position(entry)
    {
      x: coordinate(entry.dig(:position, :x)),
      y: coordinate(entry.dig(:position, :y))
    }
  end

  # Keeps whole numbers as integers (so responses stay `{ "x": 0, "y": 40 }`)
  # but no longer truncates decimals, which used to change distance ranking.
  def coordinate(value)
    number = Float(value, exception: false)
    return 0 unless number&.finite?

    number == number.to_i ? number.to_i : number
  end

  def extract_targets(entry)
    targets = entry[:targets]
    targets = [ targets ] if targets.is_a?(Hash)
    targets = [] unless targets.is_a?(Array)

    targets.map do |target|
      target = target.to_unsafe_h if target.respond_to?(:to_unsafe_h)
      target = target.deep_symbolize_keys if target.respond_to?(:deep_symbolize_keys)
      { type: target[:type].to_s, damage: target[:damage].to_i }
    end
  end
end
