# frozen_string_literal: true

require_relative 'team_picker'

module SolarScheduler
  # Weekdays considered for planning
  DAYS = %w[Monday Tuesday Wednesday Thursday Friday].freeze

  Employee = Struct.new(:id, :role, :availability) do
    def available_on?(day)
      availability.include?(day)
    end
  end

  Building = Struct.new(:id, :kind)

  # Crew requirements per building type
  REQUIREMENTS = {
    single: {
      certified: 1,
      pending: 0,
      laborer: 0,
      any: 0
    },
    two_story: {
      certified: 1,
      pending: 0,
      laborer: 0,
      any: 1   # 1 extra of any role
    },
    commercial: {
      certified: 2,
      pending: 2,
      laborer: 0,
      any: 4   # 4 additional of any role
    }
  }.freeze

  module_function

  # buildings :: [Building]  (already ordered by priority)
  # employees :: [Employee]  (with daily availability)
  # Returns  :: { "Monday" => [ { building:, crew: [ids] }, ... ], ... }
  def schedule(buildings, employees)
    backlog = buildings.dup
    availability = employees.each_with_object({}) { |e, h| h[e.id] = e.availability.dup }
    output = Hash.new { |h, k| h[k] = [] }

    DAYS.each do |day|
      output[day]        # ensure key exists even if no crew is assigned
      day_pool = employees.select { |e| availability[e.id].include?(day) }

      loop do
        break if backlog.empty?

        needed = REQUIREMENTS[backlog.first.kind]
        crew   = TeamPicker.pick(day_pool, needed)
        break unless crew # not enough resources for another building

        output[day] << { building: backlog.first.id, crew: crew.map(&:id) }

        backlog.shift
        crew.each do |m|
          day_pool.delete(m)
          availability[m.id].delete(day)
        end
      end
    end
    output
  end
end
