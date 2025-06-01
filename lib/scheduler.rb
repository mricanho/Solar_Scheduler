# frozen_string_literal: true

require_relative 'team_picker'

module SolarScheduler # rubocop:disable Style/Documentation
  DAYS = %w[Monday Tuesday Wednesday Thursday Friday].freeze

  Employee = Struct.new(:id, :role, :availability) do
    def available_on?(day)
      availability.include?(day)
    end
  end

  Building = Struct.new(:id, :kind)

  # Reglas del PDF: número de personas requeridas por tipo de edificio.
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
      any: 1   # 1 extra de cualquier rol
    },
    commercial: {
      certified: 2,
      pending: 2,
      laborer: 0,
      any: 4   # 4 adicionales de cualquier rol
    }
  }.freeze

  module_function

  # buildings :: [Building]  (ya ordenados por prioridad)
  # employees :: [Employee]  (con disponibilidad por día)
  # Devuelve  :: { "Monday" => [ { building:, crew: [ids] }, ... ], ... }
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
        break unless crew # no hay recursos para más

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
