# Approach Document — Objective Selection Module

## Problem Analysis

The challenge is to build an HTTP endpoint that selects the best attack position from radar scan data,
based on configurable and chainable attack modes. Key requirements:

1. **Multiple attack modes** that can be combined
2. **Extensibility** — new modes must be easy to add
3. **Distance calculation** from origin (0,0) using Euclidean distance: `√(x² + y²)`
4. **Response formatting** — strip humans, sort targets by damage

## Architecture: Strategy Pattern + SOLID Principles

### S — Single Responsibility

Each class has exactly one job:

| Class | Responsibility |
|-------|---------------|
| `RadarController` | HTTP layer — receives request, returns response |
| `RadarDataNormalizer` | Converts raw params into clean Ruby hashes |
| `AttackResolver` | Orchestrates mode chaining and position selection |
| `ResponseFormatter` | Formats the winning position into API response |
| `AttackModes::*` | Individual attack mode logic |

### O — Open/Closed

- **Mode registration**: Adding a new mode = 1 new class + 1 line in `MODE_REGISTRY`. Zero changes to existing classes.
- **Target sorting**: Each strategy can optionally implement `sort_targets(targets)` to customize target ordering — the `ResponseFormatter` delegates to it without knowing the details.

### L — Liskov Substitution

All strategy subclasses follow the same `Base` interface: `call(positions)` returns an array of positions. Any strategy can be swapped for another without breaking the system.

### I — Interface Segregation

Only two mode types exist: `filter?` and `selector?`. Each strategy declares its type. No strategy is forced to implement methods it doesn't need.

### D — Dependency Inversion

- The `AttackResolver` depends on the `Base` abstraction, not concrete strategy classes directly.
- The `MODE_REGISTRY` hash provides a configurable mapping, keeping mode names decoupled from implementations.

## File Structure

```
app/
├── controllers/
│   └── radar_controller.rb              # HTTP endpoint (SRP)
└── services/
    ├── attack_resolver.rb               # Orchestrator (SRP)
    ├── radar_data_normalizer.rb         # Data normalization (SRP)
    ├── response_formatter.rb            # Response formatting (SRP + OCP)
    └── attack_modes/
        ├── base.rb                      # Abstract base (LSP + ISP)
        ├── closest_first.rb             # Selector: distance ascending
        ├── furthest_first.rb            # Selector: distance descending
        ├── avoid_crossfire.rb           # Filter: removes human positions
        └── priorize_tx.rb              # Filter + sort_targets (OCP)

spec/
├── requests/
│   └── radar_spec.rb                   # 8 integration tests
└── services/
    ├── attack_resolver_spec.rb          # 7 unit tests
    ├── radar_data_normalizer_spec.rb    # 5 unit tests
    ├── response_formatter_spec.rb       # 4 unit tests
    └── attack_modes/
        └── attack_modes_spec.rb         # 13 unit tests
```

## How to Add a New Attack Mode

```ruby
# 1. Create the strategy class
class AttackModes::NewMode < AttackModes::Base
  def filter?  # or selector?
    true
  end

  def call(positions)
    # your filtering/sorting logic
  end

  # Optional: customize target ordering in response
  def sort_targets(targets)
    # your sorting logic
  end
end

# 2. Register it (one line in attack_resolver.rb)
MODE_REGISTRY["new-mode"] = AttackModes::NewMode
```

## Testing

```bash
bundle exec rspec
