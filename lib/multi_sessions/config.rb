# frozen_string_literal: true

module MultiSessions
  # Configuration options for sessions management.
  Config =
    Struct.new(
      :auth_strategies,
      :cookies_options,
      :jwt_options,
      :permanent_cookie_name,
      :session_cookie_name,
      :session_model_class,
      :user_model_scope,
      keyword_init: true
    ) do
      # rubocop:disable Lint/ConstantDefinitionInBlock
      DEFAULTS = {
        auth_strategies: %i[cookie jwt generate_session_id].freeze,
        cookies_options: {
          expires: 4.weeks.freeze,
          httponly: true,
          same_site: :strict,
          secure: true,
        }.freeze,
        jwt_options: {secret_key: "1234567890"}.freeze,
        permanent_cookie_name: :current_user_token,
        session_cookie_name: :session_token,
      }.freeze

      REQUIRED = %i[auth_strategies session_model_class user_model_scope].freeze
      REQUIRED_FOR_COOKIE = %i[permanent_cookie_name session_cookie_name].freeze
      REQUIRED_FOR_JWT = %i[jwt_options].freeze
      # rubocop:enable Lint/ConstantDefinitionInBlock

      # @return [Hash<Symbol, Object>]
      def self.default_values
        @not_modifiable ||= DEFAULTS.select { |_k, v| v.is_a?(Enumerable) }.keys

        DEFAULTS.to_h { |k, v| [k, @not_modifiable.include?(k) ? v.dup : v] }
      end

      # @return [Array<Symbol>]
      def required_properties
        res = REQUIRED
        res += REQUIRED_FOR_COOKIE if auth_strategies.include?(:cookie)
        res += REQUIRED_FOR_JWT if auth_strategies.include?(:jwt)
        res
      end

      # @return [Array<Symbol>]
      # @raise [ArgumentError] When required property is not set
      def validate
        required_properties.each do |prop|
          raise ArgumentError, "#{prop} should not be nil" if self[prop].nil?
        end
      end
    end
end
