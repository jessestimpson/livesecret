# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian instead of
# Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags
#
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bullseye-20220801-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: hexpm/elixir:1.14.0-erlang-25.0.3-debian-bullseye-20210902-slim
#
ARG ELIXIR_VERSION=1.19.4
ARG OTP_VERSION=28.3
ARG UBUNTU_VERSION=jammy-20260217
ARG FDB_VERSION=7.3.69
ARG ARCH=aarch64

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-ubuntu-${UBUNTU_VERSION}"
ARG RUNNER_IMAGE="ubuntu:${UBUNTU_VERSION}"

FROM ${BUILDER_IMAGE} as builder
ARG FDB_VERSION
ARG ARCH

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git wget \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /root

RUN wget https://github.com/apple/foundationdb/releases/download/${FDB_VERSION}/foundationdb-clients_${FDB_VERSION}-1_${ARCH}.deb && \
    wget https://github.com/apple/foundationdb/releases/download/${FDB_VERSION}/foundationdb-server_${FDB_VERSION}-1_${ARCH}.deb

RUN dpkg -i foundationdb-clients_${FDB_VERSION}-1_${ARCH}.deb

# prepare build dir
RUN useradd -u 1001 -ms /bin/bash app
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv

COPY lib lib

COPY assets assets

# compile assets
RUN mix assets.deploy

# Compile the release
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

RUN chown -R app: /app

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}
ARG FDB_VERSION
ARG ARCH

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

COPY --from=builder --chown=nobody:root /root/foundationdb-clients_${FDB_VERSION}-1_${ARCH}.deb /root
COPY --from=builder --chown=nobody:root /root/foundationdb-server_${FDB_VERSION}-1_${ARCH}.deb /root

RUN dpkg -i /root/foundationdb-clients_${FDB_VERSION}-1_${ARCH}.deb && \
    dpkg -i /root/foundationdb-server_${FDB_VERSION}-1_${ARCH}.deb

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

RUN useradd -u 1001 -ms /bin/bash app && \
    mkdir /app && chown -R app: /app

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Required for ex_fdbmonitor
ENV SHELL /bin/bash

RUN mkdir /data
RUN chown -R app: /data
VOLUME /data

USER app
WORKDIR /app

# set runner ENV
ENV MIX_ENV="prod"
ENV FDBMONITOR_PATH="/usr/lib/foundationdb/fdbmonitor"
ENV FDBCLI_PATH="/usr/bin/fdbcli"
ENV FDBSERVER_PATH="/usr/sbin/fdbserver"
ENV FDBDR_PATH="/usr/bin/fdbdr"
ENV BACKUP_AGENT_PATH="/usr/lib/foundationdb/backup_agent/backup_agent"
ENV DR_AGENT_PATH="/usr/bin/dr_agent"

# Only copy the final release from the build stage
COPY --from=builder --chown=app /app/_build/${MIX_ENV}/rel/livesecret .

EXPOSE ${PORT}

CMD ["/app/bin/server"]

# Example run command:
# docker run -it \
#     -p 8000:80 \
#     -e DATABASE_PATH=/data/livesecret \
#     -e PHX_HOST=livesecret.local \
#     -e PORT=80 \
#     -e SECRET_KEY_BASE="$(mix phx.gen.secret)" \
#     -e BEHIND_PROXY=false \
#     -e REMOTE_IP_HEADER=x-real-ip \
#     c921c88540f5e3bbf4f4849bc96968a0b0d824baff4d8e4050ab08925aa8b3c4
