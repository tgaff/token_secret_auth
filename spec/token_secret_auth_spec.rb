require "spec_helper"

RSpec.describe TokenSecretAuth do

  class Includer
    include TokenSecretAuth
    def self.find(v); end
  end
  let(:includer) do
    Includer.new
  end

  describe '#decode_token' do
    let(:encoded) { Includer.new.send(:encode, 4002) }

    it 'properly decodes the token' do
      expect(includer.decode_token(encoded)).to eq 4002
    end
  end

  describe '#token' do
    let(:klass) do
      Struct.new(:id) do
        include TokenSecretAuth
      end
    end
    let(:test_object) { klass.new(123321) }

    it 'returns the id encoded' do
      expect(test_object.token).to eq 'bRevJzqDJvyY'
    end
  end

  describe 'generate_secret' do
    it 'generates a new secret' do
      expect(includer.generate_secret).to_not eq includer.generate_secret
    end

    it 'generates a secret with length usually ~32' do
      keys = 10.times.map { includer.generate_secret.length }
      mean = keys.inject(0, :+) / 10
      # if this fails it's either a bug or your lucky day
      expect(mean).to be_between(30,32)
    end
  end

  describe 'ClassMethods' do
    describe '.generate_secret' do
      it 'generates a new secret' do
        expect(Includer.generate_secret).to_not eq Includer.generate_secret
      end

      it 'generates a secret with length usually ~32' do
        keys = 10.times.map { Includer.generate_secret.length }
        mean = keys.inject(0, :+) / 10
        # if this fails it's either a bug or your lucky day
        expect(mean).to be_between(30,32)
      end
    end

    describe '.find_with_token' do
      it 'finds records by token' do
        expect(Includer).to receive(:find).with(42)
        token = TokenSecretAuth.hash_id.encode 42
        Includer.find_with_token(token)
      end

      it 'searches for nil if the token is invalid' do
        expect(Includer).to receive(:find).with(nil)
        Includer.find_with_token('lvrKq----a')
      end
    end

    describe '.authenticate_by_credentials' do
      class FriendlyFox
        include TokenSecretAuth
        def authenticate(secret) # mock for BCrypt authenticate
          secret == 'secret' ? 'ok' : false
        end
        def self.find(x); end
      end

      let (:double_instance) do
        double = FriendlyFox.new
      end

      before do
        allow(FriendlyFox).to receive(:find_with_token).with('lvrKqvNqR58a')
            .and_return(double_instance)
      end

      it 'finds the right record' do
        expect(FriendlyFox.authenticate_by_credentials('lvrKqvNqR58a', 'secret')).to eq 'ok'
      end

      it "returns false if the secret doesn't match" do
        expect(FriendlyFox.authenticate_by_credentials('lvrKqvNqR58a', 'asldkfjklj')).to eq false
      end
    end
  end
end
