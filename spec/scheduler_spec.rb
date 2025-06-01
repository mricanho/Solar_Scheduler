# frozen_string_literal: true
require_relative '../lib/scheduler'

RSpec.describe SolarScheduler do
  let(:days) { SolarScheduler::DAYS }

  let(:employees) do
    [
      SolarScheduler::Employee.new('C1', :certified, days),
      SolarScheduler::Employee.new('C2', :certified, days),
      SolarScheduler::Employee.new('P1', :pending,   days),
      SolarScheduler::Employee.new('P2', :pending,   days),
      SolarScheduler::Employee.new('L1', :laborer,   days),
      SolarScheduler::Employee.new('L2', :laborer,   days),
      SolarScheduler::Employee.new('L3', :laborer,   days),
      SolarScheduler::Employee.new('L4', :laborer,   days)
    ]
  end

  let(:buildings) do
    [
      SolarScheduler::Building.new('B1', :single),
      SolarScheduler::Building.new('B2', :two_story),
      SolarScheduler::Building.new('B3', :commercial)
    ]
  end

  it 'generates a schedule with all weekdays present and correct crew for commercial building' do
    plan = SolarScheduler.schedule(buildings, employees)

    # Ensure Monday–Friday present (strings)
    expect(plan.keys).to contain_exactly('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')

    # Find commercial building assignment
    job_b3 = plan.values.flatten.find { |job| job[:building] == 'B3' }
    crew_b3 = job_b3[:crew]

    expect(crew_b3.count { |id| id.start_with?('C') }).to eq 2
    expect(crew_b3.count { |id| id.start_with?('P') }).to eq 2
    expect(crew_b3.size).to eq 8
  end

  it 'skips a building when crew requirements cannot be satisfied' do
    scarce_employees = [
      SolarScheduler::Employee.new('C1', :certified, days),   # only 1 certified
      SolarScheduler::Employee.new('P1', :pending,   days),   # only 1 pending
      SolarScheduler::Employee.new('L1', :laborer,   days),   # only 1 laborer → not enough for commercial
    ]

    scarce_buildings = [
      SolarScheduler::Building.new('X1', :commercial)
    ]

    plan = SolarScheduler.schedule(scarce_buildings, scarce_employees)

    # No day should contain the commercial building because requirements are unmet
    scheduled_ids = plan.values.flatten.map { |job| job[:building] }
    expect(scheduled_ids).not_to include('X1')
  end

  it 'never assigns the same employee to two buildings on the same day' do
    one_cert  = SolarScheduler::Employee.new('C1', :certified, days)
    extra_lab = SolarScheduler::Employee.new('L1', :laborer,   days)
    buildings_two = [
      SolarScheduler::Building.new('S1', :single),
      SolarScheduler::Building.new('S2', :single)
    ]

    plan = SolarScheduler.schedule(buildings_two, [one_cert, extra_lab])

    plan.each_value do |jobs|
      all_ids = jobs.flat_map { |job| job[:crew] }
      expect(all_ids).to eq(all_ids.uniq), "An employee was double‑booked on the same day"
    end
  end

  it 'stops scheduling when backlog exceeds days/personnel capacity' do
    # Only enough employees to handle one single-story building per day
    limited_employees = [
      SolarScheduler::Employee.new('C1', :certified, days)
    ]

    # Seven buildings but only five working days
    large_backlog = (1..7).map { |i| SolarScheduler::Building.new("SS#{i}", :single) }

    plan = SolarScheduler.schedule(large_backlog, limited_employees)

    total_scheduled = plan.values.flatten.size
    expect(total_scheduled).to eq 5   # at most one per day with single installer

    # Ensure the last two buildings remain unscheduled
    unscheduled_ids = large_backlog.map(&:id) - plan.values.flatten.map { |job| job[:building] }
    expect(unscheduled_ids).to match_array(['SS6', 'SS7'])
  end
end