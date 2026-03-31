# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.2.0] - 2026-03-28

### Added
- `EmailValidator.validate_all(emails, **opts)` for bulk email validation
- Configurable disposable domain list via `EmailValidator.configure`
- `EmailValidator.normalize(email)` for email normalization (lowercase, remove aliases)
- `EmailValidator.suggest(email)` for typo detection and correction suggestions
- `EmailValidator.domain_info(email)` for domain metadata extraction

## [0.1.1] - 2026-03-26

### Added

- Add GitHub funding configuration

## [0.1.0] - 2026-03-26

### Added
- Initial release
- RFC 5322 email syntax validation with local part and domain rules
- MX record verification using Ruby stdlib Resolv
- Disposable email domain detection with built-in list of ~50 providers
- Role-based address detection (admin@, info@, support@, etc.)
- Result value object with errors, warnings, and valid? predicate
