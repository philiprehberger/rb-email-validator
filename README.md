# philiprehberger-email_validator

[![Tests](https://github.com/philiprehberger/rb-email-validator/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-email-validator/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-email_validator.svg)](https://rubygems.org/gems/philiprehberger-email_validator)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-email-validator)](https://github.com/philiprehberger/rb-email-validator/commits/main)

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

### Batch Validation (Hash)

```ruby
emails = ["user@example.com", "invalid", "admin@example.com"]

results = Philiprehberger::EmailValidator.batch_validate(emails)
results["user@example.com"].valid?  # => true
results["invalid"].valid?           # => false
results["admin@example.com"].valid? # => true
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

### Sub-address Tags

```ruby
Philiprehberger::EmailValidator.extract_tag("user+promo@gmail.com")
# => "promo"

Philiprehberger::EmailValidator.extract_tag("user@gmail.com")
# => nil

Philiprehberger::EmailValidator.strip_tag("user+promo@gmail.com")
# => "user@gmail.com"

Philiprehberger::EmailValidator.strip_tag("user+a+b@gmail.com")
# => "user@gmail.com"
```

### Canonical Equality

```ruby
require "philiprehberger/email_validator"

Philiprehberger::EmailValidator.canonical_equal?("Foo.Bar+spam@Gmail.com", "foobar@gmail.com")
# => true

Philiprehberger::EmailValidator.canonical_equal?("alice@example.com", "bob@example.com")
# => false

Philiprehberger::EmailValidator.canonical_equal?(nil, "user@example.com")
# => false
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
| `EmailValidator.batch_validate(emails, **opts)` | Bulk validation returning hash of `{ email => Result }` |
| `EmailValidator.valid_all?(emails)` | Returns true only if all emails are valid |
| `EmailValidator.mx_valid?(domain)` | Check if domain has MX or A records |
| `EmailValidator.disposable?(email)` | Check if email uses a disposable domain |
| `EmailValidator.role_based?(email)` | Detect role-based addresses (info@, admin@, etc.) |
| `EmailValidator.configure { \|config\| ... }` | Configure custom disposable domain list |
| `EmailValidator.reset_configuration!` | Reset configuration to defaults |
| `EmailValidator.normalize(email)` | Normalize email (lowercase, remove aliases, Gmail dots) |
| `EmailValidator.canonical_equal?(a, b)` | Compare two emails after normalization; false on invalid input |
| `EmailValidator.extract_tag(email)` | Extract the sub-address tag after `+` in the local part; nil if none or invalid |
| `EmailValidator.strip_tag(email)` | Remove any `+tag` from the local part; returns the original value on invalid input |
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

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-email-validator)

🐛 [Report issues](https://github.com/philiprehberger/rb-email-validator/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-email-validator/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
