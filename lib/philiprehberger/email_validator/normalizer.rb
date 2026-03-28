# frozen_string_literal: true

module Philiprehberger
  module EmailValidator
    # Email address normalization.
    #
    # Lowercases, strips whitespace, removes Gmail dots, and strips
    # plus-addressing aliases.
    module Normalizer
      # Gmail-like domains where dots in the local part are ignored.
      GMAIL_DOMAINS = Set.new(%w[gmail.com googlemail.com]).freeze

      class << self
        # Normalize an email address.
        #
        # @param email [String] the email address to normalize
        # @return [String] the normalized email address
        # @raise [Philiprehberger::EmailValidator::Error] if format is invalid
        def normalize(email)
          raise Error, 'email must be a string' unless email.is_a?(String)

          stripped = email.strip.downcase

          raise Error, 'email must not be empty' if stripped.empty?

          parts = stripped.split('@', 2)

          raise Error, 'email must contain exactly one @ symbol' unless parts.length == 2

          local, domain = parts

          raise Error, 'local part must not be empty' if local.empty?
          raise Error, 'domain must not be empty' if domain.empty?

          # Remove plus-addressing alias
          local = local.split('+', 2).first

          # Remove dots from Gmail local parts
          local = local.delete('.') if GMAIL_DOMAINS.include?(domain)

          "#{local}@#{domain}"
        end
      end
    end
  end
end
