# frozen_string_literal: true

module Philiprehberger
  module EmailValidator
    # Disposable (throwaway) email domain detection.
    #
    # Maintains a built-in list of commonly used disposable email providers.
    # Useful for preventing sign-ups with temporary email addresses.
    module Disposable
      # Built-in list of common disposable email domains.
      DOMAINS = Set.new(%w[
                          mailinator.com
                          guerrillamail.com
                          guerrillamail.de
                          guerrillamail.net
                          guerrillamail.org
                          tempmail.com
                          temp-mail.org
                          throwaway.email
                          sharklasers.com
                          guerrillamailblock.com
                          grr.la
                          dispostable.com
                          yopmail.com
                          yopmail.fr
                          trashmail.com
                          trashmail.me
                          trashmail.net
                          mailnesia.com
                          maildrop.cc
                          discard.email
                          mailcatch.com
                          fakeinbox.com
                          mailnull.com
                          tempail.com
                          tempr.email
                          einrot.com
                          getnada.com
                          jetable.org
                          mohmal.com
                          burpcollaborator.net
                          mailsac.com
                          harakirimail.com
                          tmail.ws
                          guerrillamail.info
                          mytemp.email
                          tempmailaddress.com
                          mailforspam.com
                          safetymail.info
                          trashymail.com
                          mailexpire.com
                          tempinbox.com
                          spamgourmet.com
                          mintemail.com
                          mailzilla.com
                          anonbox.net
                          binkmail.com
                          bobmail.info
                          chammy.info
                          deadaddress.com
                          despammed.com
                          devnullmail.com
                          dontreg.com
                          e4ward.com
                          emailigo.de
                        ]).freeze

      class << self
        # Check if an email address uses a known disposable domain.
        #
        # @param email [String] the email address to check
        # @return [Boolean] true if the domain is in the disposable list
        def disposable?(email)
          return false unless email.is_a?(String)

          domain = extract_domain(email)
          return false if domain.nil?

          effective_domains.include?(domain.downcase)
        end

        # Check if a domain is in the disposable list.
        #
        # @param domain [String] the domain to check
        # @return [Boolean]
        def domain_disposable?(domain)
          return false unless domain.is_a?(String)

          effective_domains.include?(domain.strip.downcase)
        end

        private

        # Return the effective set of disposable domains, respecting configuration.
        #
        # @return [Set<String>]
        def effective_domains
          EmailValidator.configuration.effective_disposable_domains
        end

        # Extract the domain from an email address.
        #
        # @param email [String]
        # @return [String, nil]
        def extract_domain(email)
          parts = email.strip.split('@', 2)
          return nil if parts.length != 2

          parts[1]&.downcase
        end
      end
    end
  end
end
