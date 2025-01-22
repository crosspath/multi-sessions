# frozen_string_literal: true

module MultiSessions
  # Entry point for accessing models for current user & current session.
  class Current
    attr_reader :id, :session_id, :session_model, :user_model

    # @param request [ActionDispatch::Request]
    def initialize(request:)
      @request = request
      @cookies = request.cookie_jar if use_cookies?

      reload_session

      @id = @session_model.account_id
      @id ||= @cookies.signed[config.permanent_cookie_name] if use_cookies?

      reload_user_model if @id
    end

    # @return [boolean]
    def authorized?
      !id.nil?
    end

    # @return [void]
    def clear
      @id = nil
      @session_id = nil
      @session_model = nil
      @user_model = nil

      request.reset_session
      cookies&.delete(config.permanent_cookie_name)
    end

    # @return [void]
    def finalize_session
      return if @session_model.nil?

      @session_model.save!(validate: false)
    end

    # @param user_id [Object] See type of primary key column in users table.
    #   Generally it is Integer.
    # @return [void]
    def id=(user_id)
      raise ArgumentError, "Should not be nil" if user_id.nil?

      @id = user_id

      reload_user_model
    end

    # @return [String]
    def jwt
      MultiSessions::AuthStrategies::JwtStrategy.encode_jwt(@session_id.public_id)
    end

    # @return [void]
    # @raise [NoMethodError] When authorization by cookies is disabled
    def save_user_id_into_cookie
      cookies.signed[config.permanent_cookie_name] = config.cookies_options.merge(value: @id)
    end

    private

    attr_reader :cookies, :request

    # @return [MultiSessions::Config]
    def config
      @config ||= MultiSessions.config
    end

    # @return [void]
    def reload_session
      @session_id = MultiSessions::AuthStrategies.find_or_init_session(request)
      @session_model = session_model_class.find_or_initialize_by(session_id: @session_id.private_id)
    end

    # @return [void]
    def reload_user_model
      @user_model = user_model_scope.find_by(id: @id) if @id != @user_model&.id
      @session_model.account_id = @id
    end

    # @return [ActiveRecord::Base]
    def session_model_class
      @session_model_class ||= config.session_model_class.call
    end

    # @return [boolean]
    def use_cookies?
      @use_cookies ||= config.auth_strategies.include?(:cookie)
    end

    # @return [ActiveRecord::Base, ActiveRecord::Relation]
    def user_model_scope
      @user_model_scope ||= config.user_model_scope.call
    end
  end
end
