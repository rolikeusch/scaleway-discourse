## -*- docker-image-name: "armbuild/scw-app-discourse:latest" -*-
FROM armbuild/scw-distrib-ubuntu:vivid
MAINTAINER Scaleway <opensource@scaleway.com> (@scaleway)


# Prepare rootfs for image-builder
RUN /usr/local/sbin/builder-enter


# Install packages
RUN apt-get -q update                   \
 && apt-get --force-yes -y -qq upgrade  \
 && apt-get --force-yes install -y -q   \
         build-essential libssl-dev \
		 libyaml-dev git libtool \
		 libxslt-dev libxml2-dev \
		 libpq-dev gawk curl \
		 pngcrush imagemagick vim \
		 software-properties-common \
		 redis-server postfix nginx \
		 postgresql postgresql-contrib \
		 ruby ruby-dev redis-server \
		 libreadline6-dev libsqlite3-dev sqlite3 \
		 autoconf libgdbm-dev libncurses5-dev \
		 automake bison pkg-config libffi-dev \
		 nodejs libruby2.1


RUN ln -s /usr/lib/arm-linux-gnueabihf/libruby-2.1.so.2.0 /usr/lib/libruby.so.2.1


# Install the Bundler gem
RUN gem install bundler --no-ri --no-rdoc \
  && bundle config --global jobs 4


# Create git user for GitLab
RUN adduser --disabled-login --gecos 'Discourse' discourse


# Init database
RUN /etc/init.d/postgresql start \
  && sudo -u postgres psql -d template1 -c 'CREATE USER discourse CREATEDB;' \
  && sudo -u postgres psql -d template1 -c 'CREATE DATABASE discourse OWNER discourse;' \
  && sudo su postgres -c "psql discourse -c 'CREATE EXTENSION hstore;'" \
  && sudo su postgres -c "psql discourse -c 'CREATE EXTENSION pg_trgm;'" \
  && /etc/init.d/postgresql stop


# Clone discourse
ENV DISCOURSE_VERSION 1.2.3
RUN git clone --depth 1 --branch v${DISCOURSE_VERSION} git://github.com/discourse/discourse.git /var/www/discourse


# Upload patches
ADD ./patches/customgems /var/www/discourse/customgems


# Upgrade rubygem
# RUN gem update --system


RUN cd /var/www/discourse/customgems \
  && wget -q https://fr-1.storage.online.net/gems/libv8_therubyracer.tar.gz \
  && tar -xf libv8_therubyracer.tar.gz \
  && rm -rf libv8_therubyracer.tar.gz


# Install Discourse
RUN cd /var/www/discourse \
  && patch Gemfile < customgems/patches/Gemfile.patch \
  && patch Gemfile.lock < customgems/patches/Gemfile.lock.patch \
  && patch config/discourse.pill.sample < customgems/patches/discourse.pill.sample.patch \
  && chown -R discourse:discourse /var/www/discourse


# Install libv8 / therubyracer
RUN cd /var/www/discourse/customgems \
  && cd libv8 \
  && bundle install \
  && cd pkg \
  && bundle exec gem install libv8-3.16.14.3-armv7l-linux.gem


RUN cd /var/www/discourse/customgems \
  && cd therubyracer \
  && bundle install \
  && cd pkg \
  && bundle exec gem install therubyracer-0.12.1.gem


RUN chmod 1777 /tmp \
  && cd /var/www/discourse \
  && bundle install --no-deployment --without test development


# Configure Discourse
RUN cd /var/www/discourse/config \
  && cp discourse_defaults.conf discourse.conf \
  && cp discourse.pill.sample discourse.pill \
  && chown -R discourse:discourse /var/www/discourse


# Init database
RUN cd /var/www/discourse \
  && /etc/init.d/redis-server start \
  && /etc/init.d/postgresql start \
  && sudo su discourse -c "RUBY_GC_MALLOC_LIMIT=90000000 RAILS_ENV=production bundle exec rake db:migrate" \
  && sudo su discourse -c "RUBY_GC_MALLOC_LIMIT=90000000 RAILS_ENV=production bundle exec rake assets:precompile" \
  && /etc/init.d/redis-server stop \
  && /etc/init.d/postgresql stop


# Configure Nginx
RUN cp /var/www/discourse/config/nginx.global.conf /etc/nginx/conf.d/local-server.conf \
  && cp /var/www/discourse/config/nginx.sample.conf /etc/nginx/conf.d/discourse.conf


RUN mkdir -p /var/nginx/cache


# Configure Bluepill
RUN gem install bluepill \
  && sudo su discourse -c "echo 'alias bluepill=\"NOEXEC_DISABLE=1 bluepill --no-privileged -c ~/.bluepill\"'" >> ~/.bash_aliases \
  && sudo su discourse -c '(crontab -l ; echo "@reboot RUBY_GC_MALLOC_LIMIT=90000000 RAILS_ROOT=/var/www/discourse RAILS_ENV=production NUM_WEBS=4 bluepill --no-privileged -c ~/.bluepill load /var/www/discourse/config/discourse.pill") | crontab -'


ADD ./patches/etc/ /etc/


RUN chmod +x /etc/rc.local \
 && chmod +x /etc/update-motd.d/70-discourse \
 && rm -rf /etc/nginx/sites-enabled/default


# Clean rootfs from image-builder
RUN /usr/local/sbin/builder-leave
