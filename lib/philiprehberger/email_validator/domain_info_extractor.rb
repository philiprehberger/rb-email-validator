# frozen_string_literal: true

module Philiprehberger
  module EmailValidator
    # Domain metadata extraction from email addresses.
    #
    # Extracts domain, TLD, and optionally MX records for
    # analytics and domain-based routing.
    module DomainInfoExtractor
      class << self
        # Extract domain information from an email address.
        #
        # @param email [String] the email address to analyze
        # @param check_mx [Boolean] whether to look up MX records (default: false)
        # @return [Hash] { domain:, tld:, mx_records: }
        # @raise [Philiprehberger::EmailValidator::Error] if format is invalid
        def extract(email, check_mx: false)
          raise Error, 'email must be a string' unless email.is_a?(String)

          stripped = email.strip

          raise Error, 'email must not be empty' if stripped.empty?

          parts = stripped.split('@', 2)

          raise Error, 'email must contain exactly one @ symbol' unless parts.length == 2

          domain = parts[1]

          raise Error, 'domain must not be empty' if domain.nil? || domain.empty?

          domain_lower = domain.downcase
          labels = domain_lower.split('.')
          tld = labels.last

          info = {
            domain: domain_lower,
            tld: tld
          }

          info[:mx_records] = MxCheck.mx_records(domain_lower) if check_mx

          info
        end
      end
    end
  end
end
