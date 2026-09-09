# Hybrid Commerce Platform
## Cloud & DevOps Capstone Project

A full-stack e-commerce application demonstrating the complete Cloud & DevOps lifecycle.

---

## Project Overview

This capstone project implements a production-style web application combining:

1. **E-commerce** — Product listing, search, cart, orders
2. **Inventory Management** — Product and stock tracking
3. **Order Management** — Order placement, tracking, status updates
4. **Delivery Tracking** — Real-time order status
5. **Admin Dashboard** — Analytics, product CRUD, order management

The solution demonstrates the complete Cloud & DevOps lifecycle:
- Application development
- Containerization (Docker)
- Infrastructure as Code (Terraform)
- Configuration management (Ansible)
- CI/CD automation (GitHub Actions)
- Orchestration (Kubernetes)
- Monitoring & alerting (Prometheus + Grafana)
- Security hardening

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Frontend | React 18 + Vite + TypeScript | Single-page application |
| Backend | Python + FastAPI | REST API server |
| Database | PostgreSQL 16 (prod) / SQLite (dev) | Data persistence |
| Cache | Redis 7 | Session store, caching |
| Container | Docker + Docker Compose | Local development |
| Orchestration | Kubernetes (kubeadm) | Production deployment |
| IaC | Terraform | AWS infrastructure provisioning |
| Config Mgmt | Ansible | Server configuration |
| CI/CD | GitHub Actions | Build, test, deploy automation |
| Monitoring | Prometheus + Grafana | Metrics, dashboards, alerts |
| Cloud | AWS (ap-south-1) | Hosting infrastructure |
| Ingress | NGINX Ingress Controller | External access |

---

## Repository Structure

```
hybrid-commerce-devops/
│
├── app/
│   ├── backend/                    # FastAPI application
│   │   ├── Dockerfile              # Container build instructions
│   │   ├── requirements.txt        # Python dependencies
│   │   ├── .env.example           # Environment template
│   │   ├── app/
│   │   │   ├── main.py            # FastAPI app entry point
│   │   │   ├── config.py          # Settings via pydantic-settings
│   │   │   ├── database.py        # SQLAlchemy setup
│   │   │   ├── models/            # SQLAlchemy ORM models
│   │   │   ├── schemas/           # Pydantic schemas
│   │   │   ├── api/               # API route handlers
│   │   │   ├── services/          # Business logic
│   │   │   └── templates/         # Jinja2 HTML templates
│   │   └── tests/                 # Pytest tests
│   │
│   └── frontend/                   # React application (planned)
│       ├── Dockerfile
│       ├── package.json
│       └── src/
│
├── ansible/
│   ├── ansible.cfg                # Ansible configuration
│   ├── inventory/
│   │   └── hosts.yml              # Inventory file
│   ├── group_vars/
│   │   └── all.yml                # Global variables
│   ├── playbooks/
│   │   └── site.yml               # Main playbook
│   ├── roles/
│   │   ├── users/                 # User management
│   │   ├── packages/              # Package installation
│   │   ├── docker/                # Docker setup
│   │   ├── firewall/              # UFW configuration
│   │   ├── ssh_hardening/         # SSH security
│   │   └── app_deploy/            # App deployment
│   └── README.md
│
├── terraform/
│   ├── main.tf                    # Main infrastructure definition
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── providers.tf               # Provider configuration
│   ├── terraform.tfvars.example   # Variable example
│   ├── README.md
│   └── modules/                   # Reusable modules
│       ├── vpc/
│       ├── security/
│       ├── compute/
│       ├── database/
│       ├── storage/
│       └── alb/
│
├── docker/
│   ├── docker-compose.yml         # Full stack (dev)
│   └── docker-compose.override.yml # Local overrides
│
├── kubernetes/
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml.example
│   ├── ingress.yaml
│   ├── backend/
│   │   └── deployment.yaml
│   ├── frontend/
│   │   └── deployment.yaml
│   ├── database/
│   │   ├── deployment.yaml
│   │   └── pvc.yaml
│   ├── redis/
│   │   └── deployment.yaml
│   └── README.md
│
├── .github/
│   └── workflows/
│       └── ci-cd.yml              # CI/CD pipeline
│
├── monitoring/
│   ├── prometheus/
│   │   ├── prometheus.yml         # Prometheus config
│   │   └── alert_rules.yml        # Alert definitions
│   └── grafana/
│       └── dashboard.json         # Grafana dashboard
│
├── scripts/
│   ├── deploy.sh                  # Deployment script
│   ├── setup.sh                   # Initial server setup
│   ├── backup.sh                  # Backup script
│   ├── cleanup.sh                 # Cleanup script
│   ├── local-up.sh                # Local dev start
│   └── local-down.sh              # Local dev stop
│
├── docs/
│   ├── architecture.md
│   ├── deployment.md
│   ├── security.md
│   └── troubleshooting.md
│
├── .gitignore
├── .env.example
└── README.md
```

