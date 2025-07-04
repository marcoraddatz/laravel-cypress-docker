#!/bin/bash
set -e

echo "=== Testing Installed Software ==="

# Test Node.js and NPM
echo "Node.js: $(node -v)"
echo "NPM: $(npm -v)"

# Test PHP
echo "PHP: $(php -v | head -n 1)"

# Test Composer
echo "Composer: $(composer --version)"

# Test Browsers
echo "Chrome: $(google-chrome --version)"
echo "Firefox: $(firefox --version)"

echo "=== All tests completed successfully ==="

# Keep the container running if we're in interactive mode
if [ -t 0 ] ; then
  echo "Starting interactive shell..."
  exec /bin/bash
else
  echo "Container started in non-interactive mode."
  exec "$@"
fi
