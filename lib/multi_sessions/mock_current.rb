# frozen_string_literal: true

module MultiSessions
  # Imitate object MultiSessions::Current for Rails console.
  class MockCurrent
    StructWithId = Struct.new(:id, keyword_init: true)

    thread_mattr_accessor :user_model_class, default: StructWithId

    attr_accessor :id, :jwt, :session_id, :session_model, :user_model

    # @param user [Object] Responds to `id`
    def initialize(user = nil)
      @user_model = user || self.class.user_model_class.new(id: rand(1000))
      @id = @user_model.id
    end

    # @return [boolean]
    def authorized?
      !id.nil?
    end

    # @return [void]
    def clear
      @id = nil
      @jwt = nil
      @session_id = nil
      @session_model = nil
      @user_model = nil
    end

    # @return [void]
    def finalize_session
      nil
    end

    # @return [void]
    def save_user_id_into_cookie
      nil
    end
  end
end
