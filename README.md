

# Solar Scheduler

Small Ruby solution that generates a one‑week (Monday-Friday) installation schedule for solar‑panel crews, respecting:

* **Crew role requirements** per building type  
  | Building type | Certified | Pending | Laborer | Any role |
  | ------------- | --------- | ------- | ------- | -------- |
  | `:single`     | 1 | 0 | 0 | 0 |
  | `:two_story`  | 1 | 0 | 0 | 1 |
  | `:commercial` | 2 | 2 | 0 | 4 |
* **Employee daily availability** – each employee can work on **one** building **per day**.
* **Building priority** – buildings are scheduled in the order they arrive.
* **Workweek window** – only Monday–Friday are considered; unassigned days still appear in the output.

The algorithm is kept intentionally simple (greedy + helper) to satisfy the MVP scope and run in O(B × E).

---

## Quick start

```bash
# install deps (only RSpec)
bundle install

# run the example script
ruby bin/schedule

# run the full test suite
bundle exec rspec
```

---

## Usage

```ruby
require_relative 'lib/scheduler'
include SolarScheduler   # optional helper

employees = [
  Employee.new('C1', :certified, SolarScheduler::DAYS),
  Employee.new('P1', :pending,   %w[Monday Wednesday Friday]),
  Employee.new('L1', :laborer,   SolarScheduler::DAYS)
]

buildings = [
  Building.new('B1', :single),
  Building.new('B2', :two_story)
]

plan = SolarScheduler.schedule(buildings, employees)
puts plan
```

The `schedule` method returns a hash like:

```ruby
{
  "Monday"    => [ { building: "B1", crew: ["C1"] } ],
  "Tuesday"   => [],
  "Wednesday" => [ { building: "B2", crew: ["C1", "P1"] } ],
  "Thursday"  => [],
  "Friday"    => []
}
```

---

## Project structure

```
solar_scheduler/
├── bin/
│   └── schedule         # CLI entry point (example run)
├── lib/
│   ├── scheduler.rb     # main planner
│   └── team_picker.rb   # helper that selects crews
├── spec/
│   ├── scheduler_spec.rb# 4 RSpec examples
│   └── spec_helper.rb
├── Gemfile
└── README.md
```

---

## Assumptions

* Each building’s work fits in **one full day**.
* An employee cannot split across buildings in one day.
* If crew requirements **cannot be met**, the building is **skipped**, backlog order is preserved.

---

## Known limitations & future work

| Area | Improvement |
| ---- | ----------- |
| **Optimality** | Use ILP or matching to maximise scheduled buildings. |
| **Partial days / overtime** | Currently not modelled. |
| **Input validation** | Could add strict schema + error handling. |
| **API / UI** | Wrap into a Rails App for real‑world consumption. |
| **CI** | Add GitHub Actions with RuboCop lint + SimpleCov coverage gating. |

---

## Author

Miguel Angel Ricaño – 2025‑06‑01
