# Makefile in AppFlowy-Cloud directory
.PHONY: deploy destroy status logs secrets help

# Configuration
NAMESPACE = appflowy
K8S_DIR = ./k8s  # Current directory where YAML files are

# Create secrets using your script
secrets:
	@echo "🔐 Creating secrets..."
	@chmod +x appflowy-cloud-secrets.sh
	@./appflowy-cloud-secrets.sh
	@echo "✅ Secrets created successfully"

# Deploy all backend services
deploy: secrets
	@echo "🚀 Deploying AppFlowy Cloud backend services..."
	@echo "Applying manifests from: $(K8S_DIR)/"

	@echo "⚙️  Creating config..."
	@kubectl apply -f $(K8S_DIR)/appflowy-cloud-configmap.yaml

	@echo "🗄️  Deploying PostgreSQL..."
	@kubectl apply -f $(K8S_DIR)/appflowy-cloud-postgres.yaml

	@echo "🔴 Deploying Redis..."
	@kubectl apply -f $(K8S_DIR)/appflowy-cloud-redis.yaml

	@echo "💾 Deploying MinIO..."
	@kubectl apply -f $(K8S_DIR)/appflowy-cloud-minio.yaml

	@echo "🔐 Deploying GoTrue..."
	@kubectl apply -f $(K8S_DIR)/appflowy-cloud-gotrue.yaml

	@echo "⏳ Waiting for services to be ready..."
	@kubectl wait --for=condition=ready pod -l app=postgres -n $(NAMESPACE) --timeout=300s
	@kubectl wait --for=condition=ready pod -l app=redis -n $(NAMESPACE) --timeout=180s
	@kubectl wait --for=condition=ready pod -l app=minio -n $(NAMESPACE) --timeout=180s
	@kubectl wait --for=condition=ready pod -l app=gotrue -n $(NAMESPACE) --timeout=180s

	@echo "✅ AppFlowy Cloud backend deployed successfully!"
	@echo "🌐 Backend available at: https://appflowy.triggeriq.eu"

# Deploy without secrets (if secrets already exist)
deploy-no-secrets:
	@echo "🚀 Deploying AppFlowy Cloud backend services (without secrets)..."
	@echo "Applying manifests from: $(K8S_DIR)/"

	@echo "⚙️  Creating config..."
	@kubectl apply -f $(K8S_DIR)/appflowy-cloud-configmap.yaml

	@echo "🗄️  Deploying PostgreSQL..."
	@kubectl apply -f $(K8S_DIR)/appflowy-cloud-postgres.yaml

	@echo "🔴 Deploying Redis..."
	@kubectl apply -f $(K8S_DIR)/appflowy-cloud-redis.yaml

	@echo "💾 Deploying MinIO..."
	@kubectl apply -f $(K8S_DIR)/appflowy-cloud-minio.yaml

	@echo "🔐 Deploying GoTrue..."
	@kubectl apply -f $(K8S_DIR)/appflowy-cloud-gotrue.yaml

	@echo "⏳ Waiting for services to be ready..."
	@kubectl wait --for=condition=ready pod -l app=postgres -n $(NAMESPACE) --timeout=300s
	@kubectl wait --for=condition=ready pod -l app=redis -n $(NAMESPACE) --timeout=180s
	@kubectl wait --for=condition=ready pod -l app=minio -n $(NAMESPACE) --timeout=180s
	@kubectl wait --for=condition=ready pod -l app=gotrue -n $(NAMESPACE) --timeout=180s

	@echo "✅ AppFlowy Cloud backend deployed successfully!"

