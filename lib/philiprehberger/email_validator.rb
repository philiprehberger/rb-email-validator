# frozen_string_literal: true

require 'set'

require_relative 'email_validator/version'
require_relative 'email_validator/result'
require_relative 'email_validator/syntax'
require_relative 'email_validator/mx_check'
require_relative 'email_validator/disposable'
require_relative 'email_validator/configuration'
require_relative 'email_validator/normalizer'
require_relative 'email_validator/typo_suggester'
require_relative 'email_validator/domain_info_extractor'

module Philiprehberger
  module EmailValidator
    class Error < StandardError; end

    # Role-based local parts that typically represent groups, not individuals.
    ROLE_BASED_LOCALS = Set.new(%w[
                                  abuse admin billing contact dev devnull ftp help hostmaster
                                  info mail mailer-daemon marketing noc noreply no-reply
                                  office postmaster press registrar remove root sales security
                                  spam subscribe support sysadmin tech undisclosed-recipients
                                  unsubscribe usenet uucp webmaster www
                                ]).freeze

    class << self
      # Quick syntax check for an email address.
      #
      # @param email [String] the email address to validate
      # @return [Boolean] true if syntax is valid
      def valid?(email)
        Syntax.valid?(email)
      end

      # Full validation returning a Result object.
      #
      # @param email [String] the email address to validate
      # @param check_mx [Boolean] whether to verify MX records (default: false)
      # @param allow_disposable [Boolean] whether to allow disposable domains (default: true)
      # @return [Result] validation result with errors and warnings
      def validate(email, check_mx: false, allow_disposable: true)
        errors = []
        warnings = []

        syntax_errors = Syntax.validate(email)
        errors.concat(syntax_errors)

        if syntax_errors.empty?
          errors << 'disposable email domains are not allowed' if !allow_disposable && disposable_domain?(email)

          warnings << 'address appears to be role-based' if role_based?(email)

          if check_mx
            domain = extract_domain(email)
            errors << "domain '#{domain}' has no MX or A records" unless MxCheck.valid?(domain)
          end
        end

        Result.new(errors: errors, warnings: warnings)
      end

      # Validate an array of email addresses.
      #
      # @param emails [Array<String>] the email addresses to validate
      # @param opts [Hash] options passed to validate (check_mx:, allow_disposable:)
      # @return [Array<Result>] array of Result objects
      def validate_all(emails, **opts)
        emails.map { |email| validate(email, **opts) }
      end

      # Validate multiple emails and return a hash mapping each email to its Result.
      #
      # @param emails [Array<String>] the email addresses to validate
      # @param opts [Hash] options passed to validate (check_mx:, allow_disposable:)
      # @return [Hash{String => Result}] hash of email => Result pairs
      def batch_validate(emails, **opts)
        emails.to_h do |email|
          [email, validate(email, **opts)]
        end
      end

      # Check if all emails in an array are valid.
      #
      # @param emails [Array<String>] the email addresses to check
      # @return [Boolean] true only if all emails are valid
      def valid_all?(emails)
        emails.all? { |email| valid?(email) }
      end

      # Check if a domain has valid MX records.
      #
      # @param domain [String] the domain to check
      # @return [Boolean] true if MX or A records exist
      def mx_valid?(domain)
        MxCheck.valid?(domain)
      end

      # Check if an email address uses a known disposable domain.
      #
      # @param email [String] the email address to check
      # @return [Boolean] true if the domain is disposable
      def disposable?(email)
        disposable_domain?(email)
      end

      # Detect role-based email addresses (info@, admin@, support@, etc.).
      #
      # @param email [String] the email address to check
      # @return [Boolean] true if the local part is role-based
      def role_based?(email)
        return false unless email.is_a?(String)

        local = extract_local(email)
        return false if local.nil?

        ROLE_BASED_LOCALS.include?(local.downcase)
      end

      # Configure the email validator.
      #
      # @yield [Configuration] the configuration object
      # @return [void]
      def configure
        yield configuration
      end

      # Reset configuration to defaults.
      #
      # @return [void]
      def reset_configuration!
        @configuration = Configuration.new
      end

      # The current configuration instance.
      #
      # @return [Configuration]
      def configuration
        @configuration ||= Configuration.new
      end

      # Normalize an email address.
      #
      # @param email [String] the email address to normalize
      # @return [String] the normalized email address
      # @raise [Error] if format is invalid
      def normalize(email)
        Normalizer.normalize(email)
      end

      # Compare two email addresses after normalization.
      #
      # Returns false rather than raising if either input is invalid.
      #
      # @param a [String] first email address
      # @param b [String] second email address
      # @return [Boolean] true if both normalize to the same address
      def canonical_equal?(a, b)
        Normalizer.normalize(a) == Normalizer.normalize(b)
      rescue Error, StandardError
        false
      end

      # Extract the sub-address tag (the portion after the first `+` in the
      # local part) from an email address.
      #
      # Only the first `+` separates the user from the tag, so
      # `'user+a+b@gmail.com'` yields the tag `'a+b'`.
      #
      # @param email [String] the email address to inspect
      # @return [String, nil] the tag portion, or nil if no tag is present or
      #   the input is not a valid email
      def extract_tag(email)
        return nil unless email.is_a?(String)

        local = extract_local(email)
        domain = extract_domain(email)
        return nil if local.nil? || domain.nil? || local.empty? || domain.empty?

        parts = local.split('+', 2)
        return nil if parts.length != 2

        parts[1]
      end

      # Return the email with any sub-address tag (`+tag`) removed from the
      # local part. Domain case is preserved.
      #
      # Only the first `+` separates the user from the tag, so
      # `'user+a+b@gmail.com'` becomes `'user@gmail.com'`.
      #
      # For invalid input (non-string, missing `@`, empty local or domain),
      # the original value is returned unchanged — matching the defensive
      # behavior of `canonical_equal?`.
      #
      # @param email [String] the email address to strip
      # @return [String] the email without a `+tag`, or the original value if
      #   the input is invalid
      def strip_tag(email)
        return email unless email.is_a?(String)

        local = extract_local(email)
        domain = extract_domain(email)
        return email if local.nil? || domain.nil? || local.empty? || domain.empty?

        stripped_local = local.split('+', 2).first
        "#{stripped_local}@#{domain}"
      end

      # Split an email address into its local part, domain, and sub-address
      # tag in one call.
      #
      # Returns `nil` if the input is not a valid email address (non-string,
      # missing `@`, or an empty local or domain). The `:tag` key is `nil`
      # when no `+tag` is present in the local part. The local part is
      # returned with any tag stripped.
      #
      # @param email [String] the email address to split
      # @return [Hash{Symbol => String, nil}, nil] `{ local:, domain:, tag: }`
      #   or `nil` for invalid input
      def split(email)
        return nil unless email.is_a?(String)

        local = extract_local(email)
        domain = extract_domain(email)
        return nil if local.nil? || domain.nil? || local.empty? || domain.empty?

        local_part, tag = local.split('+', 2)
        { local: local_part, domain: domain, tag: tag }
      end

      # Suggest a corrected email if the domain appears to be a typo.
      #
      # @param email [String] the email address to check
      # @return [Hash, nil] { original:, suggested: } or nil if no suggestion
      def suggest(email)
        TypoSuggester.suggest(email)
      end

      # Extract domain information from an email address.
      #
      # @param email [String] the email address to analyze
      # @param check_mx [Boolean] whether to look up MX records (default: false)
      # @return [Hash] { domain:, tld:, mx_records: }
      # @raise [Error] if format is invalid
      def domain_info(email, check_mx: false)
        DomainInfoExtractor.extract(email, check_mx: check_mx)
      end

      private

      # Check if an email uses a disposable domain, respecting configuration.
      #
      # @param email [String]
      # @return [Boolean]
      def disposable_domain?(email)
        return false unless email.is_a?(String)

        domain = extract_domain(email)
        return false if domain.nil?

        configuration.effective_disposable_domains.include?(domain.downcase)
      end

      # Extract the domain part from an email address.
      #
      # @param email [String]
      # @return [String, nil]
      def extract_domain(email)
        parts = email.strip.split('@', 2)
        return nil if parts.length != 2

        parts[1]
      end

      # Extract the local part from an email address.
      #
      # @param email [String]
      # @return [String, nil]
      def extract_local(email)
        parts = email.strip.split('@', 2)
        return nil if parts.length != 2

        parts[0]
      end
    end
  end
end
