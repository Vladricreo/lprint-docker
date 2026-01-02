# =========================
# BUILD STAGE
# =========================
FROM debian:bookworm AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates git build-essential autoconf automake libtool pkg-config \
  libcups2-dev libavahi-client-dev libpam0g-dev libusb-1.0-0-dev \
  libpng-dev zlib1g-dev libssl-dev \
  && rm -rf /var/lib/apt/lists/*

# ---- Build PAPPL (PINNED) ----
RUN git clone https://github.com/michaelrsweet/pappl.git /src/pappl \
 && cd /src/pappl \
 && git checkout v1.4.10 \
 && ./configure --prefix=/usr/local --with-dnssd=avahi \
 && make -j"$(nproc)" \
 && make install

# ---- Build LPrint (PINNED) ----
RUN git clone https://github.com/michaelrsweet/lprint.git /src/lprint \
 && cd /src/lprint \
 && git checkout v1.3.1 \
 && ./configure --prefix=/usr/local --with-dnssd=avahi \
 && make -j"$(nproc)" \
 && make install


# =========================
# RUNTIME STAGE
# =========================
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
  libcups2 libavahi-client3 libpam0g libusb-1.0-0 libpng16-16 zlib1g ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# <-- QUI sta la differenza: portiamo dentro pappl+lprint
COPY --from=build /usr/local/ /usr/local/

ENV TZ=Europe/Rome
VOLUME ["/var/lib/lprint"]
EXPOSE 8631

# Nota: lprint sarà in /usr/local/bin
CMD ["/usr/local/bin/lprint", "server", "-o", "server-port=8631"]
