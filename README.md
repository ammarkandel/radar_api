# Radar API — Objective Selection Module

> A T-800 combat module that selects the optimal attack position from battlefield radar scan data.

## Setup

```bash
# Install dependencies
bundle install

# Start the server
rails server
```

## Running Tests

```bash
# RSpec unit + integration tests (48 specs)
bundle exec rspec --format documentation

# Integration test script (requires server running on port 3000)
rails server &
bash test_attack.sh

# Code style linting
bundle exec rubocop

# Security scanning
bin/brakeman --no-pager
bin/bundler-audit
```

## API Documentation

### `POST /radar`

Accepts battlefield scan data and returns the best position to attack.

#### Request Body

```json
{
  "attack-mode": ["closest-first"],
  "radar": [
    {
      "position": { "x": 0, "y": 40 },
      "targets": [
        { "type": "T1-9", "damage": 80 },
        { "type": "Human" }
      ]
    },
    {
      "position": { "x": 2, "y": 60 },
      "targets": [
        { "type": "HK-Tank", "damage": 40 }
      ]
    }
  ]
}
```

#### Response (200 OK)

```json
{
  "position": { "x": 0, "y": 40 },
  "targets": ["T1-9"]
}
```

#### Error Responses

| Status | When |
|--------|------|
| `400 Bad Request` | Missing or empty `radar` data |
| `422 Unprocessable Entity` | Conflicting modes, unknown modes, or no valid positions |

### Attack Modes

| Mode | Description |
|------|-------------|
| `closest-first` | Select position nearest to origin (0,0) |
| `furthest-first` | Select position furthest from origin (0,0) |
| `avoid-crossfire` | Filter out positions containing Human targets |
| `priorize-t-x` | Prioritize positions containing T-X targets |

**Chaining**: Modes can be combined (e.g., `["furthest-first", "avoid-crossfire"]`).  
**Default**: If no selector mode is provided, `closest-first` is used.

### Target Types

`Human`, `T1-9`, `T7-T`, `T-X`, `HK-Airstrike`, `HK-Bomber`, `HK-Tank`

## Architecture

Uses the **Strategy Pattern** — each attack mode is an independent, pluggable class:

```
app/services/
├── attack_resolver.rb           # Orchestrator
├── radar_data_normalizer.rb     # Input normalization
├── response_formatter.rb        # Output formatting
└── attack_modes/
    ├── base.rb                  # Abstract base class
    ├── closest_first.rb         # Selector
    ├── furthest_first.rb        # Selector
    ├── avoid_crossfire.rb       # Filter
    └── priorize_tx.rb           # Filter + target sorter
```

### Adding a New Attack Mode

1. Create `app/services/attack_modes/your_mode.rb` extending `Base`
2. Add one line to `MODE_REGISTRY` in `attack_resolver.rb`

See [APPROACH.md](APPROACH.md) for full architectural details and SOLID principles.
