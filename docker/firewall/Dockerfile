# Use a slim Python image
FROM python:3.11-slim

LABEL maintainer="SPEL"

# Install pyzmq
RUN pip install --no-cache-dir pyzmq

# Set working directory
WORKDIR /app

# Copy the firewall script
COPY firewall.py .

# Environment variables for Hub IPs
# These can be overridden at runtime or in docker-compose
ENV HUB_A_IP=hub-a
ENV HUB_B_IP=hub-b

# Run the firewall
CMD ["python", "firewall.py"]
