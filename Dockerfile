# Sources:
# https://github.com/cypress-io/cypress-docker-images
# https://github.com/lbausch/laravel-ci/blob/master/Dockerfile

# Use cypress/included as base image
FROM cypress/included:latest

# Define build arguments with default values from environment variables
ARG NODE_VERSION=${NODE_VERSION:-22.17.0}
ARG PHP_VERSION=${PHP_VERSION:-8.3}

# Set environment variables from build arguments
ENV NODE_VERSION=${NODE_VERSION} \
    PHP_VERSION=${PHP_VERSION}

USER root

RUN node --version

COPY ./global-profile.sh /tmp/global-profile.sh
RUN cat /tmp/global-profile.sh >> /etc/bash.bashrc && rm /tmp/global-profile.sh

# Install system dependencies
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  # Install Cypress dependencies
  fonts-liberation \
  git \
  libcurl4t64 \
  libcurl3t64-gnutls \
  xdg-utils \
  wget \
  curl \
  # Firefox dependencies
  bzip2 \
  # Add codecs needed for video playback in Firefox
  # https://github.com/cypress-io/cypress-docker-images/issues/150
  mplayer \
  \
  # Additional packages for PHP/Laravel
  build-essential \
  ca-certificates \
  libgtk-3-0 \
  lsb-release \
  openssh-client \
  poppler-utils \
  rsync \
  supervisor \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Add key and repository
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

# Install PHP with all extensions
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  php${PHP_VERSION}-redis \
  php${PHP_VERSION}-bcmath \
  php${PHP_VERSION}-cli \
  php${PHP_VERSION}-curl \
  php${PHP_VERSION}-dom \
  php${PHP_VERSION}-fpm \
  php${PHP_VERSION}-gd \
  php${PHP_VERSION}-imap \
  php${PHP_VERSION}-intl \
  php${PHP_VERSION}-ldap \
  php${PHP_VERSION}-mbstring \
  php${PHP_VERSION}-mysql \
  php${PHP_VERSION}-soap \
  php${PHP_VERSION}-sqlite3 \
  php${PHP_VERSION}-tidy \
  php${PHP_VERSION}-xdebug \
  php${PHP_VERSION}-zip \
  && php -m \
  && php -v \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Remove system MySQL (if any)
RUN apt-get remove --purge 'mysql-.*' || true

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
RUN composer self-update && composer --version

# Browsers (Chrome and Firefox) are already included in cypress/included image
# "fake" dbus address to prevent errors
# https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

# Install Browsershot dependencies (updated for Debian 13 with t64 packages)
# https://spatie.be/docs/browsershot/v2/requirements#content-installing-puppeteer-a-forge-provisioned-server
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  # Core Browsershot/Puppeteer dependencies (from latest docs)
  libx11-xcb1 \
  libxcomposite1 \
  libasound2t64 \
  libatk1.0-0t64 \
  libatk-bridge2.0-0 \
  libcairo2 \
  libcups2t64 \
  libdbus-1-3 \
  libexpat1 \
  libfontconfig1 \
  libgbm1 \
  libgcc-s1 \
  libglib2.0-0t64 \
  libgtk-3-0t64 \
  libnspr4 \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  libstdc++6 \
  libx11-6 \
  libxcb1 \
  libxcursor1 \
  libxdamage1 \
  libxext6 \
  libxfixes3 \
  libxi6 \
  libxrandr2 \
  libxrender1 \
  libxss1 \
  libxtst6 \
  # Additional system packages
  ca-certificates \
  fonts-liberation \
  libnss3 \
  lsb-release \
  xdg-utils \
  wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install Puppeteer and Chrome (following latest Browsershot docs)
RUN npm install --location=global --unsafe-perm puppeteer

# Install Chrome through Puppeteer (as per latest docs)
RUN npx puppeteer browsers install chrome

# Ensure the puppeteer cache directory is accessible
RUN mkdir -p /root/.cache/puppeteer && \
  chmod -R o+rx /root/.cache

# Final cleanup (redundant cleanup removed as it's now done in each apt install)

# versions of local tools
RUN echo  " node version:    $(node -v) \n" \
  "npm version:     $(npm -v) \n" \
  "yarn version:    $(yarn -v) \n" \
  "debian version:  $(cat /etc/debian_version) \n" \
  "Chrome version:  $(google-chrome --version) \n" \
  "Firefox version: $(firefox --version) \n" \
  "git version:     $(git --version) \n" \
  "whoami:          $(whoami) \n"

# A few environment variables to make NPM installs easier
# Good colors for most applications
ENV TERM=xterm
# Avoid million NPM install messages
ENV npm_config_loglevel=warn
# Allow installing when the main user is root
ENV npm_config_unsafe_perm=true

# Copy and set the entrypoint
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["cypress", "run"]
