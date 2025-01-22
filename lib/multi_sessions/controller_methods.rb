# frozen_string_literal: true

module MultiSessions
  # Helper methods for controllers & view templates.
  module ControllerMethods
    def self.included(base) # :nodoc:
      base.class_eval do
        before_action(:current)
        after_action(:finalize_session)
        helper_method(:current, :current_user) if respond_to?(:helper_method)
      end
    end

    private

    # @return [MultiSessions::Current]
    def current
      @current ||= MultiSessions::Current.new(request:)
    end

    # @return [nil, ActiveRecord::Base]
    def current_user
      current.user_model
    end

    # @return [void]
    def finalize_session
      current.finalize_session
    end
  end
end