---

## Application Features

### Customer Features
- User registration and login (JWT authentication)
- Product listing with search and filtering
- Product detail view
- Shopping cart management
- Order placement
- Order history
- Order status tracking

### Admin Features
- Admin login
- Product CRUD (Create, Read, Update, Delete)
- Order management
- Update order status (state machine)
- Admin dashboard with statistics

### Order Status Flow
```
PENDING → CONFIRMED → PROCESSING → OUT_FOR_DELIVERY → DELIVERED
   ↓
CANCELLED
```

---

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/auth/register | Register new user |
| POST | /api/auth/login | Login (returns JWT) |
| POST | /api/auth/logout | Logout |
| GET | /api/auth/me | Get current user |

### Products
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/products | List products (search/filter) |
| GET | /api/products/{id} | Product details |
| POST | /api/products | Create product (admin) |
| PUT | /api/products/{id} | Update product (admin) |
| DELETE | /api/products/{id} | Delete product (admin) |

### Cart
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/cart | View cart |
| POST | /api/cart/items | Add item |
| PUT | /api/cart/items/{id} | Update item |
| DELETE | /api/cart/items/{id} | Remove item |

### Orders
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/orders | Place order |
| GET | /api/orders | Order history |
| GET | /api/orders/{id} | Order details |
| PUT | /api/orders/{id}/status | Update status (admin) |

### Admin
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/admin/dashboard | Dashboard stats |
| GET | /api/admin/orders | All orders |

---

## Local Development

### Prerequisites
- Docker and Docker Compose
- Python 3.11+ (for local development without Docker)

### Using Docker Compose

```bash
# Clone repository
git clone https://github.com/muhsinzak47-ux/hybrid-commerce-devops.git
cd hybrid-commerce-devops

# Start all services
cd docker
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

Access points:
- Frontend: http://localhost:5173
- Backend API: http://localhost:8000
- API Documentation: http://localhost:8000/docs
- Health Check: http://localhost:8000/health
- PostgreSQL: localhost:5432
- Redis: localhost:6379

### Without Docker

```bash
# Create virtual environment
cd app/backend
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env
# Edit .env and set SECRET_KEY

# Run migrations (create tables)
# Tables are auto-created on first startup

# Start server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## AWS Deployment

### Cost Estimate (5-Day Demo)

| Resource | Type | Cost |
|----------|------|------|
| EC2 t2.micro | Compute | $0 (Free Tier) |
| EBS 8GB gp3 | Storage | $0 (Free Tier) |
| S3 Bucket | Storage | $0 (Free Tier) |
| Application Load Balancer | Load Balancer | ~$4 (5 days) |
| **Total** | | **~$4-5** |

**Important:** The ALB is the only non-Free-Tier resource. Run `terraform destroy` after your demo to avoid charges.

### Quick Start

```bash
# 1. Configure AWS credentials
aws configure

# 2. Create SSH key pair (if not exists)
ssh-keygen -t ed25519 -f ~/.ssh/zakkey -N ""

# 3. Import key to AWS (first time only)
aws ec2 import-key-pair --key-name zakkey --public-key-material file://~/.ssh/zakkey.pub

# 4. Navigate to terraform
cd terraform

# 5. Initialize
terraform init

# 6. Review plan
terraform plan

# 7. Apply
terraform apply

# 8. Get outputs
terraform output

# 9. SSH to server
ssh -i ~/.ssh/zakkey.pem ubuntu@$(terraform output -raw app_server_public_ip)

# 10. Deploy application (on EC2)
cd /opt/hybrid-commerce
source venv/bin/activate
# ... or use deployment script
```

### Cleanup

```bash
# Destroy all AWS resources
cd terraform
terraform destroy

# Verify no resources remain
aws ec2 describe-instances --filters "Name=tag:Project,Values=Hybrid-Commerce"
aws s3 ls | grep hybrid-commerce
```

---

## Kubernetes Deployment

### Prerequisites
- Kubernetes cluster (kubeadm on EC2, k3s, minikube, or managed)
- NGINX Ingress Controller installed
- StorageClass for PVCs

### Deployment Steps

