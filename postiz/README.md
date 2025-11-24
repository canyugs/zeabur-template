# Postiz - Open Source Social Media Scheduling Platform

![Postiz Banner](https://cdn.zeabur.com/postiz-banner.jpg)

Deploy Postiz on Zeabur with one click - a fully open-source social media scheduling platform that supports 19+ platforms including Threads, X (Twitter), Facebook, Instagram, Reddit, and Telegram.

## 🚀 Features

- 🧠 **Built-in AI Assistant** - Generate post content and images with AI
- 📅 **Advanced Scheduling** - Visual calendar, repeating posts, timezone support
- 🧩 **19+ Platform Integration** - Threads, X, Facebook, Instagram, Reddit, Telegram, Mastodon, Bluesky, and more
- 📊 **Analytics Dashboard** - Track post performance and engagement
- 🛠️ **Self-Hosted & Open Source** - Full control over your data
- 👥 **Team Collaboration** - Multi-user support with role management

## 📦 What's Included

This template deploys a complete Postiz stack with:

- **Postiz App** (v2.8.3) - Main application with web UI and API
- **PostgreSQL 17** - Primary database for user data and posts
- **Redis 7.2** - Caching and queue management

## 🔧 Configuration

### Domain Setup

The template will automatically:
- Assign a `.zeabur.app` domain to your Postiz instance
- Configure SSL/TLS certificates
- Set up proper CORS and URL settings

### Default Settings

- **Registration**: Enabled by default (can be disabled via `DISABLE_REGISTRATION=false`)
- **Storage**: Local filesystem (uploads stored in `/uploads` volume)
- **AI Features**: Requires additional API keys (see Advanced Configuration)

### Zeabur-Specific Settings

#### Auto-Configured Variables

These environment variables are automatically set by Zeabur - **no manual configuration needed**:

| Variable | Purpose | Value |
|----------|---------|-------|
| `MAIN_URL` | Public access URL | Auto-set to your `.zeabur.app` domain |
| `DATABASE_URL` | PostgreSQL connection | Internal service connection |
| `REDIS_URL` | Redis connection | Internal service connection |
| `JWT_SECRET` | Session encryption | Randomly generated |

#### Custom Domain

To use your own domain:
1. Zeabur dashboard → Postiz service → Domains tab
2. Add your custom domain
3. Update DNS records as instructed by Zeabur
4. **No environment variable changes needed** - Zeabur auto-updates URLs

#### Persistent Storage

Zeabur provisions these volumes automatically:
- **PostgreSQL data** - Database persistence
- **Redis data** - Job queue persistence
- **/uploads** - Default file storage location

For production use, consider configuring S3 storage. See [Postiz storage docs](https://postiz.com/docs/storage).

### Advanced Configuration

This template provides sensible defaults for Zeabur deployment.

For advanced features and customization (AI integration, external storage, email notifications, team management, etc.), please refer to:

**📚 [Official Postiz Documentation](https://postiz.com/docs)**

Common configuration guides:
- **AI Features**: https://postiz.com/docs/ai
- **Storage (S3)**: https://postiz.com/docs/storage
- **Email/SMTP**: https://postiz.com/docs/email
- **Team & Permissions**: https://postiz.com/docs/teams
- **API Integration**: https://postiz.com/docs/api

## 🎯 First Steps

### After Deployment

**⏱️ Wait 2-3 minutes** for:
- Database initialization and schema creation
- Service health checks to complete
- Zeabur domain assignment

### Initial Setup

1. **Access your instance**
   Open the Zeabur-assigned domain (found in Postiz service → Domains)

2. **Create admin account**
   - Click "Sign Up"
   - **⚠️ Important: The first user becomes the admin**
   - Choose credentials carefully

3. **Secure your instance (Recommended)**
   After creating the admin account, disable public registration:
   - Go to Zeabur dashboard → Postiz service → Environment Variables
   - Add: `DISABLE_REGISTRATION=false`
   - Click "Redeploy" or "Restart"

4. **Connect social media accounts**
   Follow the [official platform guides](https://postiz.com/docs/platforms) to connect:
   - X (Twitter), Facebook, Instagram, LinkedIn
   - Threads, Mastodon, Bluesky
   - Reddit, Discord, Telegram, and more

5. **Start scheduling**
   Create and schedule your first post!

For detailed feature guides, see [Postiz Documentation](https://postiz.com/docs).

## 🔗 Social Media Platforms Supported

- **Mainstream**: X (Twitter), Facebook, Instagram, LinkedIn, TikTok, YouTube
- **Growing**: Threads, Mastodon, Bluesky
- **Community**: Reddit, Discord, Telegram
- **Others**: Pinterest, Dribbble, Medium, Dev.to, Hashnode, Nostr, Lemmy

## 📊 System Requirements

- **Memory**: Minimum 512MB RAM (1GB+ recommended)
- **Storage**: At least 1GB for uploads and database
- **Bandwidth**: Depends on usage (media-heavy posts require more)

## 🛠️ Maintenance

### Redis Memory Monitoring

**Configuration**: 512MB max memory, `noeviction` policy

**Why monitor**: Redis stores your scheduled post queue. If memory fills up, new posts cannot be scheduled (existing scheduled posts will still publish).

#### Check Memory Usage

**Via Zeabur Dashboard**:
1. Go to Redis service → Logs
2. Look for memory warnings

**Via Redis CLI**:
```bash
redis-cli INFO memory
# Check: used_memory_human, maxmemory_human
```

#### Usage Guidelines

| Team Size | Typical Usage | Status |
|-----------|---------------|--------|
| 1-5 users | < 100MB | ✅ Normal |
| 10-20 users | 100-200MB | ✅ Normal |
| 50+ users | 200-400MB | ⚠️ Monitor |
| Any size | > 400MB | ⚠️ Action needed |

#### When Memory Exceeds 400MB (80%)

1. Check for stuck jobs in Postiz admin panel
2. Review and delete old completed posts
3. Consider increasing Redis memory limit in template
4. If problem persists, check [Postiz GitHub issues](https://github.com/gitroomhq/postiz-app/issues)

### Updating Postiz

This template uses a fixed version (v2.8.3) for stability. To update:

1. Check [Postiz releases](https://github.com/gitroomhq/postiz-app/releases)
2. Update the `image` tag in the template
3. Redeploy the service

### Monitor Resource Usage

- Check Redis memory usage (max 512MB configured)
- Monitor PostgreSQL connections (max 100 configured)
- Review application logs for errors

## 🐛 Troubleshooting

### Cannot Login After Deployment

**Solution**: Wait 2-3 minutes for database initialization to complete.

### Social Media Connection Fails

**Possible causes**:
- Incorrect callback URL configuration
- Platform API credentials expired
- Rate limiting from social platform

**Solution**: Check Postiz logs and verify your domain is correctly set.

### Upload Fails

**Solution**: Ensure the `/uploads` volume has sufficient space and proper permissions.

### Performance Issues

**Solutions**:
- Increase Redis memory limit if cache eviction is frequent
- Scale PostgreSQL resources if queries are slow
- Consider using external S3 storage for media files

### Redis "Eviction Policy" Warning

**Error message**: `IMPORTANT! Eviction policy is allkeys-lru. It should be "noeviction"`

**Status**: ✅ Fixed in this template (using `noeviction`)

**If you still see this**: Template may be outdated or Redis config was manually modified. Check Redis configuration.

### Redis OOM (Out of Memory) Error

**Error message**: `OOM command not allowed when used memory > 'maxmemory'`

**Meaning**: Redis reached 512MB limit, cannot accept new writes

**Impact**:
- ❌ New scheduled posts cannot be created
- ✅ Existing scheduled posts will still publish
- ✅ Published posts unaffected

**Solution**:
1. See "Redis Memory Monitoring" section above
2. Clear old/completed jobs
3. Increase Redis memory limit if needed

## 📚 Additional Resources

- [Official Postiz Documentation](https://postiz.com/docs)
- [GitHub Repository](https://github.com/gitroomhq/postiz-app)
- [Community Discord](https://discord.gg/postiz)
- [Zeabur Documentation](https://zeabur.com/docs)

## 🔒 Security Notes

- **JWT_SECRET** is auto-generated for each deployment
- **Database passwords** are randomly generated
- Change default credentials if exposing to production
- Enable `DISABLE_REGISTRATION=false` after creating admin account
- Use HTTPS only (automatically enforced by Zeabur)

## 📝 License

Postiz is licensed under Apache 2.0. See the [official repository](https://github.com/gitroomhq/postiz-app) for details.

## 🤝 Contributing

Found an issue with this template? Please report it at:
- [Zeabur Template Repository](https://github.com/zeabur/zeabur)

---

**Quick Links**: [Postiz Website](https://postiz.com) | [Source Code](https://github.com/gitroomhq/postiz-app) | [Zeabur Platform](https://zeabur.com)
