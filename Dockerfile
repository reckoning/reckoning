FROM ruby:2.5.1-alpine

RUN apk add --update git bash postgresql postgresql-dev nodejs yarn redis \
                     build-base libxml2-dev libxslt-dev sqlite-dev \
    && rm -rf /var/cache/apk/*

RUN gem install bundler

CMD [ "bash" ]
