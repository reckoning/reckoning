ARG RUBY_VERSION=3.0.4

FROM ruby:$RUBY_VERSION-slim

## install main deps
RUN apt-get update && apt-get install -y \
  build-essential wget git nodejs libpq-dev curl

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz \
  && tar -xf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz \
  && mv wkhtmltox/bin/wkhtmltopdf /usr/bin/wkhtmltopdf

RUN mkdir -p /app
WORKDIR /app
# Copy the Gemfile as well as the Gemfile.lock and install
# the RubyGems. This is a separate step so the dependencies
# will be cached unless changes to one of those two files
# are made.
COPY .ruby-version Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install --jobs 20 --retry 5
# Copy the main application.
COPY . ./
# Expose port 3000 to the Docker host, so we can access it
# from the outside.
EXPOSE 3000

COPY docker/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
# The main command to run when the container starts. Also
# tell the Rails dev server to bind to all interfaces by
# default.
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
