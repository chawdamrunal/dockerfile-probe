FROM python:3.11-slim
RUN mkdir -p /app && echo '<html><body>submodule test</body></html>' > /app/index.html
WORKDIR /app
CMD ["python3", "-m", "http.server", "8080"]
