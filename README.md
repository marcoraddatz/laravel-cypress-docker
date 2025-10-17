# Laravel-Cypress-Docker

This image is built on the official [Cypress Docker image](https://hub.docker.com/r/cypress/included/), and another [Laravel CI package](https://github.com/lbausch/laravel-ci/blob/master/Dockerfile), and works with both AMD64 and ARM64.

It's a complete image with all operating system dependencies for Cypress, Chrome, and Firefox browsers.
**Note:** On ARM64, only Firefox is available due to [this issue](https://github.com/cypress-io/cypress-docker-images/issues/695#issuecomment-2282696415).

## Available Images

The following PHP and Node.js combinations are available on [Docker Hub](https://hub.docker.com/r/marcoraddatz/laravel-cypress-docker/tags):

| PHP Version | Node 24 | Node 22 | Node 20 |
|-------------|---------|---------|---------|
| **PHP 8.4** | `php8.4-node24` | `php8.4-node22` | `php8.4-node20` |
| **PHP 8.3** | `php8.3-node24` | `php8.3-node22` | `php8.3-node20` |
| **PHP 8.2** | `php8.2-node24` | `php8.2-node22` | `php8.2-node20` |

### Usage Examples

```bash
# Use latest (PHP 8.4 + Node 24)
docker pull marcoraddatz/laravel-cypress-docker:latest

# Use specific PHP/Node combination
docker pull marcoraddatz/laravel-cypress-docker:php8.3-node22

# Use in Docker Compose
image: marcoraddatz/laravel-cypress-docker:php8.3-node22
```

### Features Included

- **PHP Extensions**: bcmath, curl, dom, gd, imap, intl, ldap, mbstring, mysql, redis, soap, sqlite3, tidy, xdebug, zip
- **Browsershot Support**: Full Puppeteer v24+ and Chrome setup for PDF generation
- **Testing Stack**: Cypress, Chrome, Firefox browsers
- **Multi-platform**: AMD64 and ARM64 support

## Build

## Example GitHub workflow

```yml
name: Continuous Integration

on: [push, pull_request]

jobs:
  test:
    name: Run Test Suites
    runs-on: ubuntu-latest
    container:
      image: marcoraddatz/laravel-cypress-docker:latest
    services:
      mysql:
        image: mysql:8.0
        # https://owenconti.com/posts/failing-to-start-mysql-inside-github-actions
        env:
          MYSQL_ALLOW_EMPTY_PASSWORD: yes
          MYSQL_DATABASE: testing
          MYSQL_USER: user
          MYSQL_PASSWORD: password
          MYSQL_ROOT_PASSWORD: root
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3
    steps:
      - uses: actions/checkout@v3

      - name: Install Composer dependencies
        run: |
          composer -V
          composer install --prefer-dist --no-ansi --no-interaction --no-progress --ignore-platform-reqs

      - name: Install NPM dependencies
        run: npm ci

      - name: Compile NPM
        run: npm run prod

      - name: Update hosts file
        run: |
          echo "127.0.0.1 example.test" | tee -a /etc/hosts

      - name: Run Cypress
        env:
          DB_PORT: ${{ job.services.mysql.ports[3306] }}
        run: |
          # Avoid Cypress exceptions through re-install: https://github.com/cypress-io/cypress/issues/5440#issuecomment-547851042
          npx cypress install --force
          chmod -R 0777 public
          cp .env.cypress .env
          php artisan key:generate
          php artisan serve --port=80 --host=example.test  &> /dev/null &
          npx cypress run
```

## Installation
- Change the host for `php artisan serve` to your `APP_URL` settings
- Ensure that the host matches with the one from the Cypress config (replace `example.test`)

### Sample `.env.cypress`

```
APP_NAME=Cypress
APP_ENV=testing
APP_KEY=
APP_DEBUG=true
APP_URL=http://example.test

LOG_CHANNEL=stack

FILESYSTEM_CLOUD=local

DB_CONNECTION=mysql
DB_HOST=mysql
DB_DATABASE=testing
DB_USERNAME=user
DB_PASSWORD=password
DB_PORT=3306

BROADCAST_DRIVER=log
CACHE_DRIVER=file
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

MAIL_MAILER=array
```
