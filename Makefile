# Makefile in AppFlowy-Cloud directory
.PHONY: deploy destroy status logs generate-manifests clean help

# Configuration
NAMESPACE = appflowy
DOMAIN = appflowy.triggeriq.eu
K8S_DIR = k8s-manifests

# Generate Kubernetes manifests
generate-manifests:
	@echo "Generating Kubernetes manifests for AppFlowy Cloud..."
	@mkdir -p $(K8S_DIR)
	
	# Generate secrets
	@cat > $(K8S_DIR)/01-secrets.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: appflowy-cloud-secrets
  namespace: $(NAMESPACE)
type: Opaque
data:
  postgres-user: $$(echo -n "appflowy_user" | base64)
  postgres-password: $$(openssl rand -base64 32 | tr -d '\n' | base64)
  minio-access-key: $$(echo -n "appflowy-$$(openssl rand -hex 16)" | base64)
  minio-secret-key: $$(openssl rand -base64 32 | tr -d '\n' | base64)
  gotrue-jwt-secret: $$(openssl rand -base64 64 | tr -d '\n' | base64)
  gotrue-admin-email: $$(echo -n "admin@$(DOMAIN)" | base64)
  gotrue-admin-password: $$(openssl rand -base64 16 | tr -d '\n' | base64)
EOF

	# Generate configmap
	@cat > $(K8S_DIR)/02-configmap.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: appflowy-cloud-config
  namespace: $(NAMESPACE)
data:
  DOMAIN: "$(DOMAIN)"
  APPFLOWY_BASE_URL: "https://$(DOMAIN)"
  APPFLOWY_WEBSOCKET_BASE_URL: "wss://$(DOMAIN)/ws/v2"
  APPFLOWY_WEB_URL: "https://$(DOMAIN)"
  APPFLOWY_GOTRUE_URL: "https://$(DOMAIN)/gotrue"
  POSTGRES_HOST: "postgres"
  POSTGRES_PORT: "5432"
  POSTGRES_DB: "appflowy"
  REDIS_HOST: "redis"
  REDIS_PORT: "6379"
  MINIO_HOST: "minio"
  MINIO_PORT: "9000"
  APPFLOWY_ACCESS_CONTROL: "true"
  APPFLOWY_S3_USE_MINIO: "true"
  APPFLOWY_S3_CREATE_BUCKET: "true"
  APPFLOWY_S3_BUCKET: "appflowy"
  GOTRUE_MAILER_AUTOCONFIRM: "true"
  GOTRUE_DISABLE_SIGNUP: "false"
  RUST_LOG: "info"
EOF

	@echo "Basic manifests generated in $(K8S_DIR)/"
	@echo "Now generate the service manifests using the script:"
	@echo "./scripts/generate-services.sh $(NAMESPACE) $(K8S_DIR)"

# Deploy backend services
deploy: generate-manifests
	@echo "Deploying AppFlowy Cloud backend services..."
	@for file in $(K8S_DIR)/*.yaml; do \
		echo "Applying $$file..."; \
		kubectl apply -f $$file; \
	done
	@echo "Waiting for services to be ready..."
	@kubectl wait --for=condition=ready pod -l appflowy-backend=true -n $(NAMESPACE) --timeout=600s
	@echo "AppFlowy Cloud backend deployed!"
	@echo "Services available at: https://$(DOMAIN)"

# Destroy backend services
destroy:
	@echo "Destroying AppFlowy Cloud backend..."
	@if [ -d "$(K8S_DIR)" ]; then \
		for file in $(K8S_DIR)/*.yaml; do \
			echo "Deleting $$file..."; \
			kubectl delete -f $$file 2>/dev/null || true; \
		done; \
	fi
	@kubectl delete pvc -l appflowy-backend=true -n $(NAMESPACE) 2>/dev/null || true
	@echo "Backend services destroyed"

# Status check
status:
	@echo "=== AppFlowy Cloud Backend Status ==="
	@echo "Namespace: $(NAMESPACE)"
	@echo ""
	@echo "=== Deployments ==="
	kubectl get deployments -n $(NAMESPACE) -l appflowy-backend=true
	@echo ""
	@echo "=== Services ==="
	kubectl get services -n $(NAMESPACE) -l appflowy-backend=true
	@echo ""
	@echo "=== Pods ==="
	kubectl get pods -n $(NAMESPACE) -l appflowy-backend=true
	@echo ""
	@echo "=== Persistent Volumes ==="
	kubectl get pvc -n $(NAMESPACE) -l appflowy-backend=true

# Show logs
logs:
	@echo "=== Backend Logs ==="
	@kubectl logs -n $(NAMESPACE) -l appflowy-backend=true --tail=20

# Clean generated manifests
clean:
	rm -rf $(K8S_DIR)
	@echo "Cleaned generated manifests"

# Help
help:
	@echo "AppFlowy Cloud (Backend) Makefile"
	@echo ""
	@echo "Commands:"
	@echo "  make generate-manifests - Generate Kubernetes manifests"
	@echo "  make deploy            - Deploy backend services"
	@echo "  make destroy           - Remove backend services"
	@echo "  make status            - Check backend status"
	@echo "  make logs              - Show backend logs"
	@echo "  make clean             - Clean generated files"
	@echo ""
	@echo "Configuration:"
	@echo "  DOMAIN: $(DOMAIN)"
	@echo "  NAMESPACE: $(NAMESPACE)"
	@echo "  MANIFESTS: $(K8S_DIR)/"