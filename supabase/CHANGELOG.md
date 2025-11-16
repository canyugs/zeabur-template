# Changelog

All notable changes to the Supabase template for Zeabur.

## [Unreleased]

### Added

#### Architecture Documentation
- **Comprehensive architecture section** with 14 services organized into categories:
  - **Core Services (Required)**: PostgreSQL, Kong, GoTrue (Auth), PostgREST (REST), Postgres Meta (Meta), Supabase Studio
  - **Scalability & Performance**: Supavisor (Connection Pooler)
  - **Real-time Features**: Realtime (Database Change Subscriptions)
  - **Storage & Media**: Storage, MinIO, ImgProxy
  - **Monitoring & Analytics**: Vector, Logflare (Analytics)
  - **Edge Computing**: Edge Functions
- Detailed descriptions for each service explaining their role and functionality
- Service flow explanation (all requests through Kong on port 8000)

#### Configuration Sections
- **Google OAuth Configuration**
  - Step-by-step setup instructions
  - Required environment variables with placeholders
  - Redirect URI configuration guidance

- **Apple OAuth Configuration**
  - Step-by-step setup instructions
  - Required environment variables with placeholders
  - Redirect URI configuration guidance

- **SMTP Email Service (Resend Integration)**
  - 4-step configuration process:
    1. Resend Setup (Domain Verification, Sender Email)
    2. Supabase Auth SMTP Configuration (environment variables)
    3. Zeabur Environment Configuration (deployment steps)
    4. Testing Email Functionality (manual testing with curl)
  - Comprehensive troubleshooting notes (SPF/DKIM, Redirect URI, Email Delivery, API Key Security)
  - Additional features section (custom templates, webhooks, BIMI, rate limiting)

- **Advanced Auth Configuration (Optional)**
  - Custom Access Token Hook
  - MFA Verification Hook
  - Password Verification Hook
  - Custom SMS Hook
  - Custom Email Hook
  - Other options (skip nonce check, secure email change, SMTP max frequency)

- **Studio SQL Assistant**
  - OpenAI API key configuration for SQL assistance

#### Documentation Improvements
- **Getting Started section**
  - Access the Dashboard instructions
  - Finding Your Credentials step-by-step guide
  - Important Security Keys table with descriptions
  - Security warnings about default demo keys
  - Secure key generation instructions with official Supabase link

- **Multi-language Support**
  - Complete localization for 6 languages:
    - English (en-US) - default
    - Traditional Chinese (zh-TW) - complete detailed translation
    - Simplified Chinese (zh-CN) - concise translation
    - Japanese (ja-JP) - concise translation
    - Spanish (es-ES) - concise translation
    - Indonesian (id-ID) - concise translation
  - All languages include:
    - Architecture descriptions
    - Configuration sections
    - Getting Started guides
    - Security documentation

### Changed

#### Variable Naming
- **`SUPABASE_USERNAME`** → **`DASHBOARD_USERNAME`**
  - Updated variable name for better clarity
  - Now explicitly labeled as "Dashboard Username"
  - Description updated to "What is the username you want for your Supabase Dashboard?"

#### Documentation Structure
- Reorganized service descriptions from flat list to categorized structure based on [official Supabase architecture](https://supabase.com/docs/guides/self-hosting/docker#architecture)
- Moved "Security Configuration" into "Securing your services" section
- Enhanced security warnings with critical alerts (⚠️ CRITICAL markers)
- Improved credential access instructions with numbered steps

#### Service Descriptions
- Added MinIO backend note for Storage service
- Updated service status documentation for Storage, Supavisor, and Realtime (marked as "Working")
- Enhanced descriptions for all 14 services with technical details

### Removed

- **Development Status section** - removed as services are now production-ready
- **Security Configuration subsection** from Configuration section - consolidated into "Securing your services"

### Technical Details

#### File Size Growth
- Template expanded from ~1,781 lines to ~2,860 lines (+60% growth)
- Growth primarily due to:
  - Multi-language support (5 additional languages)
  - Comprehensive configuration documentation
  - Detailed architecture descriptions

#### Environment Variable Updates
- All `${PUBLIC_DOMAIN}` references maintained for backward compatibility
- Added `${ZEABUR_WEB_DOMAIN}` for internal service references
- Updated `DASHBOARD_USERNAME` and `DASHBOARD_PASSWORD` usage across Kong service

## Migration Guide

### Upgrading from old-template.yml to template.yaml

1. **Update Variable Names**
   - If you're using `SUPABASE_USERNAME`, update references to `DASHBOARD_USERNAME`
   - The functionality remains the same, only the variable name changed

2. **Review Security Configuration**
   - Follow the new "Securing your services" section
   - Generate new JWT_SECRET, ANON_KEY, and SERVICE_ROLE_KEY
   - Update environment variables in Kong service
   - Restart all services to apply changes

3. **Optional Enhancements**
   - Configure Google/Apple OAuth if needed (see Configuration > OAuth sections)
   - Set up SMTP email service using Resend (see Configuration > SMTP section)
   - Enable advanced auth features using hooks (see Configuration > Advanced Auth)

4. **Language Selection**
   - Template now supports 6 languages
   - Default language is English (en-US)
   - Zeabur will automatically display the appropriate language based on user preference

## References

- [Supabase Self-Hosting Documentation](https://supabase.com/docs/guides/self-hosting/docker)
- [Supabase Architecture](https://supabase.com/docs/guides/self-hosting/docker#architecture)
- [Supabase API Key Generation](https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys)
- [Zeabur Template Guidelines](../README.md)
