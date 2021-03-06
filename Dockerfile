# First ARGs only used in instruction FROM
ARG base_build_image="crystallang/crystal:latest-alpine"
# You can override ARG env vars on docker build or in docker-compose
# Need to redeclare ARG env vars defined before FROM instruction in order to use it
# ARG env vars are only available during building the image
ARG base_app_image="alpine:3.11"
ARG app_user=alpine
ARG app_user_group=alpine
ARG app_user_uid=1000
ARG app_user_gid=1000
ARG app_user_home="/home/$app_user"
ARG app_root="$app_user_home/app"
ARG crystal_env=production
ARG node_env=production
ARG install_yarn=true
ARG app_port="8080"
ARG dev_ports="5000 6000 1234 26162"
# alpine system packages required to build and run rails server
ARG alpine_build_packages=" \
  build-base gdb curl git vim netcat-openbsd tzdata postgresql-client \
  postgresql-dev readline-dev yaml-dev zlib-dev sqlite-dev sqlite-static \
  bash-completion git-bash-completion colordiff gzip sudo bash openssh stow"
ARG alpine_production_packages="tini tzdata curl"
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
ENV APP_NODE_MODULES_PATH="$APP_ROOT/node_modules"
ENV APP_LIB_PATH="$APP_ROOT/lib"
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
  shards install --production && \
  crystal build -o /usr/local/bin/amber src/amber/cli.cr --release --static -p --no-debug
# Add app user group
RUN addgroup --gid $app_user_gid $app_user_group && \
    adduser -D -u $app_user_uid -G $app_user_group $app_user && \
    addgroup $app_user wheel && \
    echo "%wheel ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN mkdir -p $APP_NODE_MODULES_PATH && \
  mkdir -p $APP_LIB_PATH && \
  mkdir -p $app_user_home && \
  chown -R $app_user_uid:$app_user_gid $app_user_home && \
  chown -R $app_user_uid:$app_user_gid $APP_ROOT
WORKDIR $APP_ROOT
USER $app_user_uid:$app_user_gid
EXPOSE $dev_ports
CMD echo 'Stage: builder'
############### builder stage done ###############

############### assets stage start ###############
FROM builder AS assets
ARG app_user_uid
ARG app_user_gid
COPY --chown=$app_user_uid:$app_user_gid shard.yml shard.lock ./
RUN shards install --production 
COPY --chown=$app_user_uid:$app_user_gid . .
RUN shards build pet-tracker --release --static
############### assets stage end ###############

############### app stage start ###############
FROM $base_app_image as app
ARG base_build_image
ARG app_user
ARG app_user_group
ARG app_user_uid
ARG app_user_gid
ARG app_user_home
ARG app_root
ARG crystal_env
ARG node_env
ARG app_port
ARG alpine_production_packages
ARG alpine_extra_production_packages
# Default env vars and paths set inside the image
ENV BASE_DOCKER_IMAGE=$base_build_image
ENV APP_ROOT=$app_root
ENV APP_PORT=$app_port
ENV PAGER="less -S"
# ENV PATH="$app_user_home/.gem/bin:$PATH"
ENV SHELL="/bin/sh"
ENV CRYSTAL_ENV=$crystal_env
ENV NODE_ENV=$node_env
# Reset user to root
USER root:root
# Install packages
RUN apk update && \
    apk upgrade && \
    apk add --update --no-cache \
    $alpine_production_packages $alpine_extra_production_packages
# Add app user group
RUN addgroup --gid $app_user_gid $app_user_group && \
    adduser -D -u $app_user_uid -G $app_user_group $app_user
RUN mkdir -p $app_user_home && \
  mkdir -p $APP_ROOT && \
  chown -R $app_user_uid:$app_user_gid $app_user_home && \
  chown -R $app_user_uid:$app_user_gid $APP_ROOT
WORKDIR $APP_ROOT
COPY --chown=$app_user_uid:$app_user_gid . .
COPY --chown=$app_user_uid:$app_user_gid --from=assets $APP_ROOT/bin/pet-tracker bin/
COPY --from=assets /usr/local/bin/amber /usr/local/bin/
RUN rm -rf lib node_modules spec src
USER $app_user_uid:$app_user_gid
EXPOSE $app_port
HEALTHCHECK --interval=1m --timeout=5s --start-period=20s --retries=5 \
  CMD curl -f http://localhost:$APP_PORT/ || exit 1
# Simple init for container
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/sh", "-c", "bin/pet-tracker"]
############### app stage end ###############
