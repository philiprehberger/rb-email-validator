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

  describe '.validate_all' do
    it 'validates an array of emails and returns array of Results' do
      emails = ['user@example.com', 'invalid', 'alice@example.com']
      results = described_class.validate_all(emails)

      expect(results).to be_an(Array)
      expect(results.length).to eq(3)
      expect(results[0]).to be_valid
      expect(results[1]).not_to be_valid
      expect(results[2]).to be_valid
    end

    it 'returns empty array for empty input' do
      results = described_class.validate_all([])

      expect(results).to eq([])
    end

    it 'passes options through to validate' do
      emails = ['user@mailinator.com', 'user@example.com']
      results = described_class.validate_all(emails, allow_disposable: false)

      expect(results[0]).not_to be_valid
      expect(results[0].errors).to include('disposable email domains are not allowed')
      expect(results[1]).to be_valid
    end

    it 'passes check_mx option through' do
      allow(Philiprehberger::EmailValidator::MxCheck).to receive(:valid?).and_return(false)

      results = described_class.validate_all(['user@example.com'], check_mx: true)

      expect(results[0]).not_to be_valid
    end

    it 'handles mixed valid and invalid emails' do
      emails = ['', 'user@example.com', 'bad@@email', 'admin@example.com']
      results = described_class.validate_all(emails)

      expect(results[0]).not_to be_valid
      expect(results[1]).to be_valid
      expect(results[2]).not_to be_valid
      expect(results[3]).to be_valid
      expect(results[3].warnings).to include('address appears to be role-based')
    end
  end

  describe '.batch_validate' do
    it 'returns a hash mapping each email to its Result' do
      emails = ['user@example.com', 'invalid', 'alice@example.com']
      results = described_class.batch_validate(emails)

      expect(results).to be_a(Hash)
      expect(results.keys).to eq(emails)
      expect(results['user@example.com']).to be_valid
      expect(results['invalid']).not_to be_valid
      expect(results['alice@example.com']).to be_valid
    end

    it 'returns empty hash for empty input' do
      results = described_class.batch_validate([])

      expect(results).to eq({})
    end

    it 'passes options through to validate' do
      emails = ['user@mailinator.com', 'user@example.com']
      results = described_class.batch_validate(emails, allow_disposable: false)

      expect(results['user@mailinator.com']).not_to be_valid
      expect(results['user@mailinator.com'].errors).to include('disposable email domains are not allowed')
      expect(results['user@example.com']).to be_valid
    end

    it 'passes check_mx option through' do
      allow(Philiprehberger::EmailValidator::MxCheck).to receive(:valid?).and_return(false)

      results = described_class.batch_validate(['user@example.com'], check_mx: true)

      expect(results['user@example.com']).not_to be_valid
    end

    it 'handles duplicate emails by keeping the last result' do
      emails = ['user@example.com', 'invalid', 'user@example.com']
      results = described_class.batch_validate(emails)

      expect(results.keys).to eq(['user@example.com', 'invalid'])
      expect(results['user@example.com']).to be_valid
    end

    it 'handles mixed valid and invalid emails with warnings' do
      emails = ['', 'user@example.com', 'bad@@email', 'admin@example.com']
      results = described_class.batch_validate(emails)

      expect(results['']).not_to be_valid
      expect(results['user@example.com']).to be_valid
      expect(results['bad@@email']).not_to be_valid
      expect(results['admin@example.com']).to be_valid
      expect(results['admin@example.com'].warnings).to include('address appears to be role-based')
    end
  end

  describe '.valid_all?' do
    it 'returns true when all emails are valid' do
      emails = ['user@example.com', 'alice@example.com', 'bob@example.com']

      expect(described_class.valid_all?(emails)).to be true
    end

    it 'returns false when any email is invalid' do
      emails = ['user@example.com', 'invalid', 'alice@example.com']

      expect(described_class.valid_all?(emails)).to be false
    end

    it 'returns true for empty array' do
      expect(described_class.valid_all?([])).to be true
    end

    it 'returns false when first email is invalid' do
      expect(described_class.valid_all?(['bad', 'user@example.com'])).to be false
    end

    it 'returns false when last email is invalid' do
      expect(described_class.valid_all?(['user@example.com', 'bad'])).to be false
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

  describe '.configure and .reset_configuration!' do
    after do
      described_class.reset_configuration!
    end

    it 'allows adding custom disposable domains' do
      described_class.configure do |config|
        config.add_disposable_domains(['custom-temp.com'])
      end

      expect(described_class.disposable?('user@custom-temp.com')).to be true
    end

    it 'allows removing built-in disposable domains' do
      expect(described_class.disposable?('user@mailinator.com')).to be true

      described_class.configure do |config|
        config.remove_disposable_domains(['mailinator.com'])
      end

      expect(described_class.disposable?('user@mailinator.com')).to be false
    end

    it 'resets configuration to defaults' do
      described_class.configure do |config|
        config.add_disposable_domains(['custom-temp.com'])
        config.remove_disposable_domains(['mailinator.com'])
      end

      described_class.reset_configuration!

      expect(described_class.disposable?('user@custom-temp.com')).to be false
      expect(described_class.disposable?('user@mailinator.com')).to be true
    end

    it 'affects validation with allow_disposable: false' do
      described_class.configure do |config|
        config.add_disposable_domains(['my-temp-domain.com'])
      end

      result = described_class.validate('user@my-temp-domain.com', allow_disposable: false)

      expect(result).not_to be_valid
      expect(result.errors).to include('disposable email domains are not allowed')
    end

    it 'handles multiple configure calls' do
      described_class.configure do |config|
        config.add_disposable_domains(['temp1.com'])
      end

      described_class.configure do |config|
        config.add_disposable_domains(['temp2.com'])
      end

      expect(described_class.disposable?('user@temp1.com')).to be true
      expect(described_class.disposable?('user@temp2.com')).to be true
    end
  end

  describe '.canonical_equal?' do
    it 'returns true for two identical addresses' do
      expect(described_class.canonical_equal?('user@example.com', 'user@example.com')).to be true
    end

    it 'returns true for Gmail dot variants' do
      expect(described_class.canonical_equal?('foo.bar@gmail.com', 'foobar@gmail.com')).to be true
    end

    it 'returns true when one side uses a plus-alias' do
      expect(described_class.canonical_equal?('foo+tag@example.com', 'foo@example.com')).to be true
    end

    it 'returns true for case-only differences' do
      expect(described_class.canonical_equal?('User@Example.COM', 'user@example.com')).to be true
    end

    it 'returns false for completely different addresses' do
      expect(described_class.canonical_equal?('alice@example.com', 'bob@example.com')).to be false
    end

    it 'returns false for nil input instead of raising' do
      expect { described_class.canonical_equal?(nil, 'user@example.com') }.not_to raise_error
      expect(described_class.canonical_equal?(nil, 'user@example.com')).to be false
    end

    it 'returns false for empty string input instead of raising' do
      expect(described_class.canonical_equal?('', 'user@example.com')).to be false
    end

    it 'returns false for malformed syntax on either side' do
      expect(described_class.canonical_equal?('not-an-email', 'user@example.com')).to be false
      expect(described_class.canonical_equal?('user@example.com', '@bad')).to be false
    end
  end

  describe '.extract_tag' do
    it 'returns the tag for a Gmail address with a plus tag' do
      expect(described_class.extract_tag('user+promo@gmail.com')).to eq('promo')
    end

    it 'returns nil when no tag is present' do
      expect(described_class.extract_tag('user@gmail.com')).to be_nil
    end

    it 'returns nil for a completely invalid email' do
      expect(described_class.extract_tag('invalid')).to be_nil
    end

    it 'returns nil for non-string input' do
      expect(described_class.extract_tag(nil)).to be_nil
      expect(described_class.extract_tag(123)).to be_nil
    end

    it 'returns nil for an empty string' do
      expect(described_class.extract_tag('')).to be_nil
    end

    it 'returns nil when the local part is empty' do
      expect(described_class.extract_tag('@gmail.com')).to be_nil
    end

    it 'returns nil when the domain is empty' do
      expect(described_class.extract_tag('user+promo@')).to be_nil
    end

    it 'treats only the first + as the separator for multiple plus signs' do
      expect(described_class.extract_tag('user+a+b@gmail.com')).to eq('a+b')
    end

    it 'returns an empty string tag for a bare + with no suffix' do
      expect(described_class.extract_tag('user+@gmail.com')).to eq('')
    end
  end

  describe '.strip_tag' do
    it 'strips the tag from a Gmail address' do
      expect(described_class.strip_tag('user+promo@gmail.com')).to eq('user@gmail.com')
    end

    it 'strips the tag from a non-Gmail address (generic sub-addressing)' do
      expect(described_class.strip_tag('user+promo@example.com')).to eq('user@example.com')
    end

    it 'returns the email unchanged when no tag is present' do
      expect(described_class.strip_tag('user@gmail.com')).to eq('user@gmail.com')
    end

    it 'preserves domain case' do
      expect(described_class.strip_tag('user+promo@Example.COM')).to eq('user@Example.COM')
    end

    it 'returns the original value unchanged for invalid input' do
      expect(described_class.strip_tag('invalid')).to eq('invalid')
      expect(described_class.strip_tag('')).to eq('')
      expect(described_class.strip_tag('@gmail.com')).to eq('@gmail.com')
      expect(described_class.strip_tag('user@')).to eq('user@')
    end

    it 'returns non-string input unchanged' do
      expect(described_class.strip_tag(nil)).to be_nil
      expect(described_class.strip_tag(123)).to eq(123)
    end

    it 'treats only the first + as the separator for multiple plus signs' do
      expect(described_class.strip_tag('user+a+b@gmail.com')).to eq('user@gmail.com')
    end

    it 'handles a bare + with no suffix' do
      expect(described_class.strip_tag('user+@gmail.com')).to eq('user@gmail.com')
    end
  end

  describe '.split' do
    it 'returns local, domain, and tag for a tagged address' do
      expect(described_class.split('user+work@example.com')).to eq(
        local: 'user', domain: 'example.com', tag: 'work'
      )
    end

    it 'returns nil tag when no plus is present' do
      expect(described_class.split('user@example.com')).to eq(
        local: 'user', domain: 'example.com', tag: nil
      )
    end

    it 'preserves trailing tag content after the first plus' do
      expect(described_class.split('user+a+b@example.com')).to eq(
        local: 'user', domain: 'example.com', tag: 'a+b'
      )
    end

    it 'preserves domain case' do
      expect(described_class.split('user@Example.COM')[:domain]).to eq('Example.COM')
    end

    it 'returns nil for missing @' do
      expect(described_class.split('userexample.com')).to be_nil
    end

    it 'returns nil for empty local or domain' do
      expect(described_class.split('@example.com')).to be_nil
      expect(described_class.split('user@')).to be_nil
    end

    it 'returns nil for non-string input' do
      expect(described_class.split(nil)).to be_nil
      expect(described_class.split(123)).to be_nil
    end
  end

  describe '.normalize' do
    it 'lowercases the entire email' do
      expect(described_class.normalize('USER@EXAMPLE.COM')).to eq('user@example.com')
    end

    it 'trims whitespace' do
      expect(described_class.normalize('  user@example.com  ')).to eq('user@example.com')
    end

    it 'removes plus-addressing aliases' do
      expect(described_class.normalize('user+tag@example.com')).to eq('user@example.com')
    end

    it 'removes dots from Gmail local parts' do
      expect(described_class.normalize('jo.hn@gmail.com')).to eq('john@gmail.com')
    end

    it 'removes dots from googlemail.com local parts' do
      expect(described_class.normalize('jo.hn@googlemail.com')).to eq('john@googlemail.com')
    end

    it 'does not remove dots from non-Gmail domains' do
      expect(described_class.normalize('first.last@example.com')).to eq('first.last@example.com')
    end

    it 'handles combined Gmail normalization' do
      expect(described_class.normalize('Jo.Hn+spam@Gmail.com')).to eq('john@gmail.com')
    end

    it 'handles plus tag with no suffix' do
      expect(described_class.normalize('user+@example.com')).to eq('user@example.com')
    end

    it 'raises on non-string input' do
      expect { described_class.normalize(nil) }.to raise_error(Philiprehberger::EmailValidator::Error)
    end

    it 'raises on empty string' do
      expect { described_class.normalize('') }.to raise_error(Philiprehberger::EmailValidator::Error)
    end

    it 'raises on missing @ symbol' do
      expect { described_class.normalize('plaintext') }.to raise_error(Philiprehberger::EmailValidator::Error)
    end

    it 'raises on empty local part' do
      expect { described_class.normalize('@example.com') }.to raise_error(Philiprehberger::EmailValidator::Error)
    end

    it 'raises on empty domain' do
      expect { described_class.normalize('user@') }.to raise_error(Philiprehberger::EmailValidator::Error)
    end

    it 'handles whitespace-only input' do
      expect { described_class.normalize('   ') }.to raise_error(Philiprehberger::EmailValidator::Error)
    end
  end

  describe '.suggest' do
    it 'suggests gmail.com for gmial.com' do
      result = described_class.suggest('user@gmial.com')

      expect(result).not_to be_nil
      expect(result[:suggested]).to eq('user@gmail.com')
      expect(result[:original]).to eq('user@gmial.com')
    end

    it 'suggests yahoo.com for yaho.com' do
      result = described_class.suggest('user@yaho.com')

      expect(result).not_to be_nil
      expect(result[:suggested]).to eq('user@yahoo.com')
    end

    it 'suggests hotmail.com for hotmal.com' do
      result = described_class.suggest('user@hotmal.com')

      expect(result).not_to be_nil
      expect(result[:suggested]).to eq('user@hotmail.com')
    end

    it 'suggests outlook.com for outlok.com' do
      result = described_class.suggest('user@outlok.com')

      expect(result).not_to be_nil
      expect(result[:suggested]).to eq('user@outlook.com')
    end

    it 'suggests gmail.com for gmal.com' do
      result = described_class.suggest('user@gmal.com')

      expect(result).not_to be_nil
      expect(result[:suggested]).to eq('user@gmail.com')
    end

    it 'returns nil for correct domains' do
      expect(described_class.suggest('user@gmail.com')).to be_nil
      expect(described_class.suggest('user@yahoo.com')).to be_nil
    end

    it 'returns nil for unknown domains' do
      expect(described_class.suggest('user@mycustomdomain.com')).to be_nil
    end

    it 'returns nil for non-string input' do
      expect(described_class.suggest(nil)).to be_nil
      expect(described_class.suggest(123)).to be_nil
    end

    it 'returns nil for malformed input' do
      expect(described_class.suggest('plaintext')).to be_nil
      expect(described_class.suggest('@')).to be_nil
    end

    it 'preserves the local part in the suggestion' do
      result = described_class.suggest('alice+tag@gmial.com')

      expect(result[:suggested]).to eq('alice+tag@gmail.com')
    end

    it 'returns nil when distance is too large' do
      expect(described_class.suggest('user@xxxxxxxxx.com')).to be_nil
    end
  end

  describe '.domain_info' do
    it 'extracts domain and TLD' do
      info = described_class.domain_info('user@example.com')

      expect(info[:domain]).to eq('example.com')
      expect(info[:tld]).to eq('com')
    end

    it 'handles subdomains' do
      info = described_class.domain_info('user@mail.sub.example.co.uk')

      expect(info[:domain]).to eq('mail.sub.example.co.uk')
      expect(info[:tld]).to eq('uk')
    end

    it 'lowercases the domain' do
      info = described_class.domain_info('user@EXAMPLE.COM')

      expect(info[:domain]).to eq('example.com')
    end

    it 'does not include mx_records by default' do
      info = described_class.domain_info('user@example.com')

      expect(info).not_to have_key(:mx_records)
    end

    it 'includes mx_records when check_mx is true' do
      allow(Philiprehberger::EmailValidator::MxCheck).to receive(:mx_records)
        .with('example.com')
        .and_return(['mail.example.com'])

      info = described_class.domain_info('user@example.com', check_mx: true)

      expect(info[:mx_records]).to eq(['mail.example.com'])
    end

    it 'raises on non-string input' do
      expect { described_class.domain_info(nil) }.to raise_error(Philiprehberger::EmailValidator::Error)
    end

    it 'raises on empty string' do
      expect { described_class.domain_info('') }.to raise_error(Philiprehberger::EmailValidator::Error)
    end

    it 'raises on missing @ symbol' do
      expect { described_class.domain_info('plaintext') }.to raise_error(Philiprehberger::EmailValidator::Error)
    end

    it 'raises on empty domain' do
      expect { described_class.domain_info('user@') }.to raise_error(Philiprehberger::EmailValidator::Error)
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

