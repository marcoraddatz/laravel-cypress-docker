# Laravel-Cypress-Docker (WIP)

> Work in progress!

This image is built on the official [Cypress Docker image](https://github.com/cypress-io/cypress-docker-images/tree/master/browsers/node16.14.2-slim-chrome103-ff102) and another [Laravel CI package](https://github.com/lbausch/laravel-ci/blob/master/Dockerfile).

It's a complete image with all operating system dependencies for Cypress, Chrome 103.0.5060.53, Firefox 102.0.1, and Edge undefined browsers. Also, it ships with PHP 8.1, Composer 2, Node.js 16 and NPM 8.

I'm not very good at maintaining open source projects, so please don't build critical infrastructure on this project.

## Example GitHub workflow

```
name: Continuous Integration

on: [push, pull_request]

jobs:
  test:
    name: Run Test Suites
    runs-on: ubuntu-latest
    container:
      image: marcoraddatz/laravel-cypress-docker:latest
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
        uses: cypress-io/github-action@v4
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          start: php artisan serve
```