FROM python:3.11-slim
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
WORKDIR /app
CMD ["/app/entrypoint.sh"]
