FROM ubuntu:22.04
LABEL maintainer="SPEL"
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    gcc libc-dev libzmq3-dev make python3 python-is-python3 pkg-config git && \
    apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY libcsp-gs /app/libcsp
COPY docker/firewall/*.c docker/firewall/*.h /app/
# Build LibCSP and then compile firewall pointing directly to build headers
CMD cd /app/libcsp && rm -rf .lock-waf* build && \
    python3 ./waf configure --with-os=posix --enable-if-zmqhub && \
    python3 ./waf build && cd /app && \
    gcc -o firewall main.c firewall_core.c policy_engine.c parser.c enforcement.c iface_zmq.c routes.c \
    -I/app/libcsp/include -I/app/libcsp/build/include -L/app/libcsp/build -lcsp -lzmq -lpthread && \
    ./firewall