RSpec.describe Philiprehberger::EmailValidator::Configuration do
  subject(:config) { described_class.new }

  it 'starts with empty added domains' do
    expect(config.added_disposable_domains).to be_empty
  end

  it 'starts with empty removed domains' do
    expect(config.removed_disposable_domains).to be_empty
  end

  it 'adds disposable domains' do
    config.add_disposable_domains(['test.com', 'temp.org'])

    expect(config.added_disposable_domains).to include('test.com', 'temp.org')
  end

  it 'removes disposable domains' do
    config.remove_disposable_domains(['mailinator.com'])

    expect(config.removed_disposable_domains).to include('mailinator.com')
  end

  it 'lowercases added domains' do
    config.add_disposable_domains(['TEST.COM'])

    expect(config.added_disposable_domains).to include('test.com')
  end

  it 'lowercases removed domains' do
    config.remove_disposable_domains(['MAILINATOR.COM'])

    expect(config.removed_disposable_domains).to include('mailinator.com')
  end

  it 'returns effective domains including added and excluding removed' do
    config.add_disposable_domains(['custom-temp.com'])
    config.remove_disposable_domains(['mailinator.com'])

    effective = config.effective_disposable_domains

    expect(effective).to include('custom-temp.com')
    expect(effective).not_to include('mailinator.com')
    expect(effective).to include('guerrillamail.com')
  end
