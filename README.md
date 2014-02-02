# philiprehberger-email_validator

[![Tests](https://github.com/philiprehberger/rb-email-validator/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-email-validator/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-email_validator.svg)](https://rubygems.org/gems/philiprehberger-email_validator)
[![License](https://img.shields.io/github/license/philiprehberger/rb-email-validator)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

RFC-compliant email validation with MX record verification

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

## API

| Method | Description |
|--------|-------------|
| `EmailValidator.valid?(email)` | Quick syntax check, returns boolean |
| `EmailValidator.validate(email, check_mx: false, allow_disposable: true)` | Full validation returning Result |
| `EmailValidator.mx_valid?(domain)` | Check if domain has MX or A records |
| `EmailValidator.disposable?(email)` | Check if email uses a disposable domain |
| `EmailValidator.role_based?(email)` | Detect role-based addresses (info@, admin@, etc.) |

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

## License

[MIT](LICENSE)
