# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResponseFormatter do
  let(:position) do
    {
      position: { x: 0, y: 40 },
      targets: [
        { type: "T1", damage: 30 },
        { type: "T-X", damage: 80 },
        { type: "Human", damage: 0 }
      ]
    }
  end

  describe "#call" do
    it "strips Human targets" do
      result = described_class.new(position).call
      expect(result[:targets]).not_to include("Human")
    end

    it "sorts targets by damage descending by default" do
      result = described_class.new(position).call
      expect(result[:targets]).to eq([ "T-X", "T1" ])
    end

    it "includes the position coordinates" do
      result = described_class.new(position).call
      expect(result[:position]).to eq({ x: 0, y: 40 })
    end

    context "with priorize-t-x strategy" do
      let(:position_with_multiple) do
        {
          position: { x: 0, y: 90 },
          targets: [
            { type: "T-X", damage: 20 },
            { type: "T7-T", damage: 30 },
            { type: "HK-Bomber", damage: 80 }
          ]
        }
      end

      it "lists T-X targets first, then others by damage desc" do
        strategy = AttackModes::PriorizeTx.new
        result = described_class.new(position_with_multiple, [ strategy ]).call
        expect(result[:targets]).to eq([ "T-X", "HK-Bomber", "T7-T" ])
      end
    end
  end
end