end

RSpec.describe Philiprehberger::EmailValidator::Normalizer do
  describe '.normalize' do
    it 'lowercases everything' do
      expect(described_class.normalize('USER@EXAMPLE.COM')).to eq('user@example.com')
    end

    it 'strips whitespace' do
      expect(described_class.normalize('  user@example.com  ')).to eq('user@example.com')
    end

    it 'removes plus aliases' do
      expect(described_class.normalize('user+newsletter@example.com')).to eq('user@example.com')
    end

    it 'removes Gmail dots' do
      expect(described_class.normalize('j.o.h.n@gmail.com')).to eq('john@gmail.com')
    end

    it 'does not remove dots for non-Gmail' do
      expect(described_class.normalize('j.o.h.n@example.com')).to eq('j.o.h.n@example.com')
    end

    it 'handles combined normalization' do
      expect(described_class.normalize('  J.O.H.N+spam@GMAIL.COM  ')).to eq('john@gmail.com')
    end

    it 'raises for nil' do
      expect { described_class.normalize(nil) }.to raise_error(Philiprehberger::EmailValidator::Error)
    end

    it 'raises for empty' do
      expect { described_class.normalize('') }.to raise_error(Philiprehberger::EmailValidator::Error)
    end

    it 'raises for no @ symbol' do
      expect { described_class.normalize('nope') }.to raise_error(Philiprehberger::EmailValidator::Error)
    end
  end
