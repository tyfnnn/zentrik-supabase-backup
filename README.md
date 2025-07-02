# Zentrik Supabase Backend

Database schema and configuration for Zentrik NGO accounting app.

## 📋 Contents

- **Migrations**: PostgreSQL schema evolution
- **Functions**: Edge functions for business logic  
- **Seed Data**: Initial test/demo data
- **RLS Policies**: Row-level security rules

## 🏗️ Schema Overview

Multi-tenant NGO accounting system supporting:
- Organizations with role-based access
- Multi-currency project accounting
- Receipt management with OCR
- NGO-compliant chart of accounts (SKR)

## 🚀 Setup

```bash
# Link to remote project
supabase link --project-ref zmyuzualeipprejkfwsw

# Apply migrations
supabase db reset
```

## 🔐 Security

- Row-level security enabled
- Organization-based data isolation
- Encrypted sensitive data storage

## 🐳 Local Development

**Start Supabase locally:**
```bash
supabase start
```

**Stop containers:**
```bash
supabase stop
```

**Reset local database:**
```bash
supabase db reset
```

## 💾 Backup & Sync

**Pull remote schema changes:**
```bash
supabase db pull
```

**Generate migration from changes:**
```bash
supabase db diff --schema public > migrations/$(date +%Y%m%d_%H%M%S)_update.sql
```

**Push local changes to remote:**
```bash
supabase db push
```


**Complete backup workflow:**
```bash
# 1. Pull latest changes
supabase db pull

# 2. Generate diff if you made manual changes
supabase db diff --schema public > migrations/$(date +%Y%m%d_%H%M%S)_backup.sql

# 3. Commit to Git
git add supabase/migrations/
git commit -m "Database backup $(date +%Y-%m-%d)"
git push origin main
```

## 📱 Related

Main Android app: [zentrik-app](https://github.com/tyfnnn/Zentrik)
