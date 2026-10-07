#!/usr/bin/env bash
# The fix: expose the database under the name checkout expects ("db").
set -euo pipefail
source "$(dirname "$0")/_common.sh"
k -n shop apply -f - <<Y
apiVersion: v1
kind: Service
metadata: {name: db, namespace: shop}
spec:
  selector: {app: orders-db}
  ports: [{port: 5432, targetPort: 5432}]
Y
# CoreDNS caches the earlier NXDOMAIN for up to 30s; wait until db:5432 is reachable so a restart succeeds first time.
echo "Waiting for db:5432 to be reachable..."
k -n shop run dns-probe --rm -i --restart=Never --image=busybox:1.36 --command -- \
  sh -c 'for i in $(seq 1 30); do nc -z -w 1 db.shop.svc.cluster.local 5432 && exit 0; sleep 2; done; exit 1' >/dev/null 2>&1
echo "Service 'db' is reachable. Next: restart checkout."
