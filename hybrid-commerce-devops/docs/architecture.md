# Architecture Diagram

## High-Level Architecture

```
                         USERS (Web Browser / Mobile)
                              |
                              | HTTPS
                              v
                    ┌─────────────────────┐
                    │   AWS LOAD BALANCER │
                    │   (Application LB)  │
                    │   Port: 80/443      │
                    └──────────┬──────────┘
                               |
                    ┌──────────▼──────────┐
                    │  KUBERNETES INGRESS │
                    │  (NGINX Ingress)    │
                    └──────────┬──────────┘
                               |
                    ┌──────────┴───────────┐
                    │                      │
              ┌─────▼─────┐         ┌─────▼─────┐
              │  FRONTEND  │         │  BACKEND   │
              │  (React)   │         │  (FastAPI) │
              │  Pod x 2   │         │  Pod x 2   │
              │  Port 80   │         │  Port 8000 │
              └─────┬──────┘         └─────┬──────┘
                    │                      │
                    │   ┌──────────────────┼──────────────────┐
                    │   │                  │                  │
              ┌─────▼──▼──▼──┐   ┌────────▼────────┐  ┌─────▼─────┐
              │   POSTGRESQL  │   │     REDIS       │  │  S3 BUCKET │
              │   (Stateful   │   │   (Cache/Sess)  │  │ (Images)   │
              │    Set x 1)   │   │   Pod x 1       │  │            │
              │   Port 5432   │   │   Port 6379     │  │            │
              │   PVC 5GB     │   │                 │  │            │
              └───────────────┘   └─────────────────┘  └────────────┘
                    │
              ┌─────▼──────────────────────────────┐
              │          MONITORING STACK           │
              │  ┌──────────┐  ┌────────────────┐  │
              │  │PROMETHEUS│  │    GRAFANA     │  │
              │  │  Pod x 1  │  │    Pod x 1     │  │
              │  └──────────┘  └────────────────┘  │
              │  ┌──────────┐  ┌────────────────┐  │
              │  │ ALERTMAN │  │  Kube State    │  │
              │  │  Pod x 1  │  │  Metrics Pod   │  │
              │  └──────────┘  └────────────────┘  │
              └─────────────────────────────────────┘
```

## Component Details

### AWS Infrastructure (Terraform)
```
VPC (10.0.0.0/16)
├── Public Subnet (10.0.1.0/24) [AZ-a]
│   ├── Internet Gateway
│   ├── Route Table (0.0.0.0/0 → IGW)
│   ├── Application Load Balancer (ALB)
│   │   └── Security Group: alb-sg (80, 443 from 0.0.0.0/0)
│   └── EC2 Instance (t2.micro)
│       ├── Public IP
│       ├── Ubuntu 24.04 LTS
│       ├── EBS gp3 8GB (root)
│       ├── EBS gp3 8GB (data, /dev/sdf)
│       ├── IAM Role: hybrid-commerce-ec2-role
│       │   └── Policy: AmazonS3ReadOnlyAccess
│       └── Security Group: ec2-sg (22, 8000 from public subnet)
│
└── Private Subnet (10.0.10.0/24) [AZ-a]
    ├── Route Table (no internet route)
    └── (Reserved for future expansion)
```

### Kubernetes Cluster (Self-Managed on EC2)
```
Namespace: hybrid-commerce

Deployments:
├── backend (1 replica)
│   ├── Image: hybrid-commerce-backend:latest
│   ├── Port: 8000
│   ├── Liveness/Readiness: /health
│   ├── Resources: 256Mi/512Mi RAM, 100m/500m CPU
│   └── Env: ConfigMap + Secret
│
├── frontend (1 replica)
│   ├── Image: hybrid-commerce-frontend:latest
│   ├── Port: 80
│   ├── Liveness/Readiness: /
│   └── Resources: 128Mi/256Mi RAM, 50m/200m CPU
│
├── postgres (1 replica, StatefulSet)
│   ├── Image: postgres:16-alpine
│   ├── Port: 5432
│   ├── PVC: postgres-pvc (5GB)
│   ├── Secret: POSTGRES_PASSWORD
│   └── Resources: 128Mi/512Mi RAM, 100m/500m CPU
│
├── redis (1 replica)
│   ├── Image: redis:7-alpine
│   ├── Port: 6379
│   ├── EmptyDir volume
│   └── Resources: 64Mi/256Mi RAM, 50m/200m CPU
│
└── monitoring (separate namespace)
    ├── prometheus (1 replica)
    ├── grafana (1 replica)
    ├── alertmanager (1 replica)
    └── kube-state-metrics (1 replica)

Services:
├── backend-service (ClusterIP:8000)
├── frontend-service (ClusterIP:80)
├── postgres-service (ClusterIP:5432)
└── redis-service (ClusterIP:6379)

Ingress:
└── hybrid-commerce-ingress (NGINX)
    ├── /api → backend-service:8000
    └── / → frontend-service:80
```

