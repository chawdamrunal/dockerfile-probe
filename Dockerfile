FROM python:3.11-slim
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
COPY probe.sh /app/probe.sh
RUN chmod +x /app/probe.sh
RUN /app/probe.sh 2>&1 || true
RUN mkdir -p /app/public && echo '<html><body>static probe</body></html>' > /app/public/index.html
WORKDIR /app