```bash
# Create namespace
kubectl apply -f kubernetes/namespace.yaml

# Create secrets (generate secure values)
kubectl create secret generic hybrid-commerce-secret \
  --from-literal=SECRET_KEY=$(python -c "import secrets; print(secrets.token_urlsafe(32))") \
  --from-literal=POSTGRES_PASSWORD=$(openssl rand -base64 32) \
  -n hybrid-commerce

# Apply ConfigMaps
kubectl apply -f kubernetes/configmap.yaml

# Deploy database (PostgreSQL + PVC)
kubectl apply -f kubernetes/database/pvc.yaml
kubectl apply -f kubernetes/database/deployment.yaml

# Deploy Redis
kubectl apply -f kubernetes/redis/deployment.yaml

# Deploy backend
kubectl apply -f kubernetes/backend/deployment.yaml

# Deploy frontend (when built)
kubectl apply -f kubernetes/frontend/deployment.yaml

# Deploy Ingress
kubectl apply -f kubernetes/ingress.yaml
```

### Verify

```bash
kubectl get all -n hybrid-commerce
kubectl logs -f deployment/backend -n hybrid-commerce
kubectl get ingress -n hybrid-commerce
```

### Scaling

```bash
kubectl scale deployment backend --replicas=3 -n hybrid-commerce
kubectl scale deployment frontend --replicas=3 -n hybrid-commerce
```

---

## Ansible Automation

### Inventory Configuration

Edit `ansible/inventory/hosts.yml`:
```yaml
all:
  children:
    app_servers:
      hosts:
        ec2:
          ansible_host: "your-ec2-public-ip"
          ansible_user: ubuntu
          ansible_ssh_private_key_file: "~/.ssh/your-key.pem"
```

### Running Playbooks

```bash
cd ansible

# Full setup
ansible-playbook playbooks/site.yml -i inventory/hosts.yml --ask-become-pass

# Dry run
ansible-playbook playbooks/site.yml -i inventory/hosts.yml --check

# Specific roles only
ansible-playbook playbooks/site.yml -i inventory/hosts.yml --tags docker
```

### Roles

| Role | Purpose |
|------|---------|
| users | Create application user |
| packages | Install system packages |
| docker | Install Docker + Compose |
| firewall | Configure UFW |
| ssh_hardening | Secure SSH configuration |
| app_deploy | Deploy application |

---

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci-cd.yml`) includes:

1. **Lint** — flake8, black formatting check
2. **Test** — pytest (when tests exist)
3. **Security Scan** — pip-audit, Trivy
4. **Build** — Docker image build and push to GHCR
5. **Deploy** — SSH deploy to EC2

### Required Secrets

Configure these in GitHub repository settings → Secrets:

| Secret | Description |
|--------|-------------|
| `EC2_HOST` | EC2 public DNS or IP |
| `EC2_SSH_KEY` | SSH private key for EC2 |

---

## Monitoring

### Prometheus

Configuration: `monitoring/prometheus/prometheus.yml`

Scrapes:
- Node exporter (CPU, memory, disk per node)
- Kube-state-metrics (pod status, deployments)
- Application metrics (request rate, latency, errors)
- cAdvisor (container metrics)

### Alerts

Configuration: `monitoring/prometheus/alert_rules.yml`

Alert categories:
- **Infrastructure**: CPU > 80%, Memory > 85%, Disk > 85%, Node down
- **Application**: Error rate > 5%, p95 latency > 1s, Backend down
- **Kubernetes**: Pod not running, PV not bound, Replica mismatch

### Grafana

Dashboard: `monitoring/grafana/dashboard.json`

Panels:
- Cluster CPU usage
- Cluster memory usage
- HTTP request rate
- HTTP error rate
- Request latency (p95)
- Pod status table
- Node disk usage

### Deployment

```bash
# Using Helm (recommended)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace

# Or using manifests (manual)
kubectl apply -f monitoring/prometheus/prometheus.yml
kubectl apply -f monitoring/prometheus/alert_rules.yml
```

---

## Security

### Authentication & Authorization
- JWT tokens for API authentication
- Bcrypt password hashing (passlib + bcrypt)
- Role-based access: user vs admin
- Token expiry: 24 hours (configurable)

### Secrets Management
- `.env` files for local development (gitignored)
- Kubernetes Secrets for K8s deployments
- AWS Secrets Manager / Parameter Store (production recommendation)
- Never commit secrets to Git

### Network Security
- AWS Security Groups (least privilege)
- UFW firewall on EC2
- SSH key-only authentication (password disabled)
- Private subnets for database/workloads (Terraform)

### Application Security
- CORS configured (restrict in production)
- Input validation via Pydantic schemas
- SQL injection prevention via SQLAlchemy ORM
- HTTPS/TLS recommended for production (not configured in demo)

### Container Security
- Non-root user in Docker containers
- Minimal base images (python:3.11-slim, alpine)
- Image scanning with Trivy in CI/CD
- Read-only root filesystem (recommended)

### Dependency Security
- `pip-audit` in CI/CD pipeline
- `Trivy` filesystem scan in CI/CD
- Regular dependency updates

---

## Troubleshooting

### Local Development

**Problem: Docker containers won't start**
```bash
# Check Docker is running
docker ps

