# Automatic Deployment to Netlify

This guide will help you set up automatic deployment so that every time you push code to your Git repository, Netlify will automatically build and deploy your site.

## Step 1: Push to GitHub/GitLab/Bitbucket

### If you don't have a remote repository yet:

1. **Create a new repository** on GitHub (or GitLab/Bitbucket):
   - Go to https://github.com/new
   - Name it: `centru-recreational` (or any name you prefer)
   - Make it **public** or **private** (your choice)
   - Don't initialize with README

2. **Push your code**:
   ```bash
   git add .
   git commit -m "Initial commit - Centru Recreațional website"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/centru-recreational.git
   git push -u origin main
   ```

   Replace `YOUR_USERNAME` with your GitHub username.

## Step 2: Connect to Netlify

1. **Go to Netlify**: https://app.netlify.com
2. **Sign up/Login** (free account)
3. **Click "Add new site"** → **"Import an existing project"**
4. **Choose your Git provider** (GitHub, GitLab, or Bitbucket)
5. **Authorize Netlify** to access your repositories
6. **Select your repository**: `centru-recreational` (or whatever you named it)

## Step 3: Configure Build Settings

Netlify should automatically detect the settings from `netlify.toml`:
- **Build command**: `bash netlify-build.sh`
- **Publish directory**: `build/web`

If it doesn't auto-detect, manually enter:
- Build command: `bash netlify-build.sh`
- Publish directory: `build/web`

## Step 4: Deploy!

1. Click **"Deploy site"**
2. Netlify will:
   - Clone your repository
   - Run the build script (installs Flutter, builds your app)
   - Deploy to a URL like `your-site-name.netlify.app`

## Automatic Deployments

✅ **Every time you push to `main` branch**, Netlify will:
- Automatically detect the changes
- Run a new build
- Deploy the updated site

✅ **Pull requests** get preview deployments automatically!

## Manual Deployment (if needed)

If you want to deploy manually without Git:

```bash
# Build locally first
flutter build web --release
cp robots.txt sitemap.xml build/web/

# Deploy using Netlify CLI
npx netlify-cli deploy --prod --dir=build/web
```

## Custom Domain

After deployment:
1. Go to **Site settings** → **Domain management**
2. Click **"Add custom domain"**
3. Enter your domain (e.g., `centrurecreational.ro`)
4. Follow Netlify's DNS instructions

---

**That's it!** Your site will automatically update whenever you push code! 🚀

