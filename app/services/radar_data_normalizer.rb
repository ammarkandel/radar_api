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
      x: entry.dig(:position, :x).to_i,
      y: entry.dig(:position, :y).to_i
    }
  end

  def extract_targets(entry)
    targets = entry[:targets]
    targets = [targets] if targets.is_a?(Hash)
    targets = [] unless targets.is_a?(Array)

    targets.map do |t|
      t = t.to_unsafe_h if t.respond_to?(:to_unsafe_h)
      t = t.deep_symbolize_keys if t.respond_to?(:deep_symbolize_keys)
      { type: t[:type].to_s, damage: t[:damage].to_i }
    end
  end
end
