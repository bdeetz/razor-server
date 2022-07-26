FROM jruby:9.2-alpine

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
# upgrade bundler and install gems
RUN gem install bundler
RUN bundle install

COPY app.rb .
COPY config.yaml.docker .
COPY config.ru .
COPY shiro.ini .
COPY torquebox.rb .
COPY Rakefile .
COPY bin ./bin
RUN chmod +x bin/*
COPY brokers ./brokers
COPY db ./db
COPY hooks ./hooks
# this seems to be needed
COPY jars ./jars
COPY lib ./lib
COPY locales ./locales
COPY spec ./spec
COPY tasks ./tasks

RUN mv config.yaml.docker config.yaml \
    && mkdir -p /var/lib/razor/repo-store

# Install openssl so we can download from HTTPS (e.g. microkernel), plus
# libarchive (must be "-dev" so we can find the .so files).
RUN apk update && apk --update add openssl && apk --update add libarchive-dev

# For debugging.
RUN apk add vim

# install the microkernel
RUN mkdir -p /var/lib/razor/repo-store
WORKDIR /var/lib/razor/repo-store

# wget -c -O microkernel.tar https://pup.pt/razor-microkernel-latest
# Download from brady instead of puppet because brady is muuuuuch faster
RUN wget --no-check-certificate -c -O microkernel.tar https://owncloud.tech-hell.com:8444/index.php/s/icOQ8tAvDvsi8GI/download
RUN tar -xvf microkernel.tar

WORKDIR /usr/src/app

# install postgresql
RUN apk add postgresql

# create a persistent volume for postgres data
VOLUME /var/lib/postgresql/data

ENTRYPOINT ["/usr/src/app/bin/run-local"]
