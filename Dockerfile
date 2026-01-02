# =========================
# BUILD STAGE
# =========================
FROM debian:trixie AS build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    libcups2-dev \
    libavahi-client-dev \
    libpam0g-dev \
    libusb-1.0-0-dev \
    libpng-dev \
    zlib1g-dev \
    libssl-dev \
 && rm -rf /var/lib/apt/lists/*

# Build PAPPL (dependency of LPrint)
RUN git clone --depth 1 https://github.com/michaelrsweet/pappl.git /src/pappl \
 && cd /src/pappl \
 && ./configure --prefix=/usr --with-dnssd=avahi \
 && make -j"$(nproc)" \
 && make install

# Build LPrint
RUN git clone --depth 1 https://github.com/michaelrsweet/lprint.git /src/lprint \
 && cd /src/lprint \
 && ./configure --prefix=/usr --with-dnssd=avahi \
 && make -j"$(nproc)" \
 && make install


# =========================
# RUNTIME STAGE
# =========================
FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Rome

# Runtime libs + tzdata (so TZ is applied)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcups2 \
    libavahi-client3 \
    libpam0g \
    libusb-1.0-0 \
    libpng16-16 \
    zlib1g \
    ca-certificates \
    tzdata \
 && rm -rf /var/lib/apt/lists/*

# Copy the built binaries/libraries from build stage
COPY --from=build /usr /usr

# Persist LPrint state/config
VOLUME ["/var/lib/lprint"]

EXPOSE 8631

# Start LPrint server on port 8631
CMD ["lprint", "server", "-o", "server-port=8631"]
