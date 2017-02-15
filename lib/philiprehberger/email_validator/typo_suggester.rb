# frozen_string_literal: true

module Philiprehberger
  module EmailValidator
    # Typo detection and domain correction suggestions.
    #
    # Compares the domain part of an email against a list of common
    # providers and suggests corrections when a close match is found.
    module TypoSuggester
      # Common email provider domains to check against.
      COMMON_DOMAINS = %w[
        gmail.com
        yahoo.com
        hotmail.com
        outlook.com
        icloud.com
        protonmail.com
        aol.com
      ].freeze

      class << self
        # Suggest a corrected email if the domain appears to be a typo.
        #
        # @param email [String] the email address to check
        # @return [Hash, nil] { original:, suggested: } or nil if no suggestion
        def suggest(email)
          return nil unless email.is_a?(String)

          parts = email.strip.split('@', 2)
          return nil unless parts.length == 2

          local, domain = parts
          return nil if local.empty? || domain.nil? || domain.empty?

          domain_lower = domain.downcase

          # No suggestion needed if domain is already a known provider
          return nil if COMMON_DOMAINS.include?(domain_lower)

          best_match = nil
          best_distance = nil

          COMMON_DOMAINS.each do |known|
            dist = levenshtein(domain_lower, known)
            next unless dist.between?(1, 2)

            if best_distance.nil? || dist < best_distance
              best_distance = dist
              best_match = known
            end
          end

          return nil if best_match.nil?

          { original: email, suggested: "#{local}@#{best_match}" }
        end

        private

        # Compute the Levenshtein edit distance between two strings.
        #
        # @param str_a [String]
        # @param str_b [String]
        # @return [Integer]
        def levenshtein(str_a, str_b)
          m = str_a.length
          n = str_b.length

          return n if m.zero?
          return m if n.zero?

          # Use two rows for space efficiency
          prev_row = (0..n).to_a
          curr_row = Array.new(n + 1, 0)

          (1..m).each do |i|
            curr_row[0] = i

            (1..n).each do |j|
              cost = str_a[i - 1] == str_b[j - 1] ? 0 : 1
              curr_row[j] = [
                prev_row[j] + 1,
                curr_row[j - 1] + 1,
                prev_row[j - 1] + cost
              ].min
            end

            prev_row, curr_row = curr_row, prev_row
          end

          prev_row[n]
        end
      end
    end
  end
end
