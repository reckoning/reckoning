FROM ruby:2.5.1-alpine

RUN apk add --update git bash postgresql nodejs yarn redis

RUN gem install bundler

CMD [ "bash" ]
