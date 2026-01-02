# =========================
# BUILD STAGE
# =========================
FROM debian:bookworm AS build

ARG DEBIAN_FRONTEND=noninteractive

# Toolchain + deps per build (CUPS dev è 2.4.x su bookworm)
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

# ---- PAPPL: pin a versione compatibile con CUPS 2.4.x ----
# Se questo tag non esiste nel tuo build, vedi nota sotto per cambiare tag.
ARG PAPPL_REF=v1.3.1
RUN git clone https://github.com/michaelrsweet/pappl.git /src/pappl \
 && cd /src/pappl \
 && git checkout "${PAPPL_REF}" \
 && ./configure --prefix=/usr \
 && make -j"$(nproc)" \
 && make install

# ---- LPrint: pin a versione stabile (anche qui puoi cambiare se serve) ----
ARG LPRINT_REF=v1.3.1
RUN git clone https://github.com/michaelrsweet/lprint.git /src/lprint \
 && cd /src/lprint \
 && git checkout "${LPRINT_REF}" \
 && ./configure --prefix=/usr \
 && make -j"$(nproc)" \
 && make install


# =========================
# RUNTIME STAGE
# =========================
FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcups2 \
    libavahi-client3 \
    libpam0g \
    libusb-1.0-0 \
    libpng16-16 \
    zlib1g \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Copia i binari/librerie installati nello stage build
COPY --from=build /usr /usr

# Stato/config persistenti
VOLUME ["/var/lib/lprint"]

# Web UI + IPP
EXPOSE 8631

ENV TZ=Europe/Rome

# Avvio server LPrint
CMD ["sh", "-lc", "lprint server -o server-port=8631 -o server-name=lprint"]
