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
