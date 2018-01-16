module TokenSecretAuth
  class << self
    require 'hashids'
    # salt for the id ONLY,
    # optional config - even if user doesn't change this
    #   the only possible leak is the id
    DEFAULT_SALT = 'NaCl NaHCO3 NH4ClO3 NaBr MgCl2'

    # TokenSecretAuth.hash_id
    # returns the stored instance of Hashids
    #   used for generating any Token
    def hash_id
      @hid
    end

    # recommended configuration:
    # TokenSecretAuth.configure do |config|
    #   config.id_salt = 'some appropriate saltiness'
    # end
    def configure
      yield self
      @id_salt = DEFAULT_SALT if @id_salt.nil?
      set_hash_id_instance(@id_salt)
    end

    # set salt for hashing IDs
    def id_salt=(salt)
      @id_salt = salt
    end
    protected
    # TokenSecretAuth.set_hash_id_instance
    # call only once
    def set_hash_id_instance(salt)
      @hid = Hashids.new(salt, 12)
    end
  end


  module ClassMethods
    def decode_token(token)
      decoded = TokenSecretAuth.hash_id.decode(token).first
    end

    # .find_with_token
    # Use on model files to find a particular instance based on the token (hashed ID)
    def find_with_token(token)
      begin
        find(decode_token(token))
      rescue Hashids::InputError
        # controller should handle not found when we can't decode bad token
        return find(nil)
      end
    end

    # .authenticate_by_credentials
    # finds correct instance by its token and then authenticates the password for that instance
    def authenticate_by_credentials(token, secret=nil)
      account = find_with_token(token)
      # note BCrypt's authenticate will return false or the object when matched
      if account
        account.authenticate(secret)
      end
    end

    # create a new randomly generated secret
    def generate_secret
      rand(36**secret_length).to_s(36)
    end

    # the default length for a secret
    def secret_length
      @secret_length ||= 32
    end

    private
  end

  def self.included(base)
    base.extend(ClassMethods)
  end


  # Returns the object's ID attribute encoded as a token
  def token
    return nil if !id
    encode(id)
  end

  # the model can call this method to generate a new password for the user
  # it should then encrypt this password for storage in db
  def generate_secret
    self.class.generate_secret
  end


  private
  def secret_length
    @secret_length ||= 32
  end

  def encode(value)
    TokenSecretAuth.hash_id.encode(value)
  end

  self.configure {} # Necessary to perform default setup
end
