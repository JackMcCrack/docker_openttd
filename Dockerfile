# BUILD ENVIRONMENT
FROM debian:stable-slim AS ottd_jre_build

#ARG OPENTTD_VERSION="1.10.1"
ARG OPENTTD_JGR_RELEASE="0.42.2"
ARG OPENGFX_VERSION="0.6.1"

# Get things ready
RUN mkdir -p /config \
    && mkdir /tmp/unpack

# Install build dependencies
RUN apt-get update && \
    apt-get install -y \
    unzip \
    wget \
    xz-utils 

# download and unpack the release
WORKDIR /tmp/unpack
RUN wget -O openttdjre.tar.xz https://github.com/JGRennison/OpenTTD-patches/releases/download/jgrpp-${OPENTTD_JGR_RELEASE}/openttd-jgrpp-${OPENTTD_JGR_RELEASE}-linux-generic-amd64.tar.xz \
    && tar -xf openttdjre.tar.xz \
    && mv openttd-jgrpp-${OPENTTD_JGR_RELEASE}-linux-generic-amd64 /app

# Add the latest graphics files
## Install OpenGFX
RUN mkdir -p /app/data/baseset/ \
    && cd /app/data/baseset/ \
    && wget -q https://cdn.openttd.org/opengfx-releases/${OPENGFX_VERSION}/opengfx-${OPENGFX_VERSION}-all.zip \
    && unzip opengfx-${OPENGFX_VERSION}-all.zip \
    && tar -xf opengfx-${OPENGFX_VERSION}.tar \
    && rm -rf opengfx-*.tar opengfx-*.zip

# END BUILD ENVIRONMENT
# DEPLOY ENVIRONMENT

FROM debian:stable-slim
ARG OPENTTD_JGR_RELEASE="JGE_0.42.2"
LABEL org.label-schema.name="OpenTTD" \
      org.label-schema.description="OpenTTD JGR, designed for server use, with some extra helping treats." \
      org.label-schema.url="https://github.com/JackMcCrack/docker_openttd" \
      org.label-schema.vcs-url="https://github.com/JackMcCrack/docker_openttd" \
      org.label-schema.vendor="JackMcCrack" \
      org.label-schema.version=$OPENTTD_VERSION \
      org.label-schema.schema-version="1.0"
MAINTAINER Jack <jackmccrack@entropia.de>

# Setup the environment and install runtime dependencies
RUN mkdir -p /config \
    && useradd -d /config -u 911 -s /bin/false openttd \
    && apt-get update \
    && apt-get install -y \
    libc6 \
    zlib1g \
    liblzma5 \
    liblzo2-2

WORKDIR /config

# Copy the game data from the build container
COPY --from=ottd_jre_build /app /app

# Add the entrypoint
ADD entrypoint.sh /usr/local/bin/entrypoint

# Expose the volume
RUN chown -R openttd:openttd /config /app
VOLUME /config

# Expose the gameplay port
EXPOSE 3979/tcp
EXPOSE 3979/udp

# Expose the admin port
EXPOSE 3977/tcp

# Finally, let's run OpenTTD!
USER openttd
CMD /usr/local/bin/entrypoint