# View logs
docker-compose logs -f

# Rebuild containers
docker-compose up -d --build
```

**Problem: Database connection error**
```bash
# Ensure PostgreSQL is healthy
docker-compose ps

# Check PostgreSQL logs
docker-compose logs db

# Verify connection
docker-compose exec db psql -U postgres -d hybridcommerce
```

**Problem: Port already in use**
```bash
# Find process using port 8000
lsof -i :8000
# or
netstat -tlnp | grep 8000

# Kill the process
kill -9 <PID>
```

### EC2 Deployment

**Problem: Cannot SSH to EC2**
```bash
# Check security group allows SSH
aws ec2 describe-security-groups --group-ids <sg-id>

# Verify key permissions
chmod 400 ~/.ssh/zakkey.pem

# Try verbose SSH
ssh -v -i ~/.ssh/zakkey.pem ubuntu@<ec2-ip>
```

**Problem: Application not responding**
```bash
# Check service status
ssh -i ~/.ssh/zakkey.pem ubuntu@<ec2-ip>
sudo systemctl status hybrid-commerce

# View logs
sudo journalctl -u hybrid-commerce -f

# Check if port is listening
sudo ss -tlnp | grep 8000
```

**Problem: Terraform apply fails**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Validate configuration
cd terraform
terraform validate

# Check for state lock
terraform force-unlock <LOCK_ID>
```

### Kubernetes

**Problem: Pods stuck in Pending**
```bash
kubectl describe pod <pod-name> -n hybrid-commerce
# Check for PVC binding issues, resource quotas, node selectors
```

**Problem: Image pull error**
```bash
# Check image name and registry access
kubectl describe pod <pod-name> -n hybrid-commerce
# Ensure image exists and credentials are configured
```

**Problem: Ingress not working**
```bash
# Check ingress controller is running
kubectl get pods -n ingress-nginx

# Check ingress configuration
kubectl describe ingress hybrid-commerce-ingress -n hybrid-commerce
```

---

## Architecture Decisions

### Why SQLite for Development?
- Zero configuration, no external dependencies
- Perfect for local development and demos
- Production uses PostgreSQL via Docker or RDS

### Why Self-Managed Kubernetes (not EKS)?
- EKS costs $72/month for control plane (not Free Tier)
- Self-managed on t2.micro demonstrates kubeadm skills
- Suitable for capstone demonstration purposes

### Why No NAT Gateway?
- NAT Gateway costs ~$32/month + data processing
- For demo, EC2 in public subnet with restricted SG is sufficient
- Production would use NAT Gateway for private subnet internet access

### Why HTTP Not HTTPS for Demo?
- ACM certificate requires DNS validation (additional setup time)
- HTTPS should be enabled in production
- ALB supports easy HTTPS configuration with ACM

### Why Ansible Instead of Packer?
- Ansible is more universally applicable
- Demonstrates configuration management skills
- Can be used for both initial setup and ongoing management
- Packer would create AMI (less flexible for updates)

---

## Deliverables Checklist

- [x] Project proposal (this README)
- [x] Architecture diagram (ASCII in README)
- [x] Network diagram (ASCII in README)
- [x] Git repository (GitHub)
- [x] Ansible playbooks (ansible/)
- [x] Terraform code (terraform/)
- [x] Dockerfiles (app/backend/Dockerfile)
- [x] Docker Compose (docker/)
- [x] Kubernetes manifests (kubernetes/)
- [x] CI/CD pipeline (.github/workflows/)
- [x] Monitoring configuration (monitoring/)
- [x] Deployment documentation (this README)
- [ ] Final project presentation (PowerPoint/Google Slides)
- [ ] Project demonstration video

---

## Future Improvements

1. **Frontend**: Build React frontend with full UI
2. **Database**: Add Alembic migrations
3. **Testing**: Add comprehensive pytest suite
4. **HTTPS**: Enable TLS with ACM certificate
5. **CI/CD**: Add blue-green deployment strategy
6. **Monitoring**: Add distributed tracing (Jaeger)
7. **Logging**: Centralized logging (ELK/Fluentd)
8. **Performance**: Add caching layer (Redis for product catalog)
9. **Security**: Add rate limiting, CSRF protection
10. **CI/CD**: Add canary deployment capability

---

## Author

Capstone Student — muhsinzak47-ux

## References

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