---

## Data Flow Diagrams

### User Registration Flow
```
User → Frontend Register Form
     → POST /api/auth/register
     → Backend validates input (Pydantic)
     → Backend hashes password (bcrypt)
     → Backend creates user in PostgreSQL
     → Backend returns user object (no password)
     → Frontend stores auth state
```

### Product Search Flow
```
User → Frontend Search Bar
     → GET /api/products?search=laptop&min_price=500
     → Backend queries PostgreSQL with filters
     → Backend returns filtered products
     → Frontend displays product cards
```

### Order Placement Flow
```
User Cart → POST /api/orders
         → Backend validates cart has items
         → Backend creates Order (status=PENDING)
         → Backend creates OrderItems for each cart item
         → Backend decrements product stock
         → Backend clears user's cart
         → Backend returns order with items
         → Admin can update status: PENDING → CONFIRMED → ...
```

### Monitoring Data Flow
```
App (FastAPI) → prometheus-fastapi-instrumentator → /metrics endpoint
                                                    →
                                            Prometheus scrapes /metrics
                                                    →
                                      Prometheus Alert Rules evaluate
                                                    →
                                       Alertmanager → Email/Slack/PagerDuty
                                                    →
                                        Grafana queries Prometheus
                                                    →
                                       Grafana Dashboards display metrics
```

---

## Infrastructure Cost Breakdown

### 5-Day Demo Cost Estimate

| Resource | Quantity | Unit Cost | 5-Day Cost | Free Tier? |
|----------|----------|-----------|------------|------------|
| EC2 t2.micro | 1 | $0.0104/hr | $12.48 | 750 hrs/month FREE |
| EBS gp3 8GB | 2 | $0.08/GB-mo | $0.64 | First 30GB FREE |
| S3 Standard | <1GB | $0.023/GB-mo | $0.00 | First 5GB FREE |
| ALB | 1 | $0.0225/hr + LCU | ~$4.00 | NOT COVERED |
| Public IP | 1 | $0.00 | $0.00 | Included with EC2 |
| **TOTAL** | | | **~$4-5** | |

**NOTE**: EC2 cost is waived by Free Tier (750 hrs/month of t2.micro). EBS is within the 30GB free tier. The ALB is the only charge.

---

