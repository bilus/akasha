FROM ruby:2.5.1-alpine3.7
RUN set -eux; \
    apk update; \
    apk add git openssl; \
    apk add build-base libffi-dev

ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz

COPY Gemfile /var/akasha/
COPY Gemfile.lock /var/akasha/
COPY akasha.gemspec /var/akasha/
COPY lib/akasha/version.rb /var/akasha/lib/akasha/version.rb

RUN set -eux; \
    cd /var/akasha; \
    bundle

COPY . /var/akasha/
WORKDIR /var/akasha/

CMD dockerize -wait http://eventstore:2113 bundle exec rspec --tag integration