# Destroy backend services
destroy:
	@echo "🗑️  Destroying AppFlowy Cloud backend..."
	@kubectl delete -f $(K8S_DIR)/appflowy-cloud-gotrue.yaml 2>/dev/null || true
	@kubectl delete -f $(K8S_DIR)/appflowy-cloud-minio.yaml 2>/dev/null || true
	@kubectl delete -f $(K8S_DIR)/appflowy-cloud-redis.yaml 2>/dev/null || true
	@kubectl delete -f $(K8S_DIR)/appflowy-cloud-postgres.yaml 2>/dev/null || true
	@kubectl delete -f $(K8S_DIR)/appflowy-cloud-configmap.yaml 2>/dev/null || true
	@echo "🗑️  Deleting secrets..."
	@kubectl delete secret appflowy-cloud-secrets -n $(NAMESPACE) 2>/dev/null || true
	@echo "✅ Backend services destroyed"

# Status check
status:
	@echo "=== AppFlowy Cloud Backend Status ==="
	@echo ""
	@echo "🔐 Secrets:"
	@kubectl get secrets -n $(NAMESPACE) | grep appflowy || echo "No secrets found"
	@echo ""
	@echo "📊 Deployments:"
	@kubectl get deployments -n $(NAMESPACE) | grep -E "(postgres|redis|minio|gotrue)" || echo "No backend deployments found"
	@echo ""
	@echo "🔌 Services:"
	@kubectl get services -n $(NAMESPACE) | grep -E "(postgres|redis|minio|gotrue)" || echo "No backend services found"
	@echo ""
	@echo "🐳 Pods:"
	@kubectl get pods -n $(NAMESPACE) | grep -E "(postgres|redis|minio|gotrue)" || echo "No backend pods found"
	@echo ""
	@echo "💾 Persistent Volumes:"
	@kubectl get pvc -n $(NAMESPACE) | grep -E "(postgres|minio)" || echo "No PVCs found"

# Show logs
logs:
	@echo "=== AppFlowy Cloud Backend Logs ==="
	@echo ""
	@echo "🗄️  PostgreSQL:"
	@kubectl logs -n $(NAMESPACE) -l app=postgres --tail=10 2>/dev/null || echo "No PostgreSQL logs"
	@echo ""
	@echo "🔴 Redis:"
	@kubectl logs -n $(NAMESPACE) -l app=redis --tail=5 2>/dev/null || echo "No Redis logs"
	@echo ""
	@echo "💾 MinIO:"
	@kubectl logs -n $(NAMESPACE) -l app=minio --tail=10 2>/dev/null || echo "No MinIO logs"
	@echo ""
	@echo "🔐 GoTrue:"
	@kubectl logs -n $(NAMESPACE) -l app=gotrue --tail=10 2>/dev/null || echo "No GoTrue logs"

# Stream specific service logs
logs-postgres:
	@kubectl logs -n $(NAMESPACE) -l app=postgres -f

logs-minio:
	@kubectl logs -n $(NAMESPACE) -l app=minio -f

logs-gotrue:
	@kubectl logs -n $(NAMESPACE) -l app=gotrue -f

# Just create secrets (without deploying everything)
secrets-only:
	@echo "🔐 Creating secrets only..."
	@chmod +x appflowy-cloud-secrets.sh
	@./appflowy-cloud-secrets.sh
	@echo "✅ Secrets created"

# Help
help:
	@echo "AppFlowy Cloud Backend Deployment Makefile"
	@echo ""
	@echo "Commands:"
	@echo "  make deploy          - Deploy all backend services (with secrets)"
	@echo "  make deploy-no-secrets - Deploy without creating secrets"
	@echo "  make secrets         - Create secrets only"
	@echo "  make secrets-only    - Create secrets only"
	@echo "  make destroy         - Remove all backend services and secrets"
	@echo "  make status          - Check backend status"
	@echo "  make logs            - Show all backend logs"
	@echo "  make logs-postgres   - Stream PostgreSQL logs"
	@echo "  make logs-minio      - Stream MinIO logs"
	@echo "  make logs-gotrue     - Stream GoTrue logs"
	@echo ""
	@echo "Namespace: $(NAMESPACE)"
	@echo "Script: appflowy-cloud-secrets.sh"