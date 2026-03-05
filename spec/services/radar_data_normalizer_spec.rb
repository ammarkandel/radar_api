# frozen_string_literal: true

require "rails_helper"

RSpec.describe RadarDataNormalizer do
  describe "#call" do
    it "normalizes standard radar data" do
      raw = [
        { position: { x: 10, y: 20 }, targets: [{ type: "T1", damage: 30 }] }
      ]

      result = described_class.new(raw).call

      expect(result).to eq([
        { position: { x: 10, y: 20 }, targets: [{ type: "T1", damage: 30 }] }
      ])
    end

    it "handles targets as a hash instead of array" do
      raw = [
        { position: { x: 5, y: 5 }, targets: { type: "mech", number: 20 } }
      ]

      result = described_class.new(raw).call

      expect(result.first[:targets]).to be_an(Array)
      expect(result.first[:targets].length).to eq(1)
      expect(result.first[:targets].first[:type]).to eq("mech")
    end

    it "handles missing damage values (defaults to 0)" do
      raw = [
        { position: { x: 0, y: 10 }, targets: [{ type: "Human" }] }
      ]

      result = described_class.new(raw).call

      expect(result.first[:targets].first[:damage]).to eq(0)
    end

    it "handles nil or missing targets" do
      raw = [
        { position: { x: 0, y: 10 }, targets: nil }
      ]

      result = described_class.new(raw).call

      expect(result.first[:targets]).to eq([])
    end

    it "coerces position coordinates to integers" do
      raw = [
        { position: { x: "3", y: "10" }, targets: [] }
      ]

      result = described_class.new(raw).call

      expect(result.first[:position]).to eq({ x: 3, y: 10 })
    end
  end
end
