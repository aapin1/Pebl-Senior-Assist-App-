# AdMob Setup Instructions for Pebl App

## ✅ What's Already Done

I've implemented a complete AdMob system with:
- ✅ Friendly pre-ad dialog for seniors
- ✅ Interstitial ads every 3 questions
- ✅ Query counter with persistent storage
- ✅ Ad service with automatic loading
- ✅ Platform configurations (iOS & Android)
- ✅ Senior-friendly messaging

## 🚀 How to Complete Setup

### Step 1: Get Your AdMob Account Ready

1. **Go to AdMob**: https://apps.admob.com/
2. **Sign in** with your Google account (use the same one for consistency)
3. **Accept terms** and complete account setup

### Step 2: Create Your App in AdMob

#### For iOS:
1. Click **"Apps"** in left sidebar
2. Click **"Add App"**
3. Select **"iOS"**
4. Choose **"Yes"** (app is listed on app store) or **"No"** (not yet)
5. Enter app name: **"Pebl"** or **"Pebl Tech Help"**
6. Click **"Add"**
7. **Copy the App ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`)

#### For Android (when ready):
1. Repeat above steps but select **"Android"**
2. Use same app name
3. **Copy the Android App ID**

### Step 3: Create Ad Units

1. In your app dashboard, click **"Ad units"**
2. Click **"Add ad unit"**
3. Select **"Interstitial"**
4. Name it: **"Question Interstitial"**
5. Click **"Create ad unit"**
6. **Copy the Ad Unit ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ`)

### Step 4: Replace Test IDs with Your Real IDs

#### Update iOS App ID:
Open: `ios/Runner/Info.plist`
```xml
<key>GADApplicationIdentifier</key>
<string>YOUR_IOS_APP_ID_HERE</string>
```

#### Update Android App ID:
Open: `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="YOUR_ANDROID_APP_ID_HERE"/>
```

#### Update Ad Unit IDs:
Open: `lib/services/ad_service.dart`
```dart
// Replace these lines:
static const String _androidInterstitialAdUnitId = 'YOUR_ANDROID_AD_UNIT_ID';
static const String _iosInterstitialAdUnitId = 'YOUR_IOS_AD_UNIT_ID';
```

### Step 5: Test Your Ads

1. **Run the app** on a real device (ads don't work well in simulator)
2. **Ask 3 questions** - you should see:
   - Friendly dialog: "To keep Pebl free for everyone..."
   - Then the actual ad
3. **Verify the flow**:
   - Dialog appears ✅
   - User taps "Continue" ✅
   - Ad shows ✅
   - User can close ad ✅
   - App continues normally ✅

### Step 6: Enable Real Ads

**IMPORTANT:** Test ads show immediately, but real ads may take time:
- **First 24 hours**: Ads may not show (AdMob learning period)
- **After 24-48 hours**: Ads should show normally
- **Fill rate**: Won't be 100% - this is normal

## 📊 AdMob Dashboard

Monitor your ads at: https://apps.admob.com/

You can see:
- **Impressions**: How many ads were shown
- **Revenue**: How much you've earned
- **eCPM**: Earnings per 1000 impressions
- **Fill rate**: % of ad requests that showed ads

## 🎯 Current Ad Settings

- **Frequency**: Every 3 questions
- **Ad Type**: Interstitial (full-screen)
- **Targeting**: Family-friendly, technology-related
- **User Experience**: Friendly dialog before ad

## 🔧 Customization Options

### Change Ad Frequency:
In `lib/services/ad_service.dart`:
```dart
static const int _queriesBeforeAd = 3; // Change to 5, 10, etc.
```

### Disable Ads for Testing:
```dart
AdService().setAdsEnabled(false);
```

### Reset Counter:
```dart
await AdService().resetQueryCounter();
```

## ⚠️ Important Notes

1. **Test IDs are currently active** - Replace them before publishing
2. **Real ads won't show in test mode** - Use test IDs for development
3. **AdMob policies**: Ensure your app complies with AdMob policies
4. **Senior-friendly**: The dialog explains ads in simple terms
5. **Privacy**: Update privacy policy to mention ads

## 📱 App Store Requirements

When submitting to App Store:
1. ✅ Mention ads in app description
2. ✅ Include "Contains Ads" in app info
3. ✅ Update privacy policy about ad data
4. ✅ Ensure ads are family-friendly (already configured)

## 🆘 Troubleshooting

### Ads not showing?
- Wait 24-48 hours after setup
- Check AdMob dashboard for errors
- Verify App ID and Ad Unit IDs are correct
- Test on real device, not simulator
- Check internet connection

### Dialog shows but no ad?
- This is normal during learning period
- Check AdMob dashboard for fill rate
- Ensure test mode is disabled for real ads

### App crashes when showing ad?
- Verify all IDs are correct
- Check AdMob account is approved
- Review error logs in console

## 💰 Revenue Expectations

- **eCPM**: Typically $1-$5 per 1000 impressions
- **Fill Rate**: Usually 60-90%
- **Example**: 1000 users × 10 questions each × 3 ads = ~3,333 impressions
- **Estimated**: $3-$17 per 1000 active users per month

## 📞 Support

- **AdMob Help**: https://support.google.com/admob
- **AdMob Community**: https://groups.google.com/g/google-admob-ads-sdk
- **Flutter Ads Plugin**: https://pub.dev/packages/google_mobile_ads

---

**Your AdMob implementation is complete and ready to go! Just replace the test IDs with your real AdMob IDs.** 🎉
