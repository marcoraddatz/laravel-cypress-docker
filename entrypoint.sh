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
# Chrome is typically installed in /opt/google/chrome in cypress/included
if [ -f "/opt/google/chrome/chrome" ]; then
  echo "Chrome: $(/opt/google/chrome/chrome --version)"
else
  echo "Chrome: Not found in /opt/google/chrome/chrome"
  echo "Trying to find Chrome..."
  find / -name chrome -type f -executable 2>/dev/null | grep -v "snap" | head -n 1 | xargs -I{} sh -c 'echo "Chrome: $({} --version)"' || echo "Chrome not found"
fi

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
