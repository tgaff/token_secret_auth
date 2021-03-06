require "spec_helper"

RSpec.describe TokenSecretAuth do

  class Includer
    attr_reader :password
    include TokenSecretAuth
    def self.find(v); end
    def password=(pw)
      @password = pw # this is normally provided by Bcrypt
    end
  end
  let(:includer) do
    Includer.new
  end

  describe '#token' do
    let(:klass) do
      Struct.new(:id) do
        include TokenSecretAuth
      end
    end
    let(:test_object) { klass.new(123321) }

    it 'returns the id encoded' do
      expect(test_object.token).to eq 'koV3ZELzj0rg'
    end
  end

  describe '#generate_secret' do
    it 'generates a new secret' do
      expect(includer.generate_secret).to_not eq includer.generate_secret
    end

    it 'generates a secret with length ~32' do
      keys = 10.times.map { includer.generate_secret.length }
      mean = keys.inject(0, :+) / 10
      # if this fails it's either a bug or your lucky day
      expect(mean).to be_between(31,32)
    end

    it 'stores the secret as password' do
      expect{includer.generate_secret}.to change{includer.password}.from(nil).to an_instance_of(String)
    end
  end

  describe 'ClassMethods' do

    describe '.decode_token' do
      let(:encoded) { Includer.new.send(:encode, 4002) }

      it 'properly decodes the token' do
        expect(Includer.decode_token(encoded)).to eq 4002
      end
    end

    describe '.generate_secret' do
      it 'generates a new secret' do
        expect(Includer.generate_secret).to_not eq Includer.generate_secret
      end

      it 'generates a secret with length ~32' do
        keys = 10.times.map { Includer.generate_secret.length }
        mean = keys.inject(0, :+) / 10
        # if this fails it's either a bug or your lucky day
        expect(mean).to be_between(31,32)
      end
    end

    describe '.find_by_token' do
      it 'finds records by token' do
        expect(Includer).to receive(:find).with(42)
        token = TokenSecretAuth.hash_id.encode 42
        Includer.find_by_token(token)
      end

      it 'searches for nil if the token is invalid' do
        expect(Includer).to receive(:find).with(nil)
        Includer.find_by_token('lvrKq----a')
      end
    end

    describe '.authenticate_by_credentials' do
      class FriendlyFox
        include TokenSecretAuth
        def id; 33; end
        def authenticate(secret) # mock for BCrypt authenticate
          secret == 'secret' ? self : nil
        end
        #require 'pry'
        #def self.find(x); binding.pry; end
      end

      let (:double_instance) do
        double = FriendlyFox.new
      end

      before do
        allow(FriendlyFox).to receive(:find).with(33)
          .and_return(FriendlyFox.new)
      end

      it 'finds the right record and returns it' do
        expect(FriendlyFox.authenticate_by_credentials('NGKb0Y8nxmjo', 'secret')).to be_an_instance_of FriendlyFox
      end

      it "returns nil if the secret doesn't match" do # technically Bcrypt functionality
        expect(FriendlyFox.authenticate_by_credentials('NGKb0Y8nxmjo', 'asldkfjklj')).to eq nil
      end
    end

    describe 'configure' do
      it "updates the hash_id instance using the new salt" do
        current_hid = TokenSecretAuth.hash_id
        TokenSecretAuth.configure do |config|
          config.id_salt = 'lsdakjflksdjflksdjf'
        end
        expect(TokenSecretAuth.hash_id).to_not eq current_hid
      end
    end
  end
end
