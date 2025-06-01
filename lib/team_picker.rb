# frozen_string_literal: true

module SolarScheduler
  # This module is responsible for picking a team of employees based on their roles and the required team composition.
  module TeamPicker
    module_function

    # pool  :: [Employee]
    # need  :: { role => n, :any => m }
    # Devuelve [Employee] o nil si no se puede formar el equipo.
    def pick(pool, need)
      team = []

      %i[certified pending laborer].each do |role|
        req = need[role]
        next if req.zero?

        sel = pool.select { |e| e.role == role }.first(req)
        return nil if sel.size < req

        team.concat(sel)
      end

      any_req = need[:any]
      if any_req.positive?
        extras = (pool - team).first(any_req)
        return nil if extras.size < any_req

        team.concat(extras)
      end
      team
    end
  end
end
