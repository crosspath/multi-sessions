# frozen_string_literal: true

require "multi_sessions/railtie" if defined?(Rails::Railtie)

# Database-backed sessions for Rails applications
module MultiSessions
  autoload :AuthStrategies, "multi_sessions/auth_strategies"
  autoload :Config, "multi_sessions/config"
  autoload :ControllerMethods, "multi_sessions/controller_methods"
  autoload :Current, "multi_sessions/current"
  autoload :VERSION, "multi_sessions/version"

  class << self
    attr_reader :config

    # @yieldparam config [MultiSessions::Config]
    # @yieldreturn [void]
    # @return [void]
    def configure
      @config = MultiSessions::Config.new(**MultiSessions::Config.default_values)

      yield(@config)
      @config.validate
    end
  end
end
