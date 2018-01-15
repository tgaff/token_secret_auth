require "token_secret_auth/version"
require 'pry'
module TokenSecretAuth
  def decode_token(token)
    decoded = TokenSecretAuth.hash_id.decode(token).first
  end

  def token
    return nil if !id
    encode(id)
  end

  # the model can call this method to generate a new password for the user
  # it should then encrypt this password for storage in db
  def generate_secret
    self.class.generate_secret
  end

  def self.included(base)
    base.extend(ClassMethods)

  end

  # eigenclass
  class << self
    def hash_id
      @hid
    end
    def set_hash_id_instance(salt)
      @hid = Hashids.new(salt, 12)
    end
  end

  module ClassMethods
    require 'hashids'
    attr_reader :hash_ids
    def find_with_token(token)
      begin
        find(TokenSecretAuth.hash_id.decode(token).first)
      rescue Hashids::InputError
        # controller should handle not found when we can't decode bad token
        return find(nil)
      end
    end

    def authenticate_by_credentials(token, secret=nil)
      account = find_with_token(token)
      # note BCrypt's authenticate will return false or the object when matched
      if account
        account.authenticate(secret)
      end
    end

    def generate_secret
      rand(36**secret_length).to_s(36)
    end

    def secret_length
      @secret_length ||= 32
    end

    def hash_id(val)
      TokenSecretAuth.hash_id(val)
    end

    # recommended configuration:
    # TokenSecretAuth.configure do |config|
    #   config.id_salt = 'some appropriate saltiness'
    # end
    def configure
      yield self
      config_hashids
    end

    private
  end
  # salt for the id ONLY,
  # optional config - even if unset the only leak is the id
  @id_salt = 'some appropriate saltiness'

  # mandatory to have a hash_id instance
  TokenSecretAuth.set_hash_id_instance(@id_salt)


  private
  def secret_length
    @secret_length ||= 32
  end

  def encode(value)
    TokenSecretAuth.hash_id.encode(value)
  end

end
