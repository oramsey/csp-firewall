# Use Ubuntu base for compiling C code with libzmq
FROM ubuntu:24.04

LABEL maintainer="SPEL"

# Install dependencies for C and ZeroMQ
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    gcc libc-dev libzmq3-dev make && \
    apt autoremove -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the modular C firewall files
COPY *.c *.h ./

# Environment variables for Hub IPs
ENV HUB_A_IP=ground-node-a
ENV HUB_B_IP=sat-node-b

# We compile it during startup if we are using volumes to live-edit the C files
# Otherwise, we could compile it here. Since the user wants incremental live updates, 
# we'll compile and run in the command.
CMD gcc -o firewall router.c firewall_core.c policy_engine.c parser.c enforcement.c -lzmq && ./firewall
