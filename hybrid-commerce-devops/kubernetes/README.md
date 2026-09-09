# Kubernetes Deployment Guide - Hybrid Commerce

## Overview
This directory contains Kubernetes manifests to deploy the Hybrid Commerce application to a Kubernetes cluster.

## Architecture
- **Namespace**: hybrid-commerce
- **Backend**: FastAPI application (Deployment + Service)
- **Frontend**: React/static files (Deployment + Service)
- **Database**: PostgreSQL 16 with persistent storage (StatefulSet + PVC)
- **Cache**: Redis 7 (Deployment + Service)
- **Ingress**: NGINX Ingress Controller for external access

## Prerequisites
1. Running Kubernetes cluster (k3s, minikube, or cloud-managed)
2. NGINX Ingress Controller installed
3. StorageClass available for PVC (or use hostPath for dev)
4. kubectl configured to access the cluster

## Deployment Steps

### 1. Create Namespace
kubectl apply -f namespace.yaml

### 2. Create Secrets
Create a secret with SECRET_KEY and POSTGRES_PASSWORD:
kubectl create secret generic hybrid-commerce-secret \
  --from-literal=SECRET_KEY=your-secret-key-here \
  --from-literal=POSTGRES_PASSWORD=your-password-here \
  -n hybrid-commerce

Or use the example file:
kubectl apply -f secret.yaml.example  # After editing with real values

### 3. Create ConfigMaps
kubectl apply -f configmap.yaml

### 4. Deploy Database (PostgreSQL)
kubectl apply -f database/pvc.yaml
kubectl apply -f database/deployment.yaml

### 5. Deploy Redis
kubectl apply -f redis/deployment.yaml

### 6. Deploy Backend API
kubectl apply -f backend/deployment.yaml

### 7. Deploy Frontend (optional, in progress)
kubectl apply -f frontend/deployment.yaml

### 8. Deploy Ingress
kubectl apply -f ingress.yaml

## Verification
kubectl get all -n hybrid-commerce
kubectl logs -f deployment/backend -n hybrid-commerce
kubectl get ingress -n hybrid-commerce

## Scaling
kubectl scale deployment backend --replicas=3 -n hybrid-commerce
kubectl scale deployment frontend --replicas=3 -n hybrid-commerce

## Cleanup
kubectl delete namespace hybrid-commerce
