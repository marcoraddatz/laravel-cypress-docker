# Laravel-Cypress-Docker

This image is built on the official [Cypress Docker image](https://github.com/cypress-io/cypress-docker-images/tree/master/browsers/node16.14.2-slim-chrome103-ff102), and another [Laravel CI package](https://github.com/lbausch/laravel-ci/blob/master/Dockerfile), and works with AMD64.

It's a complete image with all operating system dependencies for Cypress, Chrome 103.0.5060.53, Firefox 102.0.1, and Edge undefined browsers. Also, it ships with PHP 8.1, Composer 2, Node.js 16 and NPM 8.

I'm not very good at maintaining open source projects, so please don't build critical infrastructure on this project.

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

      - name: Run Cypress
        env:
          DB_PORT: ${{ job.services.mysql.ports[3306] }}
        run: |
          chmod -R 0777 public
          cp .env.ci .env.testing
          php artisan key:generate
          php artisan serve --port=80 --env=testing --host=localhost  &> /dev/null &
          npx cypress run
```

## Installation
- Adjust the `.env` settings in the job
- Change the host for `php artisan serve` to your `APP_URL` settings
- Ensure that the host matches with the one from the Cypress config
- `DB_HOST` must be `mysql`