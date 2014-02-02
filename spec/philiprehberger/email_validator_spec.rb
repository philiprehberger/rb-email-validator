# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::EmailValidator do
  it 'has a version number' do
    expect(Philiprehberger::EmailValidator::VERSION).not_to be_nil
  end

  describe '.valid?' do
    context 'with valid emails' do
      %w[
        user@example.com
        alice.bob@example.com
        user+tag@example.com
        user@sub.domain.example.com
        firstname.lastname@example.com
        user123@example.com
        _user@example.com
        user!def@example.com
        user%special@example.com
      ].each do |email|
        it "returns true for #{email}" do
          expect(described_class.valid?(email)).to be true
        end
      end
    end

    context 'with invalid emails' do
      [
        '',
        'plaintext',
        '@domain.com',
        'user@',
        'user@@domain.com',
        'user@.com',
        '.user@example.com',
        'user.@example.com',
        'user..name@example.com',
        'user@domain',
        'user@-domain.com',
        'user@domain-.com',
        nil,
        123,
        'user@domain.123'
      ].each do |email|
        it "returns false for #{email.inspect}" do
          expect(described_class.valid?(email)).to be false
        end
      end
    end
  end

  describe '.validate' do
    it 'returns a valid Result for a correct email' do
      result = described_class.validate('user@example.com')

      expect(result).to be_valid
      expect(result.errors).to be_empty
      expect(result.warnings).to be_empty
    end

    it 'returns errors for an invalid email' do
      result = described_class.validate('')

      expect(result).not_to be_valid
      expect(result.errors).to include('email must not be empty')
    end

    it 'returns errors for missing @ symbol' do
      result = described_class.validate('plaintext')

      expect(result).not_to be_valid
      expect(result.errors).to include('email must contain an @ symbol')
    end

    it 'returns errors for empty local part' do
      result = described_class.validate('@example.com')

      expect(result).not_to be_valid
      expect(result.errors).to include('local part must not be empty')
    end

    it 'returns errors for empty domain' do
      result = described_class.validate('user@')

      expect(result).not_to be_valid
      expect(result.errors).to include('domain must not be empty')
    end

    it 'returns errors for consecutive dots in local part' do
      result = described_class.validate('user..name@example.com')

      expect(result).not_to be_valid
      expect(result.errors).to include('local part must not contain consecutive dots')
    end

    it 'returns errors for single-label domain' do
      result = described_class.validate('user@localhost')

      expect(result).not_to be_valid
      expect(result.errors).to include('domain must contain at least two labels')
    end

    context 'with check_mx: true' do
      it 'adds MX error for a non-existent domain' do
        allow(Philiprehberger::EmailValidator::MxCheck).to receive(:valid?).and_return(false)

        result = described_class.validate('user@nonexistent-domain-xyz.example', check_mx: true)

        expect(result).not_to be_valid
        expect(result.errors).to include(match(/has no MX or A records/))
      end

      it 'passes for a domain with MX records' do
        allow(Philiprehberger::EmailValidator::MxCheck).to receive(:valid?).and_return(true)

        result = described_class.validate('user@example.com', check_mx: true)

        expect(result).to be_valid
      end
    end

    context 'with allow_disposable: false' do
      it 'rejects disposable email domains' do
        result = described_class.validate('user@mailinator.com', allow_disposable: false)

        expect(result).not_to be_valid
        expect(result.errors).to include('disposable email domains are not allowed')
      end

      it 'allows non-disposable domains' do
        result = described_class.validate('user@example.com', allow_disposable: false)

        expect(result).to be_valid
      end
    end

    it 'warns about role-based addresses' do
      result = described_class.validate('admin@example.com')

      expect(result).to be_valid
      expect(result.warnings).to include('address appears to be role-based')
    end
  end

  describe '.disposable?' do
    it 'returns true for known disposable domains' do
      expect(described_class.disposable?('user@mailinator.com')).to be true
      expect(described_class.disposable?('user@guerrillamail.com')).to be true
      expect(described_class.disposable?('user@yopmail.com')).to be true
    end

    it 'returns false for non-disposable domains' do
      expect(described_class.disposable?('user@example.com')).to be false
      expect(described_class.disposable?('user@gmail.com')).to be false
    end

    it 'is case-insensitive' do
      expect(described_class.disposable?('user@MAILINATOR.COM')).to be true
    end

    it 'returns false for non-string input' do
      expect(described_class.disposable?(nil)).to be false
      expect(described_class.disposable?(123)).to be false
    end
  end

  describe '.role_based?' do
    it 'returns true for role-based local parts' do
      %w[admin info support postmaster webmaster abuse noreply].each do |local|
        expect(described_class.role_based?("#{local}@example.com")).to be true
      end
    end

    it 'returns false for personal addresses' do
      expect(described_class.role_based?('john@example.com')).to be false
      expect(described_class.role_based?('alice.smith@example.com')).to be false
    end

    it 'is case-insensitive' do
      expect(described_class.role_based?('ADMIN@example.com')).to be true
      expect(described_class.role_based?('Info@example.com')).to be true
    end

    it 'returns false for non-string input' do
      expect(described_class.role_based?(nil)).to be false
    end
  end

  describe '.mx_valid?' do
    it 'delegates to MxCheck.valid?' do
      allow(Philiprehberger::EmailValidator::MxCheck).to receive(:valid?).with('example.com').and_return(true)

      expect(described_class.mx_valid?('example.com')).to be true
      expect(Philiprehberger::EmailValidator::MxCheck).to have_received(:valid?).with('example.com')
    end
  end
end

