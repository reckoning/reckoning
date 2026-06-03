# syntax=docker/dockerfile:1

# Stage 1: Base image with system runtime dependencies
ARG RUBY_VERSION=3.4.7
FROM ruby:${RUBY_VERSION}-slim AS base

WORKDIR /rails

# Runtime packages only (build-essential lives in the build stage).
# - libpq5/libvips42: ActiveRecord + image_processing
# - libjemalloc2: better Ruby memory allocator
# - postgresql-client: rails db:* tasks at deploy/boot
# - Chrome system libs + Google Chrome itself: Grover spawns headless
#   Chrome for invoice/offer PDF generation. We install Google Chrome
#   stable via the official repo so Puppeteer's bundled-Chrome download
#   can be skipped (PUPPETEER_SKIP_DOWNLOAD=1 below).
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      ca-certificates \
      curl \
      gnupg \
      imagemagick \
      libcurl4 \
      libjemalloc2 \
      libpq5 \
      libvips42 \
      poppler-utils \
      postgresql-client \
      shared-mime-info \
      fonts-liberation \
      libnss3 libatk-bridge2.0-0 libdrm2 libxkbcommon0 libgbm1 libasound2t64 \
      libxshmfence1 libxcomposite1 libxdamage1 libxrandr2 libpango-1.0-0 \
      libcairo2 libxss1 \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | \
         gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
         > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y google-chrome-stable && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# jemalloc for reduced fragmentation/memory under Ruby
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

ARG RAILS_ENV="production"
ENV RAILS_ENV="${RAILS_ENV}" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    PUPPETEER_SKIP_DOWNLOAD="1" \
    PUPPETEER_EXECUTABLE_PATH="/usr/bin/google-chrome-stable"

# Stage 2: build gems, install node, precompile assets
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libcurl4-openssl-dev \
      libmagickwand-dev \
      libpq-dev \
      libvips-dev \
      libyaml-dev \
      pkg-config \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Node for Sprockets + Terser (execjs). Pin to current LTS.
ARG NODE_MAJOR=22
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - && \
    apt-get install --no-install-recommends -y nodejs && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*
RUN corepack enable && corepack prepare pnpm@10.13.1 --activate

# Install Ruby gems
COPY Gemfile Gemfile.lock .tool-versions ./
RUN bundle install --jobs 4 && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Install Node deps (puppeteer install script is skipped via env above —
# the slim image already has Google Chrome from the base stage).
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --ignore-scripts

# Application code
COPY . .

# Stamp the build with the deploy SHA so the admin UI / Sentry can show it
ARG GIT_REVISION=""
RUN if [ -n "$GIT_REVISION" ]; then echo "$GIT_REVISION" > REVISION; fi

# bootsnap iseq+yjit warmup — boot time drops noticeably
RUN bundle exec bootsnap precompile --gemfile app/ lib/ config/

# Compile Sprockets assets. SECRET_KEY_BASE_DUMMY=1 lets Rails initialize
# without a real key at build time; runtime injects the real one.
RUN --mount=type=secret,id=RAILS_MASTER_KEY \
    RAILS_MASTER_KEY="$(cat /run/secrets/RAILS_MASTER_KEY 2>/dev/null || true)" \
    SECRET_KEY_BASE_DUMMY=1 \
    bin/rails assets:precompile

# Stage 3: final image
FROM base

# Bring in vendored gems and the app
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Strip files not needed at runtime
RUN rm -rf \
      node_modules \
      test \
      tmp/cache \
      vendor/cache \
    && mkdir -p tmp/pids tmp/cache log storage

# Run as non-root for defense in depth
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp public
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 8240

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
