# frozen_string_literal: true

module Philiprehberger
  module EmailValidator
    # RFC 5322 compliant email syntax validation.
    #
    # Validates local part rules, domain rules, and length limits
    # according to the relevant RFCs (5321, 5322).
    module Syntax
      # Maximum total length of an email address (RFC 5321).
      MAX_EMAIL_LENGTH = 254

      # Maximum length of the local part (RFC 5321).
      MAX_LOCAL_LENGTH = 64

      # Maximum length of the domain part (RFC 5321).
      MAX_DOMAIN_LENGTH = 253

      # Maximum length of a single domain label.
      MAX_LABEL_LENGTH = 63

      # Characters allowed in the local part without quoting (RFC 5322 dot-atom).
      LOCAL_CHAR_PATTERN = %r{\A[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+\z}

      # Pattern for a valid domain label.
      LABEL_PATTERN = /\A[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\z/

      class << self
        # Validate the syntax of an email address.
        #
        # @param email [String] the email address to validate
        # @return [Array<String>] list of error messages (empty if valid)
        def validate(email)
          errors = []

          return ['email must be a string'] unless email.is_a?(String)

          stripped = email.strip

          return ['email must not be empty'] if stripped.empty?

          if stripped.length > MAX_EMAIL_LENGTH
            errors << "email exceeds maximum length of #{MAX_EMAIL_LENGTH} characters"
          end

          parts = stripped.split('@', -1)

          return ['email must contain an @ symbol'] if parts.length < 2

          return ['email must contain exactly one @ symbol'] if parts.length > 2

          local, domain = parts

          errors.concat(validate_local(local))
          errors.concat(validate_domain(domain))

          errors
        end

        # Check if an email address has valid syntax.
        #
        # @param email [String] the email address to check
        # @return [Boolean]
        def valid?(email)
          validate(email).empty?
        end

        private

        # Validate the local part of an email address.
        #
        # @param local [String] the local part (before @)
        # @return [Array<String>] list of error messages
        def validate_local(local)
          errors = []

          if local.empty?
            errors << 'local part must not be empty'
            return errors
          end

          if local.length > MAX_LOCAL_LENGTH
            errors << "local part exceeds maximum length of #{MAX_LOCAL_LENGTH} characters"
          end

          errors << 'local part must not start with a dot' if local.start_with?('.')

          errors << 'local part must not end with a dot' if local.end_with?('.')

          errors << 'local part must not contain consecutive dots' if local.include?('..')

          errors << 'local part contains invalid characters' unless local.match?(LOCAL_CHAR_PATTERN)

          errors
        end

        # Validate the domain part of an email address.
        #
        # @param domain [String] the domain part (after @)
        # @return [Array<String>] list of error messages
        def validate_domain(domain)
          errors = []

          if domain.empty?
            errors << 'domain must not be empty'
            return errors
          end

          if domain.length > MAX_DOMAIN_LENGTH
            errors << "domain exceeds maximum length of #{MAX_DOMAIN_LENGTH} characters"
          end

          errors << 'domain must not start with a hyphen' if domain.start_with?('-')

          errors << 'domain must not end with a hyphen' if domain.end_with?('-')

          labels = domain.split('.')

          errors << 'domain must contain at least two labels' if labels.length < 2

          labels.each do |label|
            if label.empty?
              errors << 'domain must not contain empty labels'
              next
            end

            if label.length > MAX_LABEL_LENGTH
              errors << "domain label '#{label}' exceeds maximum length of #{MAX_LABEL_LENGTH} characters"
            end

            errors << "domain label '#{label}' contains invalid characters" unless label.match?(LABEL_PATTERN)
          end

          tld = labels.last
          errors << 'top-level domain must not be all numeric' if tld&.match?(/\A\d+\z/)

          errors
        end
      end
    end
  end
end
