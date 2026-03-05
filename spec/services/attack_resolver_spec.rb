# frozen_string_literal: true

require "rails_helper"

RSpec.describe AttackResolver do
  let(:positions) do
    [
      { position: { x: 0, y: 40 }, targets: [ { type: "T1", damage: 30 }, { type: "T-X", damage: 80 } ] },
      { position: { x: 0, y: 60 }, targets: [ { type: "T-X", damage: 80 } ] }
    ]
  end

  describe "#call" do
    it "resolves closest-first correctly" do
      result = described_class.new([ "closest-first" ], positions).call
      expect(result[:position]).to eq({ x: 0, y: 40 })
    end

    it "resolves furthest-first correctly" do
      result = described_class.new([ "furthest-first" ], positions).call
      expect(result[:position]).to eq({ x: 0, y: 60 })
    end

    it "defaults to closest-first when no selector mode given" do
      positions_with_humans = [
        { position: { x: 0, y: 80 }, targets: [ { type: "HK-Tank", damage: 20 } ] },
        { position: { x: 0, y: 70 }, targets: [ { type: "T7-T", damage: 90 } ] }
      ]
      result = described_class.new([ "avoid-crossfire" ], positions_with_humans).call
      expect(result[:position]).to eq({ x: 0, y: 70 })
    end

    it "raises InvalidModeCombination for conflicting modes" do
      expect {
        described_class.new([ "closest-first", "furthest-first" ], positions).call
      }.to raise_error(AttackResolver::InvalidModeCombination)
    end

    it "raises InvalidModeCombination for unknown modes" do
      expect {
        described_class.new([ "unknown-mode" ], positions).call
      }.to raise_error(AttackResolver::InvalidModeCombination, /Unknown attack mode/)
    end

    it "raises NoPositionsError when all positions are filtered" do
      all_human_positions = [
        { position: { x: 0, y: 10 }, targets: [ { type: "Human" } ] }
      ]
      expect {
        described_class.new([ "avoid-crossfire" ], all_human_positions).call
      }.to raise_error(AttackResolver::NoPositionsError)
    end

    it "chains filters before selectors" do
      mixed = [
        { position: { x: 0, y: 20 }, targets: [ { type: "T7-T", damage: 30 }, { type: "Human" } ] },
        { position: { x: 0, y: 80 }, targets: [ { type: "HK-Tank", damage: 20 } ] },
        { position: { x: 0, y: 50 }, targets: [ { type: "T-X", damage: 40 } ] }
      ]
      result = described_class.new([ "furthest-first", "avoid-crossfire" ], mixed).call
      expect(result[:position]).to eq({ x: 0, y: 80 })
    end

    it "raises ValidationError when radar data is empty" do
      expect {
        described_class.new([ "closest-first" ], []).call
      }.to raise_error(AttackResolver::ValidationError, /Radar data is required/)
    end

    it "raises ValidationError when radar data is nil" do
      expect {
        described_class.new([ "closest-first" ], nil).call
      }.to raise_error(AttackResolver::ValidationError, /Radar data is required/)
    end

    it "works with empty attack modes (defaults to closest-first)" do
      result = described_class.new([], positions).call
      expect(result[:position]).to eq({ x: 0, y: 40 })
    end
  end
end
