# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /radar", type: :request do
  describe "closest-first mode" do
    it "selects the nearest position to origin" do
      payload = {
        "attack-mode": [ "closest-first" ],
        radar: [
          { position: { x: 0, y: 40 }, targets: [ { type: "T1", damage: 30 }, { type: "T-X", damage: 80 }, { type: "Human" } ] },
          { position: { x: 0, y: 60 }, targets: [ { type: "T-X", damage: 80 } ] }
        ]
      }

      post "/radar", params: payload, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["position"]).to eq({ "x" => 0, "y" => 40 })
      expect(body["targets"]).to eq([ "T-X", "T1" ])
    end

    it "strips Human targets from the response" do
      payload = {
        "attack-mode": [ "closest-first" ],
        radar: [
          { position: { x: 0, y: 10 }, targets: [ { type: "Human" }, { type: "T1", damage: 50 } ] }
        ]
      }

      post "/radar", params: payload, as: :json

      body = JSON.parse(response.body)
      expect(body["targets"]).not_to include("Human")
      expect(body["targets"]).to eq([ "T1" ])
    end

    it "sorts targets by damage descending" do
      payload = {
        "attack-mode": [ "closest-first" ],
        radar: [
          { position: { x: 0, y: 10 }, targets: [
            { type: "T1", damage: 20 },
            { type: "HK-Tank", damage: 90 },
            { type: "T7-T", damage: 50 }
          ] }
        ]
      }

      post "/radar", params: payload, as: :json

      body = JSON.parse(response.body)
      expect(body["targets"]).to eq([ "HK-Tank", "T7-T", "T1" ])
    end
  end

  describe "furthest-first mode" do
    it "selects the furthest position from origin" do
      payload = {
        "attack-mode": [ "furthest-first" ],
        radar: [
          { position: { x: 0, y: 20 }, targets: [ { type: "T7-T", damage: 30 }, { type: "HK-Bomber", damage: 80 } ] },
          { position: { x: 0, y: 80 }, targets: [ { type: "HK-Tank", damage: 20 } ] }
        ]
      }

      post "/radar", params: payload, as: :json

      body = JSON.parse(response.body)
      expect(body["position"]).to eq({ "x" => 0, "y" => 80 })
      expect(body["targets"]).to eq([ "HK-Tank" ])
    end
  end

  describe "priorize-t-x mode" do
    it "selects position with T-X and lists T-X targets first" do
      payload = {
        "attack-mode": [ "priorize-t-x" ],
        radar: [
          { position: { x: 0, y: 20 }, targets: [ { type: "T7-T", damage: 30 }, { type: "HK-Bomber", damage: 80 } ] },
          { position: { x: 0, y: 80 }, targets: [ { type: "HK-Tank", damage: 20 } ] },
          { position: { x: 0, y: 90 }, targets: [ { type: "T-X", damage: 20 }, { type: "T7-T", damage: 30 }, { type: "HK-Bomber", damage: 80 } ] }
        ]
      }

      post "/radar", params: payload, as: :json

      body = JSON.parse(response.body)
      expect(body["position"]).to eq({ "x" => 0, "y" => 90 })
      expect(body["targets"]).to eq([ "T-X", "HK-Bomber", "T7-T" ])
    end
  end

  describe "avoid-crossfire mode" do
    it "filters out positions with humans and defaults to closest" do
      payload = {
        "attack-mode": [ "avoid-crossfire" ],
        radar: [
          { position: { x: 0, y: 20 }, targets: [ { type: "T7-T", damage: 30 }, { type: "HK-Bomber", damage: 80 }, { type: "Human" } ] },
          { position: { x: 0, y: 80 }, targets: [ { type: "HK-Tank", damage: 20 } ] },
          { position: { x: 0, y: 70 }, targets: [ { type: "T-X", damage: 20 }, { type: "T7-T", damage: 90 }, { type: "HK-Bomber", damage: 80 } ] }
        ]
      }

      post "/radar", params: payload, as: :json

      body = JSON.parse(response.body)
      expect(body["position"]).to eq({ "x" => 0, "y" => 70 })
      expect(body["targets"]).to eq([ "T7-T", "HK-Bomber", "T-X" ])
    end
  end

  describe "chained modes" do
    it "applies furthest-first with avoid-crossfire" do
      payload = {
        "attack-mode": [ "furthest-first", "avoid-crossfire" ],
        radar: [
          { position: { x: 10, y: 19 }, targets: [ { type: "T-X", damage: 20 }, { type: "T7-T", damage: 90 } ] },
          { position: { x: 70, y: 91 }, targets: [ { type: "T-X", damage: 20 }, { type: "T7-T", damage: 90 } ] },
          { position: { x: 3, y: 10 }, targets: [ { type: "T-X", damage: 20 }, { type: "T7-T", damage: 90 } ] }
        ]
      }

      post "/radar", params: payload, as: :json

      body = JSON.parse(response.body)
      expect(body["position"]).to eq({ "x" => 70, "y" => 91 })
    end
  end

  describe "conflicting modes" do
    it "returns an error for closest-first + furthest-first" do
      payload = {
        "attack-mode": [ "closest-first", "furthest-first" ],
        radar: [
          { position: { x: 0, y: 10 }, targets: [ { type: "T1", damage: 30 } ] }
        ]
      }

      post "/radar", params: payload, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "malformed data" do
    it "handles targets as a hash instead of array" do
      payload = {
        "attack-mode": [ "furthest-first" ],
        radar: [
          { position: { x: 3, y: 10 }, targets: [ { type: "T-X", damage: 20 } ] },
          { position: { x: 30, y: 95 }, targets: { type: "mech", number: 20 } }
        ]
      }

      post "/radar", params: payload, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["position"]).to eq({ "x" => 30, "y" => 95 })
    end
  end

  # ── Edge Cases (Senior-level defensive testing) ──

  describe "edge cases" do
    it "returns 400 when radar data is empty" do
      payload = { "attack-mode": [ "closest-first" ], radar: [] }

      post "/radar", params: payload, as: :json

      expect(response).to have_http_status(:bad_request)
      body = JSON.parse(response.body)
      expect(body["error"]).to include("Radar data is required")
    end

    it "returns 400 when radar key is missing" do
      payload = { "attack-mode": [ "closest-first" ] }

      post "/radar", params: payload, as: :json

      expect(response).to have_http_status(:bad_request)
      body = JSON.parse(response.body)
      expect(body["error"]).to include("Radar data is required")
    end

    it "defaults to closest-first when attack-mode is empty" do
      payload = {
        "attack-mode": [],
        radar: [
          { position: { x: 0, y: 80 }, targets: [ { type: "HK-Tank", damage: 20 } ] },
          { position: { x: 0, y: 10 }, targets: [ { type: "T7-T", damage: 30 } ] }
        ]
      }

      post "/radar", params: payload, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["position"]).to eq({ "x" => 0, "y" => 10 })
    end

    it "returns 422 when all positions are filtered by avoid-crossfire" do
      payload = {
        "attack-mode": [ "avoid-crossfire" ],
        radar: [
          { position: { x: 0, y: 10 }, targets: [ { type: "Human" } ] },
          { position: { x: 0, y: 20 }, targets: [ { type: "T1", damage: 30 }, { type: "Human" } ] }
        ]
      }

      post "/radar", params: payload, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]).to include("No valid positions")
    end

    it "works correctly with a single position" do
      payload = {
        "attack-mode": [ "closest-first" ],
        radar: [
          { position: { x: 5, y: 5 }, targets: [ { type: "T-X", damage: 100 } ] }
        ]
      }

      post "/radar", params: payload, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["position"]).to eq({ "x" => 5, "y" => 5 })
      expect(body["targets"]).to eq([ "T-X" ])
    end

    it "returns 422 for unknown attack modes" do
      payload = {
        "attack-mode": [ "destroy-all" ],
        radar: [
          { position: { x: 0, y: 10 }, targets: [ { type: "T1", damage: 30 } ] }
        ]
      }

      post "/radar", params: payload, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]).to include("Unknown attack mode")
    end

    it "returns 422 with descriptive error for conflicting modes" do
      payload = {
        "attack-mode": [ "closest-first", "furthest-first" ],
        radar: [
          { position: { x: 0, y: 10 }, targets: [ { type: "T1", damage: 30 } ] }
        ]
      }

      post "/radar", params: payload, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]).to include("Cannot combine")
    end

    it "handles positions with only Human targets (empty target list after stripping)" do
      payload = {
        "attack-mode": [ "closest-first" ],
        radar: [
          { position: { x: 0, y: 10 }, targets: [ { type: "Human" } ] },
          { position: { x: 0, y: 20 }, targets: [ { type: "T1", damage: 50 } ] }
        ]
      }

      post "/radar", params: payload, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      # Closest is (0,10) — it wins, but its only target (Human) is stripped
      expect(body["position"]).to eq({ "x" => 0, "y" => 10 })
      expect(body["targets"]).to eq([])
    end
  end
end
