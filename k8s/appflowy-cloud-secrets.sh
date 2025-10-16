#!/bin/bash

# Generate secure passwords
kubectl create secret generic appflowy-cloud-secrets \
--namespace=appflowy \
--from-literal=postgres-user=appflowy_user \
--from-literal=postgres-password=$(openssl rand -base64 32) \
--from-literal=minio-access-key=appflowy-$(openssl rand -hex 16) \
--from-literal=minio-secret-key=$(openssl rand -base64 32) \
--from-literal=gotrue-jwt-secret=$(openssl rand -base64 64) \
--from-literal=gotrue-admin-email=admin@triggeriq.eu \
--from-literal=gotrue-admin-password=$(openssl rand -base64 16) \
--dry-run=client -o yaml > 02-secrets.yaml