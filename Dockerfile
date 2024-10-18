FROM --platform=linux/amd64 ubuntu as build

# Setting bash as our shell, and enabling pipefail option
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Some ENV variables
ENV PATH="/usr/lib/go/bin:/mattermost/server/bin:${PATH}"

# Build Arguments
ARG PUID=2000
ARG PGID=2000

# Install needed packages and indirect dependencies
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  ca-certificates \
  curl \
  media-types \
  mailcap \
  unrtf \
  wv \
  poppler-utils \
  tidy \
  tzdata \
  make \
  build-essential \
  gcc \
  golang \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
  apt-get install -y nodejs && \
  rm -rf /var/lib/apt/lists/*

# Build client
RUN mkdir /mattermost
COPY . /mattermost
WORKDIR /mattermost/webapp
RUN make dist

# Build server
WORKDIR /mattermost/server
RUN make client \
    && make build-linux

# Healthcheck to make sure container is ready
HEALTHCHECK --interval=30s --timeout=10s \
  CMD curl -f http://localhost:8065/api/v4/system/ping || exit 1

# Required ports
EXPOSE 8065 8067 8074 8075

# Declare volumes for mount point directories
VOLUME ["/mattermost/server/data", "/mattermost/server/logs", "/mattermost/server/config", "/mattermost/server/plugins", "/mattermost/server/client/plugins"]

# run the client and server
CMD ["mattermost"]
