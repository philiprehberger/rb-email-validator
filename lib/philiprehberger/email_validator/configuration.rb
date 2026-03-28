# frozen_string_literal: true

module Philiprehberger
  module EmailValidator
    # Mutable configuration for the email validator.
    #
    # Allows customizing the disposable domain list at runtime.
    #
    # @example
    #   EmailValidator.configure do |config|
    #     config.add_disposable_domains(["example.com"])
    #     config.remove_disposable_domains(["mailinator.com"])
    #   end
    class Configuration
      # @return [Set<String>] custom domains added to the disposable list
      attr_reader :added_disposable_domains

      # @return [Set<String>] domains removed from the built-in disposable list
      attr_reader :removed_disposable_domains

      def initialize
        @added_disposable_domains = Set.new
        @removed_disposable_domains = Set.new
      end

      # Add domains to the disposable list.
      #
      # @param domains [Array<String>] domains to add
      # @return [void]
      def add_disposable_domains(domains)
        domains.each { |d| @added_disposable_domains.add(d.downcase) }
      end

      # Remove domains from the disposable list.
      #
      # @param domains [Array<String>] domains to remove
      # @return [void]
      def remove_disposable_domains(domains)
        domains.each { |d| @removed_disposable_domains.add(d.downcase) }
      end

      # Return the effective set of disposable domains.
      #
      # @return [Set<String>]
      def effective_disposable_domains
        (Disposable::DOMAINS | @added_disposable_domains) - @removed_disposable_domains
      end
    end
  end
end
