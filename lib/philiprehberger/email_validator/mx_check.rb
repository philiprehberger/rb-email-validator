# frozen_string_literal: true

require 'resolv'

module Philiprehberger
  module EmailValidator
    # MX record verification using Ruby's built-in Resolv library.
    #
    # Checks whether a domain has valid MX records, falling back to
    # A record lookup as permitted by RFC 5321 section 5.1.
    module MxCheck
      # Default DNS timeout in seconds.
      DEFAULT_TIMEOUT = 5

      class << self
        # Check if a domain has valid MX records.
        #
        # Falls back to checking A records if no MX records are found,
        # as RFC 5321 permits mail delivery to the A record host.
        #
        # @param domain [String] the domain to check
        # @param timeout [Integer] DNS query timeout in seconds
        # @return [Boolean] true if the domain has MX or A records
        def valid?(domain, timeout: DEFAULT_TIMEOUT)
          return false if domain.nil? || domain.strip.empty?

          resolver = Resolv::DNS.new
          resolver.timeouts = timeout

          mx_records = fetch_mx_records(resolver, domain)
          return true unless mx_records.empty?

          a_records = fetch_a_records(resolver, domain)
          !a_records.empty?
        rescue Resolv::ResolvError, Resolv::ResolvTimeout
          false
        ensure
          resolver&.close
        end

        # Retrieve MX records for a domain.
        #
        # @param domain [String] the domain to look up
        # @param timeout [Integer] DNS query timeout in seconds
        # @return [Array<String>] list of MX hostnames sorted by preference
        def mx_records(domain, timeout: DEFAULT_TIMEOUT)
          return [] if domain.nil? || domain.strip.empty?

          resolver = Resolv::DNS.new
          resolver.timeouts = timeout

          records = fetch_mx_records(resolver, domain)
          records.sort_by(&:preference).map { |r| r.exchange.to_s }
        rescue Resolv::ResolvError, Resolv::ResolvTimeout
          []
        ensure
          resolver&.close
        end

        private

        # @param resolver [Resolv::DNS]
        # @param domain [String]
        # @return [Array<Resolv::DNS::Resource::IN::MX>]
        def fetch_mx_records(resolver, domain)
          resolver.getresources(domain, Resolv::DNS::Resource::IN::MX)
        rescue Resolv::ResolvError, Resolv::ResolvTimeout
          []
        end

        # @param resolver [Resolv::DNS]
        # @param domain [String]
        # @return [Array<Resolv::DNS::Resource::IN::A>]
        def fetch_a_records(resolver, domain)
          resolver.getresources(domain, Resolv::DNS::Resource::IN::A)
        rescue Resolv::ResolvError, Resolv::ResolvTimeout
          []
        end
      end
    end
  end
end
