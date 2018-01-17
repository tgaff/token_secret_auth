# TokenSecretAuth

TokenSecretAuth aims to be a simple implementation for ActiveRecord and similar model systems to implement token+secret authentication.

Clients using this can send a token like: `koV3Zel321fe` and a secret like `fffixk5ptz2puaf1sk3wo5szpkrpjnhp`

**token** is generated from the model **id**
**secret** is randomly assigned and **encrypted**

## Why should I use this?

```
OR Why did you release this?
```

While looking for a gem to handle mobile API authentication I found that many solutions fit into one of two categories:

1. Required Devise
1. Did not encrypt the token (or secret) properly

### Why not devise?

Devise is a great solution and I often recommend it.  However, it is sometimes more complexity than needed for something this simple.  TokenSecretAuth does not require devise.

### Why do I need to encrypt my API token?

If your token or token+secret grants a user similar power as a login+password then it should be encrypted with one-way encryption **just like a password**.

### Other benefits

* It's plain-old ruby - any model that responds to `.find(id)` and works with or in a manner similar to `has_secure_password` will work.
*  Flexible: you can send token+secret as part of URL query paramaters or in the header or any other way you can interpret in a controller method.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'token_secret_auth'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install token_secret_auth

In your model file add:

    include TokenSecretAuth
    has_secure_password

This grants your model instances the following methods: 

    #token, #decode_token, #generate_secret

Create and run a migration to add the `password_digest` field to your model.  
For example on rails: 

    $ rails generate migration add_password_digest_to_api_clients password_digest:string
    
Note: you do not need a 'token' field on your model.  `#token` is a virtual attribute derived from the model ID.
    

## Usage

#### Giving token+secret to client

If your application has a login page in which a user logs in and then receives a new API token+secret the responding controller method may look something like this.

```ruby
 def try_login
    @email = login_params[:email]
    @pass  = login_params[:password]
    @user = User.find_by(email: @email).try(:authenticate, @pass)
    if @user
      api_client = ApiClient.create
      # IMPORTANT - this is the only time you can see secret decrypted decrypted
      render json: { token: api_client.token, secret: api_client.secret }
    else
      render json: {password: ["Invalid account or password"]}, status: :unauthorized
    end
  end
```

To perform authentication, for example in an `ApplicationController`:

```ruby
def current_user
  if params[:creds]
    token = credentials_params[:token]
    secret = credentials_params[:secret]
  begin
    api_client = ApiClient.authenticate_by_credentials(token, secret)
  rescue ActiveRecord::RecordNotFound
  # if someone actually manages to guess a hash but it doesn't exist
  end
end

  if api_client
    @current_user = api_client.user
  else
    render json: {errors: ['Unauthorized token or secret']}, status: :unauthorized }
  end
end
```

Headers are an even better way to pass authentication tokens.  **TODO:**

```ruby

```

If you'd like to manually generate a new secret for a specific token.

```ruby
    client = ApiClient.find_by_token('afuoisjdjl')
    client.password = client.generate_secret
    client.save # bcrypt/has_secure_password will handle encryption
```

#### salt

If you'd like to change the salt used for hashing IDs to generate `token`s you can add an initializer:

```ruby
# config/initializers/token_secret_auth.rb

TokenSecretAuth.configure do |config|
    config.id_salt = 'some appropriately salty bytes'
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tgaff/token_secret_auth. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TokenSecretAuth project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/token_secret_auth/blob/master/CODE_OF_CONDUCT.md).
