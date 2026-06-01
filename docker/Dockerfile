FROM ruby:3.2.2

RUN curl https://deb.nodesource.com/setup_10.x | bash - \
    && apt-get install -y --no-install-recommends \
    nodejs

RUN npm install -g npm@6.9.0 pnpm@10.13.1

RUN apt-get install -y --no-install-recommends \
    vim wget git curl rsync patch postgresql postgresql-contrib python-psycopg2 build-essential cmake \
    imagemagick openssl libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev libpq-dev libxml2-dev libxslt-dev libc6-dev libicu-dev \
    libnss3 libatk-bridge2.0-0 libdrm2 libxkbcommon0 libgbm1 libasound2 libxshmfence1 libxcomposite1 libxdamage1 libxrandr2 \
    libpango-1.0-0 libcairo2 libxss1 fonts-liberation \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/*

RUN gem install bundler

CMD [ "bash" ]
