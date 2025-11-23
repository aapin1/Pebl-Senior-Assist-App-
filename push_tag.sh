#!/bin/bash

echo "Attempting to push tag v1.0-appstore-no-medicine to GitHub..."
echo ""

# Try with SSL verification disabled temporarily
GIT_SSL_NO_VERIFY=true git push origin v1.0-appstore-no-medicine

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully pushed tag to GitHub!"
    echo "View it at: https://github.com/aapin1/app-dev/releases/tag/v1.0-appstore-no-medicine"
else
    echo ""
    echo "❌ Push failed. Please try manually:"
    echo "   cd \"$(pwd)\""
    echo "   GIT_SSL_NO_VERIFY=true git push origin v1.0-appstore-no-medicine"
fi
