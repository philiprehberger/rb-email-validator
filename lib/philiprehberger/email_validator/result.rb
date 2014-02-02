# frozen_string_literal: true

module Philiprehberger
  module EmailValidator
    # Value object representing the outcome of an email validation.
    #
    # @example
    #   result = EmailValidator.validate("user@example.com")
    #   result.valid?   # => true
    #   result.errors   # => []
    #   result.warnings # => []
    class Result
      # @return [Array<String>] list of validation error messages
      attr_reader :errors

      # @return [Array<String>] list of non-fatal warning messages
      attr_reader :warnings

      # @param errors [Array<String>] validation error messages
      # @param warnings [Array<String>] non-fatal warning messages
      def initialize(errors: [], warnings: [])
        @errors = errors.freeze
        @warnings = warnings.freeze
        freeze
      end

      # Whether the email passed all validation checks.
      #
      # @return [Boolean]
      def valid?
        @errors.empty?
      end

      # String representation for debugging.
      #
      # @return [String]
      def to_s
        if valid?
          '#<EmailValidator::Result valid>'
        else
          "#<EmailValidator::Result invalid errors=#{@errors}>"
        end
      end

      alias inspect to_s
    end
  end
end
