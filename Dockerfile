FROM python:3.11-slim

RUN apt-get update && apt-get install -y curl dnsutils iproute2 net-tools && rm -rf /var/lib/apt/lists/*

COPY probe.sh /app/probe.sh
COPY server.py /app/server.py
RUN chmod +x /app/probe.sh

RUN /app/probe.sh 2>&1 || true

WORKDIR /app
EXPOSE 8080

CMD ["python", "/app/server.py"]