end

RSpec.describe Philiprehberger::EmailValidator::TypoSuggester do
  describe '.suggest' do
    it 'suggests gmail.com for gmial.com' do
      result = described_class.suggest('user@gmial.com')

      expect(result[:suggested]).to eq('user@gmail.com')
    end

    it 'suggests yahoo.com for yaho.com' do
      result = described_class.suggest('user@yaho.com')

      expect(result[:suggested]).to eq('user@yahoo.com')
    end

    it 'returns nil for correct domains' do
      expect(described_class.suggest('user@gmail.com')).to be_nil
    end

    it 'returns nil for distant domains' do
      expect(described_class.suggest('user@totallyunknown.com')).to be_nil
    end

    it 'returns nil for nil input' do
      expect(described_class.suggest(nil)).to be_nil
    end
  end
end

RSpec.describe Philiprehberger::EmailValidator::DomainInfoExtractor do
  describe '.extract' do
    it 'extracts domain and tld' do
      info = described_class.extract('user@example.com')

      expect(info[:domain]).to eq('example.com')
      expect(info[:tld]).to eq('com')
    end

    it 'handles multi-level domains' do
      info = described_class.extract('user@sub.example.co.uk')

      expect(info[:domain]).to eq('sub.example.co.uk')
      expect(info[:tld]).to eq('uk')
    end

    it 'does not include mx_records by default' do
      info = described_class.extract('user@example.com')

      expect(info).not_to have_key(:mx_records)
    end

    it 'includes mx_records when requested' do
      allow(Philiprehberger::EmailValidator::MxCheck).to receive(:mx_records)
        .with('example.com')
        .and_return(['mx1.example.com'])

      info = described_class.extract('user@example.com', check_mx: true)

      expect(info[:mx_records]).to eq(['mx1.example.com'])
    end

    it 'raises for invalid input' do
      expect { described_class.extract(nil) }.to raise_error(Philiprehberger::EmailValidator::Error)
      expect { described_class.extract('') }.to raise_error(Philiprehberger::EmailValidator::Error)
      expect { described_class.extract('nope') }.to raise_error(Philiprehberger::EmailValidator::Error)
    end
  end
end
