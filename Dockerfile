ARG RUBY_VERSION=3.0.4

FROM ruby:$RUBY_VERSION-slim

ARG NODE_VERSION=16
ARG BUNDLER_VERSION=2.2.33

ENV RAILS_ENV=production

## install main deps
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  && apt-get clean \
  && rm -rf /tmp/* /var/lib/apt/lists/*

RUN curl https://deb.nodesource.com/setup_current.x | bash - \
  && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -\
  && echo "deb https://deb.nodesource.com/node_${NODE_VERSION}.x focal main" | tee /etc/apt/sources.list.d/node.list

## install main deps
RUN apt-get update && apt-get install -y --no-install-recommends \
  nodejs=$NODE_VERSION* wget yarn git gcc g++ make rsync patch postgresql-client build-essential \
  cmake imagemagick openssl libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev \
  libpq-dev libxml2-dev libxslt-dev libc6-dev libicu-dev xvfb bzip2 libssl-dev \
  unzip shared-mime-info \
  && apt-get clean \
  && rm -rf /tmp/* /var/lib/apt/lists/*

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz \
  && tar -xf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz \
  && mv wkhtmltox/bin/wkhtmltopdf /usr/bin/wkhtmltopdf

## install bundler
RUN gem update --system && gem install bundler -v $BUNDLER_VERSION

WORKDIR /reckoning

COPY app /reckoning/app
COPY config /reckoning/config
COPY db /reckoning/db
COPY bin /reckoning/bin
COPY lib /reckoning/lib
COPY public /reckoning/public
COPY vendor /reckoning/vendor
COPY .ruby-version /reckoning/.ruby-version
COPY Rakefile /reckoning/Rakefile
COPY Gemfile /reckoning/Gemfile
COPY Gemfile.lock /reckoning/Gemfile.lock
COPY config.ru /reckoning/config.ru

RUN bundle install

# Add a script to be executed every time the container starts.
COPY docker/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

RUN mkdir -p /reckoning/tmp/pids && mkdir -p /reckoning/log

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]


