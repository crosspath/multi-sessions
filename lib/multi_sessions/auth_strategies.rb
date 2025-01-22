# frozen_string_literal: true

module MultiSessions
  # Initialization of sessions.
  module AuthStrategies
    extend self

    # Raised when all enabled strategies cannot find or initialize session. Perhaps you forgot
    # to add :generate_session_id?
    AuthError = Class.new(RuntimeError) # rubocop:disable Style/MutableConstant

    # Base class for authorization initializer/generator.
    class Strategy
      # @param request [ActionDispatch::Request]
      # @return [Strategy, nil]
      def self.result_or_nil(request)
        result = new(request)
        result.success? ? result : nil
      end

      # @return [Rack::Session::SessionId]
      attr_reader :session_id

      # @param request [ActionDispatch::Request]
      def initialize(request)
        @request = request
      end

      # @return [boolean]
      # @raise [NotImplementedError] This method should be implemented in ancestor classes
      def success?
        raise NotImplementedError
      end

      private

      # @return [ActionDispatch::Request]
      attr_reader :request

      # @return [void]
      def add_session_id_to_cookie
        value = @session_id.public_id
        cookies[config.session_cookie_name] = config.cookies_options.merge(value:)
      end

      # @return [ActionDispatch::Cookies]
      def cookies
        @cookies ||= request.cookie_jar.signed
      end

      # @return [MultiSessions::Config]
      def config
        @config ||= MultiSessions.config
      end
    end

    # Find session token in cookie.
    class CookieStrategy < Strategy
      # @return [boolean]
      def success?
        value = cookies[config.session_cookie_name]
        return false if value.blank?

        @session_id = Rack::Session::SessionId.new(value)

        true
      end
    end

    # Find session token in request header.
    # @see https://github.com/jwt/ruby-jwt
    class JwtStrategy < Strategy
      class << self
        # @param value [String] JWT with Session ID
        # @return [Array<Hash<String, Object>>]
        def decode_jwt(value)
          JWT.decode(value, secret_key, true, {algorithm: "HS256"})
        end

        # @param value [String] Session ID
        # @return [String]
        def encode_jwt(value)
          JWT.encode({data: value}, secret_key, "HS256")
        end

        private

        # @return [String]
        def secret_key
          @secret_key ||= MultiSessions.config.jwt_options[:secret_key]
        end
      end

      # @return [boolean]
      def success?
        parts = request.headers["Authorization"]&.split
        return false if !valid_header?(parts)

        jwt_payload = self.class.decode_jwt(parts.second)
        @session_id = Rack::Session::SessionId.new(jwt_payload.first["data"])

        true
      end

      private

      # @param parts [Array<String>]
      # @return [boolean]
      def valid_header?(parts)
        parts.present? && parts.size == 2 && parts.first == "Digest"
      end
    end

    # Generate session identifier and store it in cookie (if you enabled :cookie strategy).
    class GenerateSessionIdStrategy < Strategy
      # @return [boolean]
      def success?
        @session_id = Rack::Session::SessionId.new(SecureRandom.hex(16).encode(Encoding::UTF_8))

        add_session_id_to_cookie if config.auth_strategies.include?(:cookie)

        true
      end
    end

    # @param request [ActionDispatch::Request]
    # @return [Rack::Session::SessionId]
    # @raise [AuthError] If cannot read nor generate session_id
    def find_or_init_session(request)
      @use_strategies ||= MultiSessions.config.auth_strategies.filter_map { |key| STRATEGIES[key] }
      strategy = nil

      raise AuthError if @use_strategies.none? { |klass| strategy = klass.result_or_nil(request) }

      strategy.session_id
    end

    STRATEGIES = {
      cookie: CookieStrategy,
      jwt: JwtStrategy,
      generate_session_id: GenerateSessionIdStrategy,
    }.freeze
  end
end
