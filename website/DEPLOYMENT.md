# Deployment Guide for peblapp.help

## 🚀 Quick Start Deployment

Your website is ready to deploy to **https://peblapp.help**

### Recommended: Deploy with Netlify (Easiest)

1. **Go to Netlify**: https://app.netlify.com/
2. **Sign up/Login** with GitHub or email
3. **Drag and drop** your `website` folder to Netlify
4. **Configure custom domain**:
   - Go to Site Settings → Domain Management
   - Click "Add custom domain"
   - Enter: `peblapp.help`
   - Follow DNS configuration instructions

### DNS Configuration for peblapp.help

Add these DNS records at your domain registrar:

```
Type: A
Name: @
Value: 75.2.60.5 (Netlify's load balancer)

Type: CNAME  
Name: www
Value: [your-site-name].netlify.app
```

**Or use Netlify DNS** (recommended):
- Transfer DNS management to Netlify
- Netlify will automatically configure everything

## 🔧 Alternative Deployment Options

### Option 1: Vercel
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
cd website
vercel --prod

# Add custom domain in Vercel dashboard
```

### Option 2: GitHub Pages + Custom Domain
```bash
# 1. Create GitHub repo and push website files
git init
git add .
git commit -m "Initial website"
git remote add origin [your-repo-url]
git push -u origin main

# 2. Enable GitHub Pages in repo settings
# 3. Add custom domain: peblapp.help
# 4. Configure DNS at your registrar:
#    A record @ → 185.199.108.153
#    A record @ → 185.199.109.153
#    A record @ → 185.199.110.153
#    A record @ → 185.199.111.153
#    CNAME www → [username].github.io
```

### Option 3: Traditional Web Hosting
1. **Upload via FTP/SFTP**:
   - Host: Your hosting provider's server
   - Upload all files from `website` folder
   - Ensure `index.html` is in root directory

2. **Point domain to hosting**:
   - Update nameservers at domain registrar
   - Or add A record pointing to hosting IP

## 📋 Pre-Deployment Checklist

- [x] Domain purchased: peblapp.help ✅
- [x] Email configured: pebl.help@gmail.com ✅
- [x] Website files ready ✅
- [ ] SSL certificate (auto with Netlify/Vercel)
- [ ] DNS configured
- [ ] Test on multiple devices
- [ ] Replace placeholder images (if any)
- [ ] Set up analytics (optional)
- [ ] Submit to Google Search Console

## 🔒 SSL Certificate

Both Netlify and Vercel provide **free SSL certificates** automatically via Let's Encrypt.

For traditional hosting:
- Use Let's Encrypt (free)
- Or purchase SSL from hosting provider

## 📊 Post-Deployment

### 1. Verify Website
- Visit https://peblapp.help
- Test all links and navigation
- Check mobile responsiveness
- Verify contact form/email links

### 2. SEO Setup
```bash
# Create sitemap.xml
# Submit to Google Search Console
# Submit to Bing Webmaster Tools
```

### 3. Analytics (Optional)
- Add Google Analytics
- Add Facebook Pixel
- Set up conversion tracking

### 4. Performance
- Test with Google PageSpeed Insights
- Optimize images if needed
- Enable CDN (included with Netlify/Vercel)

## 🆘 Troubleshooting

### Domain not working?
- DNS changes can take 24-48 hours to propagate
- Check DNS with: https://dnschecker.org
- Verify DNS records are correct

### SSL certificate issues?
- Wait for auto-provisioning (can take a few minutes)
- Ensure DNS is properly configured
- Contact hosting support if issues persist

### Email not working?
- Gmail address (pebl.help@gmail.com) works independently
- For custom domain email, set up email forwarding or G Suite

## 📞 Support

- **Netlify Support**: https://answers.netlify.com/
- **Vercel Support**: https://vercel.com/support
- **DNS Help**: Contact your domain registrar

## 🎉 You're Live!

Once deployed, your website will be accessible at:
- **https://peblapp.help** (primary)
- **https://www.peblapp.help** (with www)

Share your website and start getting users for your Pebl app! 🚀
