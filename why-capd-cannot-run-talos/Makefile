KIND_IMAGE  ?= kindest/node:v1.34.0
TALOS_IMAGE ?= ghcr.io/siderolabs/talos:v1.13.10

.PHONY: check check-kind check-talos inspect

check: check-kind check-talos

check-kind:
	@./scripts/capd-checks.sh $(KIND_IMAGE)

check-talos:
	@./scripts/capd-checks.sh $(TALOS_IMAGE)

# Which of the binaries CAPD calls exist in each image at all.
inspect:
	@for img in $(KIND_IMAGE) $(TALOS_IMAGE); do \
	  echo "== $$img"; cid=$$(docker create $$img); \
	  found=$$(docker export $$cid | tar -tf - | grep -E '^(usr/)?(local/)?s?bin/(sh|bash|systemctl|crictl|kubeadm|cloud-init)$$'); \
	  if [ -n "$$found" ]; then echo "$$found" | sed 's/^/   /'; else echo "   (none of them)"; fi; \
	  docker rm $$cid >/dev/null; \
	done
