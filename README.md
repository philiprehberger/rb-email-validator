# philiprehberger-email_validator

[![Tests](https://github.com/philiprehberger/rb-email-validator/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-email-validator/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-email_validator.svg)](https://rubygems.org/gems/philiprehberger-email_validator)
[![GitHub release](https://img.shields.io/github/v/release/philiprehberger/rb-email-validator)](https://github.com/philiprehberger/rb-email-validator/releases)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-email-validator)](https://github.com/philiprehberger/rb-email-validator/commits/main)
[![License](https://img.shields.io/github/license/philiprehberger/rb-email-validator)](LICENSE)
[![Bug Reports](https://img.shields.io/github/issues/philiprehberger/rb-email-validator/bug)](https://github.com/philiprehberger/rb-email-validator/issues?q=is%3Aissue+is%3Aopen+label%3Abug)
[![Feature Requests](https://img.shields.io/github/issues/philiprehberger/rb-email-validator/enhancement)](https://github.com/philiprehberger/rb-email-validator/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

RFC-compliant email validation with MX record verification, disposable domain detection, normalization, and typo suggestions

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-email_validator"
```

Or install directly:

```bash
gem install philiprehberger-email_validator
```

## Usage

```ruby
require "philiprehberger/email_validator"

Philiprehberger::EmailValidator.valid?("user@example.com")
# => true

Philiprehberger::EmailValidator.valid?("not-an-email")
# => false
```

### Full Validation

```ruby
result = Philiprehberger::EmailValidator.validate("user@example.com")
result.valid?    # => true
result.errors    # => []
result.warnings  # => []

result = Philiprehberger::EmailValidator.validate("admin@example.com")
result.valid?    # => true
result.warnings  # => ["address appears to be role-based"]
```

### MX Record Verification

```ruby
result = Philiprehberger::EmailValidator.validate("user@example.com", check_mx: true)
result.valid?  # => true (if domain has MX/A records)

Philiprehberger::EmailValidator.mx_valid?("example.com")
# => true
```

### Disposable Domain Detection

```ruby
Philiprehberger::EmailValidator.disposable?("user@mailinator.com")
# => true

result = Philiprehberger::EmailValidator.validate("user@mailinator.com", allow_disposable: false)
result.valid?  # => false
result.errors  # => ["disposable email domains are not allowed"]
```

### Role-Based Address Detection

```ruby
Philiprehberger::EmailValidator.role_based?("info@example.com")
# => true

Philiprehberger::EmailValidator.role_based?("alice@example.com")
# => false
```

### Bulk Validation

```ruby
emails = ["user@example.com", "invalid", "admin@example.com"]

results = Philiprehberger::EmailValidator.validate_all(emails, allow_disposable: false)
results[0].valid?  # => true
results[1].valid?  # => false

Philiprehberger::EmailValidator.valid_all?(["user@example.com", "alice@example.com"])
# => true
```

### Custom Disposable Domain List

```ruby
Philiprehberger::EmailValidator.configure do |config|
  config.add_disposable_domains(["custom-temp.com", "temp.org"])
  config.remove_disposable_domains(["mailinator.com"])
end

Philiprehberger::EmailValidator.disposable?("user@custom-temp.com")
# => true

Philiprehberger::EmailValidator.reset_configuration!
```

### Email Normalization

```ruby
Philiprehberger::EmailValidator.normalize("Jo.Hn+spam@Gmail.com")
# => "john@gmail.com"

Philiprehberger::EmailValidator.normalize("  USER+tag@Example.COM  ")
# => "user@example.com"
```

### Typo Suggestion

```ruby
Philiprehberger::EmailValidator.suggest("user@gmial.com")
# => { original: "user@gmial.com", suggested: "user@gmail.com" }

Philiprehberger::EmailValidator.suggest("user@gmail.com")
# => nil
```

### Domain Info

```ruby
Philiprehberger::EmailValidator.domain_info("user@mail.example.co.uk")
# => { domain: "mail.example.co.uk", tld: "uk" }

Philiprehberger::EmailValidator.domain_info("user@example.com", check_mx: true)
# => { domain: "example.com", tld: "com", mx_records: ["mail.example.com"] }
```

## API

| Method | Description |
|--------|-------------|
| `EmailValidator.valid?(email)` | Quick syntax check, returns boolean |
| `EmailValidator.validate(email, check_mx: false, allow_disposable: true)` | Full validation returning Result |
| `EmailValidator.validate_all(emails, **opts)` | Bulk validation returning array of Results |
| `EmailValidator.valid_all?(emails)` | Returns true only if all emails are valid |
| `EmailValidator.mx_valid?(domain)` | Check if domain has MX or A records |
| `EmailValidator.disposable?(email)` | Check if email uses a disposable domain |
| `EmailValidator.role_based?(email)` | Detect role-based addresses (info@, admin@, etc.) |
| `EmailValidator.configure { \|config\| ... }` | Configure custom disposable domain list |
| `EmailValidator.reset_configuration!` | Reset configuration to defaults |
| `EmailValidator.normalize(email)` | Normalize email (lowercase, remove aliases, Gmail dots) |
| `EmailValidator.suggest(email)` | Suggest corrected domain for typos |
| `EmailValidator.domain_info(email, check_mx: false)` | Extract domain metadata |

### `Result`

| Method | Description |
|--------|-------------|
| `#valid?` | True if no validation errors |
| `#errors` | Array of error message strings |
| `#warnings` | Array of warning message strings |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this package useful, consider giving it a star on GitHub — it helps motivate continued maintenance and development.

[![LinkedIn](https://img.shields.io/badge/Philip%20Rehberger-LinkedIn-0A66C2?logo=linkedin)](https://www.linkedin.com/in/philiprehberger)
[![More packages](https://img.shields.io/badge/more-open%20source%20packages-blue)](https://philiprehberger.com/open-source-packages)

## License

[MIT](LICENSE)
