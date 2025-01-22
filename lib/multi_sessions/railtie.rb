# frozen_string_literal: true

module MultiSessions
  # Configuration for Rails application.
  class Railtie < Rails::Railtie
    initializer "multi_sessions.controller_methods" do
      [ActionController::API, ActionController::Base].each do |controller|
        controller.include(MultiSessions::ControllerMethods)
      end
    end
  end
end
