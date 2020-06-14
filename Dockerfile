# First ARGs only used in instruction FROM
ARG base_build_image="crystallang/crystal:latest-alpine"
# You can override ARG env vars on docker build or in docker-compose
# Need to redeclare ARG env vars defined before FROM instruction in order to use it
# ARG env vars are only available during building the image
ARG app_user=crystal
ARG app_user_group=crystal
ARG app_user_uid=1000
ARG app_user_gid=1000
ARG app_user_home="/home/$app_user"
ARG app_root="$app_user_home/app"
ARG crystal_env=production
ARG node_env=production
ARG install_yarn=true
ARG app_port="5000"
ARG dev_ports="5000 6000 1234 26162"
# alpine system packages required to build and run rails server
ARG alpine_build_packages=" \
  build-base curl git vim netcat-openbsd tzdata postgresql-client \
  postgresql-dev readline-dev yaml-dev zlib-dev sqlite-dev \
  bash-completion git-bash-completion colordiff gzip sudo bash openssh stow"
ARG alpine_production_packages=" \
  tini tzdata postgresql-client \
  readline netcat-openbsd curl"
# You can install extra system packages at build time by setting this var
ARG alpine_extra_build_packages=""
ARG alpine_extra_production_packages=""

############### builder stage start ###############
FROM $base_build_image AS builder
ARG base_build_image
ARG app_user
ARG app_user_group
ARG app_user_uid
ARG app_user_gid
ARG app_user_home
ARG app_root
ARG crystal_env
ARG node_env
ARG install_yarn
ARG alpine_build_packages
ARG alpine_extra_build_packages
# Default env vars and paths set inside the image
ENV BASE_DOCKER_IMAGE=$base_build_image
ENV APP_ROOT=$app_root
ENV PAGER="less -S"
# ENV PATH="$app_user_home/.gem/bin:$PATH"
ENV SHELL="/bin/bash"
ENV CRYSTAL_ENV=$crystal_env
ENV NODE_ENV=$node_env
ENV BUNDLE_APP_CONFIG="$APP_ROOT/.bundle"
ENV APP_NODE_PATH="$APP_ROOT/node_modules"
ENV BUNDLE_PATH="$APP_ROOT/vendor/bundle"
# Reset user to root
USER root:root
# Install packages
RUN apk update && \
    apk upgrade && \
    apk add --update --no-cache \
    $alpine_build_packages $alpine_extra_build_packages
# Install yarn and nodejs
RUN if [ "$install_yarn" = "true" ] ; then \
    apk add --update --no-cache nodejs npm yarn ; \
  fi
RUN curl -L https://github.com/amberframework/amber/archive/stable.tar.gz | tar xz && \
  cd amber-stable/ && \
  make && \
  make install
# Add app user group
RUN if $(grep -i -e ":$app_user_gid:" /etc/group > /dev/null 2>&1) ; then \
    echo "App user gid already exists, not adding it" ; \
  else \
    addgroup --gid $app_user_gid $app_user_group ; \
  fi
# Add app user and setup sudo
RUN if $(id $app_user_uid > /dev/null 2>&1) ; then \
    echo "App user uid already exists, not adding it" ; \
  else \
    app_user_group_name=$(getent group $app_user_gid | cut -d: -f1) && \
    adduser -D -u $app_user_uid -G $app_user_group_name $app_user && \
    addgroup $app_user wheel && \
    echo "%wheel ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers ; \
  fi
RUN mkdir -p $APP_NODE_PATH && \
  mkdir -p $BUNDLE_PATH && \
  mkdir -p $app_user_home && \
  chown -R $app_user_uid:$app_user_gid $app_user_home && \
  chown -R $app_user_uid:$app_user_gid $APP_ROOT
WORKDIR $APP_ROOT
USER $app_user_uid:$app_user_gid
EXPOSE $dev_ports
CMD echo 'Stage: builder'
############### builder stage done ###############
