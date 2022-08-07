# Sources:
# https://github.com/cypress-io/cypress-docker-images/tree/master/browsers/node16.14.2-slim-chrome103-ff102
# https://github.com/lbausch/laravel-ci/blob/master/Dockerfile

FROM cypress/base:16.14.2-slim

USER root

RUN node --version

COPY ./global-profile.sh /tmp/global-profile.sh
RUN cat /tmp/global-profile.sh >> /etc/bash.bashrc && rm /tmp/global-profile.sh

# Install Cypress dependencies
RUN apt-get update && \
  apt-get install -y \
  fonts-liberation \
  git \
  libcurl4 \
  libcurl3-gnutls \
  libcurl3-nss \
  xdg-utils \
  wget \
  curl \
  # firefox dependencies
  bzip2 \
  # add codecs needed for video playback in firefox
  # https://github.com/cypress-io/cypress-docker-images/issues/150
  mplayer \
  \
  # Additional packages for PHP/Laravel
  build-essential \
  ca-certificates \
  curl \
  libgtk-3-0 \
  lsb-release \
  default-mysql-client \
  openssh-client \
  poppler-utils \
  rsync \
  supervisor \
  \
  # clean up
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean

# Add key and repository
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

# Install PHP
RUN apt-get update && \
  apt-get install -y \
  php-redis \
  php8.1-bcmath \
  php8.1-cli \
  php8.1-curl \
  php8.1-dom \
  php8.1-fpm \
  php8.1-gd \
  php8.1-imap \
  php8.1-intl \
  php8.1-ldap \
  php8.1-mbstring \
  php8.1-mysql \
  php8.1-soap \
  php8.1-sqlite \
  php8.1-tidy \
  php8.1-xdebug \
  php8.1-zip \
  && php -m \
  && php -v

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
RUN composer self-update && composer --version

# Install libappindicator3-1 - not included with Debian 11
RUN wget --no-verbose /usr/src/libappindicator3-1_0.4.92-7_amd64.deb "http://ftp.us.debian.org/debian/pool/main/liba/libappindicator/libappindicator3-1_0.4.92-7_amd64.deb" && \
  dpkg -i /usr/src/libappindicator3-1_0.4.92-7_amd64.deb ; \
  apt-get install -f -y && \
  rm -f /usr/src/libappindicator3-1_0.4.92-7_amd64.deb

# Install Chrome browser
RUN node -p "process.arch === 'arm64' ? 'Not downloading Chrome since we are on arm64: https://crbug.com/677140' : process.exit(1)" || \
  (wget --no-verbose -O /usr/src/google-chrome-stable_current_amd64.deb "http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_103.0.5060.53-1_amd64.deb" && \
  dpkg -i /usr/src/google-chrome-stable_current_amd64.deb ; \
  apt-get install -f -y && \
  rm -f /usr/src/google-chrome-stable_current_amd64.deb)

# "fake" dbus address to prevent errors
# https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

# Install Firefox browser
RUN node -p "process.arch === 'arm64' ? 'Not downloading Firefox since we are on arm64: https://bugzilla.mozilla.org/show_bug.cgi?id=1678342' : process.exit(1)" || \
  (wget --no-verbose -O /tmp/firefox.tar.bz2 https://download-installer.cdn.mozilla.net/pub/firefox/releases/102.0.1/linux-x86_64/en-US/firefox-102.0.1.tar.bz2 && \
  tar -C /opt -xjf /tmp/firefox.tar.bz2 && \
  rm /tmp/firefox.tar.bz2 && \
  ln -fs /opt/firefox/firefox /usr/bin/firefox)

# versions of local tools
RUN echo  " node version:    $(node -v) \n" \
  "npm version:     $(npm -v) \n" \
  "yarn version:    $(yarn -v) \n" \
  "debian version:  $(cat /etc/debian_version) \n" \
  "Chrome version:  $(google-chrome --version) \n" \
  "Firefox version: $(firefox --version) \n" \
  "Edge version:    n/a \n" \
  "git version:     $(git --version) \n" \
  "whoami:          $(whoami) \n"

# a few environment variables to make NPM installs easier
# good colors for most applications
ENV TERM=xterm
# avoid million NPM install messages
ENV npm_config_loglevel=warn
# allow installing when the main user is root
ENV npm_config_unsafe_perm=true