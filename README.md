# Database-backed sessions for Rails applications

This gem is not compatible with standard Rails & Rack sessions. Support for them is over-complicated and buggy. If you use this gem, you have to disable standard sessions. To do it, add this line into definition of application in `config/application.rb`:

```ruby
config.session_store(:disabled)
```

This gem uses JWT for user token in Rswag tests & API controllers. You should add configuration for Rswag (if you use Rswag in application) to be able to authorize in Swagger UI with request header (see `swagger_helper.rb`):

```ruby
config.openapi_specs = {
  "v1/swagger.yaml" => {
    components: {securitySchemes: {digest: {name: "Authorization", in: :header, type: :apiKey}}},
    ...
```

This gem expects user token in request header:

```plain
Authorization: Digest user.token.value
```

Example:

```plain
Authorization: Digest eyu58fhfh
# Type "Digest eyu58fhfh" in Swagger UI for authorization.
```

Configuration example for `config/initializers/multi_sessions.rb`:

```ruby
MultiSessions.configure do |config|
  # Default: %i[cookie jwt generate_session_id]
  config.auth_strategies = %i[jwt generate_session_id].freeze

  # Default: true. You may read values from ENV or another configuration source.
  config.cookies_options[:secure] = ENV.fetch("ENABLE_HTTPS", "false") == "true"

  # Default: "1234567890"
  config.jwt_options[:secret_key] = AppConfig.dig(:jwt, :secret_key)

  # Default: :current_user_token
  config.permanent_cookie_name = :account

  # Default: :session_token
  config.session_cookie_name = :sess

  # Default value is not set, you should pass class that behaves like ActiveRecord::Base.
  config.session_model_class = -> { Session }

  # Default value is not set, you should pass instance of ActiveRecord::Relation or
  # descendant class of ActiveRecord::Base.
  config.user_model_scope = -> { Account.users }
end
```

See `MultiSessions::Config` for more information.

Also you may want to change class for imitating object `MultiSessions::Current` in Rails console:

```ruby
if Rails.env.development?
  ActiveSupport::Reloader.to_prepare do
    # Here "User" is your model class (e.g. derived from ActiveRecord::Base) and "admin?" is
    # redefined method in "User" class.
    MultiSessions::MockCurrent.user_model_class =
      Class.new(User) do
        def admin?
          true
        end
      end
  end
end
```

You may use it like so:

```ruby
MultiSessions::MockCurrent.new
MultiSessions::MockCurrent.new(User.new(your_attributes))
```

Also, you may be interested in adding configuration to `Rack::Cors`, see example for `config/initializers/cors.rb`:

```ruby
Rails.application.config.middleware.insert_before(0, Rack::Cors) do
  allow do # For API-only application, JWT.
    origins("*")
    resource("*", expose: ["Authorization"], headers: :any, methods: :any)
  end
end
```

Don't forget to add these gems to `Gemfile` if you need them!

```ruby
gem "jwt"
gem "rack-cors"
gem "rswag-api"
gem "rswag-ui"

group :development, :test do
  gem "rspec-rails"
  gem "rswag-specs"
end
```

All of these dependencies **are not required** for cookie-based sessions.

## Development

Before release — apply suggestions from RuboCop, review them and commit or reject:

```shell
bin/rubocop --autofix
```

Try your gem locally, then commit changes in local repository.

Push new version to remote repository:

```shell
bin/release
```
