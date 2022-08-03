FROM jruby:9.2-alpine

# BE SURE TO FORWARD THESE
EXPOSE 69/udp
EXPOSE 8150/tcp

# install postgresql
RUN apk add postgresql postgresql-client

USER postgres

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
# upgrade bundler and install gems
RUN gem install bundler
RUN bundle install

COPY app.rb .
COPY config.ru .
COPY shiro.ini .
COPY torquebox.rb .
COPY Rakefile .
COPY brokers ./brokers
COPY db ./db
COPY hooks ./hooks
# this seems to be needed
COPY jars ./jars
COPY lib ./lib
COPY locales ./locales
COPY spec ./spec
COPY tasks ./tasks

USER root

RUN mkdir -p /var/lib/razor/repo-store \
    && chmod -R 777 /var/lib/razor/repo-store

# Install openssl so we can download from HTTPS (e.g. microkernel), plus
# libarchive (must be "-dev" so we can find the .so files).
RUN apk update && apk --update add openssl && apk --update add libarchive-dev

# For debugging.
RUN apk add vim

USER postgres

# install the microkernel
WORKDIR /var/lib/razor/repo-store

# wget -c -O microkernel.tar https://pup.pt/razor-microkernel-latest
# Try to download from brady first instead of puppet because brady is muuuuuch faster
RUN wget --no-check-certificate -c -O microkernel.tar https://owncloud.tech-hell.com:8444/index.php/s/icOQ8tAvDvsi8GI/download || wget -c -O microkernel.tar https://pup.pt/razor-microkernel-latest
RUN tar -xvf microkernel.tar

WORKDIR /usr/src/app

USER root

# install gosu https://github.com/tianon/gosu/blob/master/INSTALL.md
ENV GOSU_VERSION 1.14
RUN set -eux; \
	\
	apk add --no-cache --virtual .gosu-deps \
		ca-certificates \
		dpkg \
		gnupg \
	; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
# verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	command -v gpgconf && gpgconf --kill all || :; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	\
# clean up fetch dependencies
	apk del --no-network .gosu-deps; \
	\
	chmod +x /usr/local/bin/gosu; \
# verify that the binary works
	gosu --version; \
	gosu nobody true

RUN apk add curl gcc libc-dev

# install su-exec for fancy things
RUN  curl -o /usr/local/bin/su-exec.c https://raw.githubusercontent.com/ncopa/su-exec/master/su-exec.c \
     && gcc -Wall /usr/local/bin/su-exec.c -o/usr/local/bin/su-exec \
     && chown root:root /usr/local/bin/su-exec \
     && chmod 0755 /usr/local/bin/su-exec \
     && rm /usr/local/bin/su-exec.c

# install tftp server
RUN apk add tftp-hpa
RUN apk add strace

# configure tftp server
COPY in.tftpd.docker .
RUN mv in.tftpd.docker /etc/conf.d/in.tftpd

RUN rm -rf /var/tftpboot && ln -s /var/lib/razor/repo-store /var/tftpboot && chown -R postgres:postgres /var/tftpboot

USER postgres

# install razor client
RUN gem install faraday -v 1.10.0
RUN gem install razor-client

# create a persistent volume for postgres data
VOLUME /var/lib/postgresql/data

COPY bin ./bin
COPY config.yaml.docker .
RUN mv config.yaml.docker config.yaml

USER root
RUN chmod +x bin/*
RUN addgroup -S razor
RUN adduser -G razor -D razor
RUN echo "razor:razor" | chpasswd

USER postgres

ENTRYPOINT ["/usr/src/app/bin/run-local"]
