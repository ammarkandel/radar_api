# frozen_string_literal: true

require "rails_helper"

RSpec.describe AttackModes::ClosestFirst do
  let(:positions) do
    [
      { position: { x: 0, y: 60 }, targets: [] },
      { position: { x: 3, y: 10 }, targets: [] },
      { position: { x: 0, y: 40 }, targets: [] }
    ]
  end

  describe "#call" do
    it "sorts positions by ascending distance from origin" do
      result = subject.call(positions)
      expect(result.map { |p| p[:position] }).to eq([
        { x: 3, y: 10 },  # √109 ≈ 10.44
        { x: 0, y: 40 },  # 40
        { x: 0, y: 60 }   # 60
      ])
    end
  end

  describe "#selector?" do
    it { expect(subject.selector?).to be true }
  end

  describe "#filter?" do
    it { expect(subject.filter?).to be false }
  end
end

RSpec.describe AttackModes::FurthestFirst do
  let(:positions) do
    [
      { position: { x: 3, y: 10 }, targets: [] },
      { position: { x: 0, y: 60 }, targets: [] },
      { position: { x: 0, y: 40 }, targets: [] }
    ]
  end

  describe "#call" do
    it "sorts positions by descending distance from origin" do
      result = subject.call(positions)
      expect(result.first[:position]).to eq({ x: 0, y: 60 })
      expect(result.last[:position]).to eq({ x: 3, y: 10 })
    end
  end

  describe "#selector?" do
    it { expect(subject.selector?).to be true }
  end
end

RSpec.describe AttackModes::AvoidCrossfire do
  let(:positions) do
    [
      { position: { x: 0, y: 20 }, targets: [ { type: "T7-T", damage: 30 }, { type: "Human", damage: 0 } ] },
      { position: { x: 0, y: 80 }, targets: [ { type: "HK-Tank", damage: 20 } ] },
      { position: { x: 0, y: 70 }, targets: [ { type: "T-X", damage: 20 } ] }
    ]
  end

  describe "#call" do
    it "removes positions containing Human targets" do
      result = subject.call(positions)
      expect(result.length).to eq(2)
      expect(result.map { |p| p[:position][:y] }).to eq([ 80, 70 ])
    end

    it "returns all positions when no humans present" do
      no_humans = [
        { position: { x: 0, y: 10 }, targets: [ { type: "T1", damage: 30 } ] }
      ]
      result = subject.call(no_humans)
      expect(result.length).to eq(1)
    end
  end

  describe "#filter?" do
    it { expect(subject.filter?).to be true }
  end
end

RSpec.describe AttackModes::PriorizeTx do
  let(:positions) do
    [
      { position: { x: 0, y: 20 }, targets: [ { type: "T7-T", damage: 30 } ] },
      { position: { x: 0, y: 90 }, targets: [ { type: "T-X", damage: 20 }, { type: "T7-T", damage: 30 } ] }
    ]
  end

  describe "#call" do
    it "keeps only positions with T-X when available" do
      result = subject.call(positions)
      expect(result.length).to eq(1)
      expect(result.first[:position]).to eq({ x: 0, y: 90 })
    end

    it "returns all positions when none have T-X" do
      no_tx = [
        { position: { x: 0, y: 20 }, targets: [ { type: "T7-T", damage: 30 } ] },
        { position: { x: 0, y: 40 }, targets: [ { type: "HK-Tank", damage: 20 } ] }
      ]
      result = subject.call(no_tx)
      expect(result.length).to eq(2)
    end
  end

  describe "#sort_targets" do
    it "places T-X targets first, then others by damage desc" do
      targets = [
        { type: "T7-T", damage: 90 },
        { type: "T-X", damage: 20 },
        { type: "HK-Bomber", damage: 80 }
      ]
      result = subject.sort_targets(targets)
      expect(result.map { |t| t[:type] }).to eq([ "T-X", "T7-T", "HK-Bomber" ])
    end
  end

  describe "#filter?" do
    it { expect(subject.filter?).to be true }
  end
end
