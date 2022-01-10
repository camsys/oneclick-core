module ConfigHelpers
  PERMITTED_DASHBOARD_MODES = %i[default travel_patterns].freeze

  def build_dashboard_mode_collection
    PERMITTED_DASHBOARD_MODES.map do |mode|
      DashboardModeInputHelper.new(mode)
    end
  end

  class DashboardModeInputHelper
    def initialize(sym)
      raise "Unexpected input, ensure your inputs match with permitted dashboard modes" unless PERMITTED_DASHBOARD_MODES.include?(sym)
      @value = sym
      @name = sym.to_s.gsub('_', ' ').titleize
    end

    def value
      @value
    end

    def name
      @name
    end
  end
end