RSpec.describe Philiprehberger::EmailValidator::Syntax do
  describe '.validate' do
    it 'returns empty array for valid email' do
      expect(described_class.validate('user@example.com')).to eq([])
    end

    it 'rejects email exceeding max length' do
      long_local = 'a' * 65
      errors = described_class.validate("#{long_local}@example.com")

      expect(errors).to include(match(/local part exceeds maximum length/))
    end

    it 'rejects domain exceeding max length' do
      long_domain = "#{'a' * 64}.#{'b' * 64}.#{'c' * 64}.#{'d' * 64}.com"
      errors = described_class.validate("user@#{long_domain}")

      expect(errors).to include(match(/domain exceeds maximum length/))
    end

    it 'rejects domain label exceeding max length' do
      long_label = 'a' * 64
      errors = described_class.validate("user@#{long_label}.com")

      expect(errors).to include(match(/domain label .* exceeds maximum length/))
    end

    it 'rejects all-numeric TLD' do
      errors = described_class.validate('user@domain.123')

      expect(errors).to include('top-level domain must not be all numeric')
    end
  end
end

RSpec.describe Philiprehberger::EmailValidator::MxCheck do
  describe '.valid?' do
    it 'returns false for nil domain' do
      expect(described_class.valid?(nil)).to be false
    end

    it 'returns false for empty domain' do
      expect(described_class.valid?('')).to be false
    end

    it 'returns true when MX records exist' do
      resolver = instance_double(Resolv::DNS)
      allow(Resolv::DNS).to receive(:new).and_return(resolver)
      allow(resolver).to receive(:timeouts=)
      allow(resolver).to receive(:close)

      mx_record = Resolv::DNS::Resource::IN::MX.new(10, Resolv::DNS::Name.create('mail.example.com'))
      allow(resolver).to receive(:getresources)
        .with('example.com', Resolv::DNS::Resource::IN::MX)
        .and_return([mx_record])

      expect(described_class.valid?('example.com')).to be true
    end

    it 'falls back to A records when no MX records exist' do
      resolver = instance_double(Resolv::DNS)
      allow(Resolv::DNS).to receive(:new).and_return(resolver)
      allow(resolver).to receive(:timeouts=)
      allow(resolver).to receive(:close)
      allow(resolver).to receive(:getresources)
        .with('example.com', Resolv::DNS::Resource::IN::MX)
        .and_return([])

      a_record = Resolv::DNS::Resource::IN::A.new('93.184.216.34')
      allow(resolver).to receive(:getresources)
        .with('example.com', Resolv::DNS::Resource::IN::A)
        .and_return([a_record])

      expect(described_class.valid?('example.com')).to be true
    end

    it 'returns false when neither MX nor A records exist' do
      resolver = instance_double(Resolv::DNS)
      allow(Resolv::DNS).to receive(:new).and_return(resolver)
      allow(resolver).to receive(:timeouts=)
      allow(resolver).to receive(:close)
      allow(resolver).to receive(:getresources).and_return([])

      expect(described_class.valid?('nonexistent.example')).to be false
    end
  end

  describe '.mx_records' do
    it 'returns sorted MX hostnames' do
      resolver = instance_double(Resolv::DNS)
      allow(Resolv::DNS).to receive(:new).and_return(resolver)
      allow(resolver).to receive(:timeouts=)
      allow(resolver).to receive(:close)

      mx1 = Resolv::DNS::Resource::IN::MX.new(20, Resolv::DNS::Name.create('mail2.example.com'))
      mx2 = Resolv::DNS::Resource::IN::MX.new(10, Resolv::DNS::Name.create('mail1.example.com'))
      allow(resolver).to receive(:getresources)
        .with('example.com', Resolv::DNS::Resource::IN::MX)
        .and_return([mx1, mx2])

      records = described_class.mx_records('example.com')

      expect(records).to eq(['mail1.example.com', 'mail2.example.com'])
    end

    it 'returns empty array for nil domain' do
      expect(described_class.mx_records(nil)).to eq([])
    end
  end
end

RSpec.describe Philiprehberger::EmailValidator::Disposable do
  describe '.disposable?' do
    it 'detects known disposable domains' do
      expect(described_class.disposable?('user@mailinator.com')).to be true
      expect(described_class.disposable?('user@tempmail.com')).to be true
    end

    it 'returns false for regular domains' do
      expect(described_class.disposable?('user@gmail.com')).to be false
    end
  end

  describe '.domain_disposable?' do
    it 'checks domain directly' do
      expect(described_class.domain_disposable?('mailinator.com')).to be true
      expect(described_class.domain_disposable?('gmail.com')).to be false
    end
  end
end

RSpec.describe Philiprehberger::EmailValidator::Result do
  it 'is valid when no errors' do
    result = described_class.new

    expect(result).to be_valid
    expect(result.errors).to eq([])
    expect(result.warnings).to eq([])
  end

  it 'is invalid when errors present' do
    result = described_class.new(errors: ['something wrong'])

    expect(result).not_to be_valid
    expect(result.errors).to eq(['something wrong'])
  end

  it 'includes warnings without affecting validity' do
    result = described_class.new(warnings: ['heads up'])

    expect(result).to be_valid
    expect(result.warnings).to eq(['heads up'])
  end

  it 'is frozen' do
    result = described_class.new

    expect(result).to be_frozen
    expect(result.errors).to be_frozen
    expect(result.warnings).to be_frozen
  end

  it 'has a readable string representation' do
    valid_result = described_class.new
    expect(valid_result.to_s).to include('valid')

    invalid_result = described_class.new(errors: ['bad'])
    expect(invalid_result.to_s).to include('invalid')
  end
end