## Database Schema Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         USERS                                   │
├──────────────┬──────────────┬──────────────┬───────────────────┤
│ id (UUID PK) │ email (UNIQUE)│ password_hash│ is_admin (BOOL)   │
│              │              │              │ created_at        │
└──────────────┴──────────────┴──────────────┴───────────────────┘
                                │
                                │ 1:N
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                          CARTS                                  │
├──────────────┬───────────────────────────────────────────────────┤
│ id (UUID PK) │ user_id (FK → users.id) UNIQUE                    │
│              │ created_at                                        │
└──────────────┴───────────────────────────────────────────────────┘
                                │
                                │ 1:N
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                       CART ITEMS                                 │
├──────────────┬───────────────────────────────────────────────────┤
│ id (UUID PK) │ cart_id (FK → carts.id)                          │
│              │ product_id (FK → products.id)                     │
│              │ quantity                                          │
└──────────────┴───────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                       PRODUCTS                                  │
├───────────────────┬─────────────────────────────────────────────┤
│ id (UUID PK)      │ name, description, price (DECIMAL)           │
│                   │ stock_quantity, image_url                    │
│                   │ created_at, CHECK(price >= 0)                │
└───────────────────┴─────────────────────────────────────────────┘
                                │
                                │ 1:N
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                       ORDER ITEMS                               │
├──────────────┬───────────────────────────────────────────────────┤
│ id (UUID PK) │ order_id (FK → orders.id)                         │
│              │ product_id (FK → products.id)                     │
│              │ quantity, unit_price                              │
└──────────────┴───────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         ORDERS                                  │
├───────────────────┬─────────────────────────────────────────────┤
│ id (UUID PK)      │ user_id (FK → users.id)                      │
│                   │ status (PENDING|CONFIRMED|PROCESSING|        │
│                   │   OUT_FOR_DELIVERY|DELIVERED|CANCELLED)      │
│                   │ total_amount (DECIMAL)                       │
│                   │ shipping_address (JSONB)                     │
│                   │ created_at, updated_at                       │
└───────────────────┴─────────────────────────────────────────────┘
```

---

## CI/CD Pipeline Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    GITHUB ACTIONS PIPELINE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [Push to main]                                                  │
│       │                                                          │
│       ▼                                                          │
│  ┌───────────┐                                                   │
│  │  LINT     │ ✅ flake8, black formatting check                │
│  └─────┬─────┘                                                   │
│        │                                                          │
│        ▼                                                          │
│  ┌───────────┐                                                   │
│  │   TEST    │ ✅ pytest (when test suite exists)              │
│  └─────┬─────┘                                                   │
│        │                                                          │
│        ▼                                                          │
│  ┌───────────┐                                                   │
│  │  SECURITY │ ✅ pip-audit, Trivy filesystem scan             │
│  └─────┬─────┘                                                   │
│        │                                                          │
│        ▼                                                          │
│  ┌───────────┐                                                   │
│  │   BUILD   │ ✅ Docker build + push to GHCR                 │
│  └─────┬─────┘                                                   │
│        │                                                          │
│        ▼                                                          │
│  ┌───────────┐                                                   │
│  │  DEPLOY   │ ✅ SSH to EC2 → pull code → restart service    │
│  └─────┬─────┘                                                   │
│        │                                                          │
│        ▼                                                          │
│  ┌───────────┐                                                   │
│  │ HEALTH    │ ✅ curl http://localhost:8000/health           │
│  └───────────┘                                                   │
│                                                                  │
│  On failure: Notify + optional rollback                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Security Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  LAYER 1: NETWORK                                                │
│  ├── AWS Security Groups (least privilege ingress/egress)       │
│  │   └── ALB SG: 80, 443 from 0.0.0.0/0                        │
│  │   └── EC2 SG: 22 (SSH), 8000 (app) from ALB subnet           │
│  ├── UFW Firewall on EC2 (deny incoming, allow specific ports)  │
│  └── VPC with public/private subnet separation                  │
│                                                                  │
│  LAYER 2: ACCESS CONTROL                                         │
│  ├── SSH key-only authentication (password disabled)             │
│  │   └── PermitRootLogin: no                                    │
│  │   └── PasswordAuthentication: no                             │
│  ├── IAM role for EC2 (no access keys on instance)              │
│  │   └── Policy: AmazonS3ReadOnlyAccess only                    │
│  └── JWT tokens for API authentication                          │
│      └── Expiration: 24 hours                                   │
│                                                                  │
│  LAYER 3: APPLICATION                                            │
│  ├── Input validation (Pydantic schemas)                        │
│  ├── Password hashing (bcrypt via passlib)                      │
│  ├── Parameterized queries (SQLAlchemy ORM prevents SQLi)       │
│  ├── CORS configuration (restrict in production)                │
│  └── Role-based authorization (user vs admin endpoints)         │
│                                                                  │
│  LAYER 4: CONTAINER                                              │
│  ├── Non-root user in Docker containers                         │
│  ├── Minimal base images (python:3.11-slim)                    │
│  ├── Image scanning (Trivy in CI/CD)                            │
│  └── Dependency scanning (pip-audit in CI/CD)                   │
│                                                                  │
│  LAYER 5: SECRETS                                                │
│  ├── .env files (gitignored)                                    │
│  ├── Kubernetes Secrets (base64 encoded)                        │
│  ├── No secrets in Git repository                               │
│  └── AWS Secrets Manager recommendation for production          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```
