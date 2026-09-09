# ============================================================================
# SECURITY DOCUMENTATION
# ============================================================================

## Security Overview

This document describes the security measures implemented in the Hybrid Commerce platform across all layers.

---

## 1. Authentication & Authorization

### JWT Authentication
- **Algorithm**: HS256 (HMAC with SHA-256)
- **Token expiry**: 24 hours (configurable via `ACCESS_TOKEN_EXPIRE_MINUTES`)
- **Storage**: Client-side localStorage (with CSRF caveats noted below)
- **Transport**: `Authorization: Bearer <token>` header on all API requests

### Password Security
- **Hashing algorithm**: bcrypt (via passlib library)
- **Work factor**: Default bcrypt cost factor (12 rounds)
- **Password requirements**: Minimum 6 characters
- **Never stored in plaintext**: Only bcrypt hash is stored in database

### Authorization Model
- **User role**: Can access own cart, own orders, public products
- **Admin role**: Can manage all products, view all orders, update order status
- **Enforcement**: `is_admin` flag checked on every admin endpoint via dependency injection

### Security Considerations
- **CSRF**: Not implemented (stateless JWT). In production, use SameSite cookies + CSRF tokens.
- **XSS**: JWT in localStorage is vulnerable to XSS. Production should use HttpOnly cookies.
- **Token theft**: No token refresh mechanism. Short-lived tokens + refresh tokens recommended for production.

---

## 2. Network Security

### AWS Security Groups

| Security Group | Ingress Rules | Egress Rules |
|----------------|---------------|--------------|
| **alb-sg** | HTTP (80) from 0.0.0.0/0, HTTPS (443) from 0.0.0.0/0 | All traffic to 0.0.0.0/0 |
| **ec2-sg** | SSH (22) from 0.0.0.0/0 (restrict to IP in production), App (8000) from ALB subnet, HTTP (80) from ALB subnet | All traffic to 0.0.0.0/0 |

### UFW Firewall (EC2)
- Default policy: deny incoming
- Allowed ports: 22 (SSH), 80 (HTTP), 443 (HTTPS), 8000 (application)
- Enabled on boot

### VPC Architecture
- Public subnet for ALB and EC2 (with public IP)
- Private subnet reserved for future expansion (database, cache in production)
- No NACLs configured (security groups provide sufficient isolation for demo)

---

## 3. SSH Hardening

### Configuration Applied by Ansible
```ssh-config
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
MaxAuthTries 3
```

### Key Management
- SSH key pair: `zakkey` (ED25519)
- Private key stored locally (never committed to Git)
- Public key imported to AWS EC2 key pairs
- Key permissions: `chmod 400 ~/.ssh/zakkey.pem`

---

## 4. IAM (AWS Identity & Access Management)

### EC2 Instance Role
- **Role name**: `hybrid-commerce-ec2-role`
- **Trust policy**: Allows EC2 service to assume role
- **Attached policy**: `AmazonS3ReadOnlyAccess`
  - Allows EC2 to read from S3 buckets (for product images)
  - No write access (images uploaded via admin API, stored in DB as URLs)
  - No other AWS service access

### Best Practices Demonstrated
- No access keys stored on instance
- Role-based access via instance profile
- Least privilege: only S3 read access
- No administrative IAM user for day-to-day operations

---

## 5. Container Security

### Docker Best Practices
- **Non-root user**: Container runs as `appuser` (UID 1000)
- **Minimal base image**: `python:3.11-slim` (smaller attack surface)
- **No unnecessary packages**: Only required system packages installed
- **Read-only filesystem** (recommended for production, not enforced in demo)

### Image Scanning
- **Trivy**: Integrated in CI/CD pipeline
- Scans for:
  - OS package vulnerabilities
  - Language-specific vulnerabilities (Python)
  - Secrets in image layers

### Dockerfile Security
```dockerfile
# Create non-root user
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app && \
    chmod 755 /app

USER appuser
```

---

## 6. Secrets Management

### Current Approach (Demo)
- `.env` file for local development (gitignored via `.gitignore`)
- Environment variables injected by Docker/FastAPI
- `SECRET_KEY` is the only true secret (JWT signing key)

### Production Recommendations
1. **AWS Secrets Manager**: Store `SECRET_KEY`, database passwords
2. **Kubernetes Secrets**: For K8s deployments (base64 encoded)
3. **Environment injection**: Use IAM roles + Secrets Manager SDK
4. **Rotation**: Rotate `SECRET_KEY` periodically (requires re-issuing tokens)
5. **Never commit**: `.env` files, SSH keys, AWS credentials

### Git Exclusion
Files blocked by `.gitignore`:
```
.env
.env.local
.env.production
*.env
*.db
*.sqlite
*.log
backup/
venv/
__pycache__/
```

---

## 7. Application Security

### Input Validation
- All API inputs validated via Pydantic schemas
- Type checking, length limits, pattern matching
- Example: Product price must be > 0, email must be valid format

### SQL Injection Prevention
- SQLAlchemy ORM used for all database queries
- Parameterized queries (no string concatenation)
- No raw SQL executed from user input

### CORS (Cross-Origin Resource Sharing)
- Currently configured to allow all origins (for demo)
- Production: Restrict to specific frontend domain
```python
allow_origins=["https://yourdomain.com"]  # Instead of ["*"]
```

### Rate Limiting (Not Implemented)
- Not implemented in current demo
- Production recommendations:
  - FastAPI middleware with Redis backend
  - AWS WAF on ALB for DDoS protection
  - API Gateway for advanced rate limiting

---

## 8. Dependency Security

### Automated Scanning
- **pip-audit**: Checks Python dependencies for known vulnerabilities
- **Trivy**: Scans container images and filesystem for CVEs
- **GitHub Dependabot**: (configured) Automatic PRs for vulnerable dependencies

### Dependency Pinning
- All dependencies pinned to exact versions in `requirements.txt`
- Prevents unexpected upgrades that could introduce vulnerabilities
- Regular updates via Dependabot or manual review

---

## 9. Backup & Recovery

### Database Backup
- SQLite backup: `cp hybrid.db backup/hybrid_db_TIMESTAMP.sqlite`
- Automated via `scripts/backup.sh` (runs on schedule or manually)
- Retention: Last 7 days of backups kept

### Infrastructure Recovery
- Terraform can recreate all AWS resources from code
- EC2 user_data script automates initial setup
- Application redeployable via Ansible or deployment script

### Disaster Recovery Plan (Summary)
1. **Minor issue (app crash)**: `systemctl restart hybrid-commerce`
2. **Data corruption**: Restore from latest backup in `backups/`
3. **EC2 failure**: Terraform reprovisions EC2; Ansible configures it
4. **Region failure**: Not covered in demo (multi-region would be production requirement)

---

## 10. Security Checklist

| Control | Status | Notes |
|---------|--------|-------|
| HTTPS/TLS | ❌ Not configured | Use ACM + ALB in production |
| SSH key-only | ✅ Implemented | Password auth disabled |
| Root login disabled | ✅ Implemented | Via Ansible ssh_hardening role |
| Firewall (UFW) | ✅ Implemented | Allow list for specific ports |
| Non-root containers | ✅ Implemented | appuser in Dockerfile |
| JWT authentication | ✅ Implemented | HS256, 24hr expiry |
| Password hashing | ✅ Implemented | bcrypt via passlib |
| Input validation | ✅ Implemented | Pydantic schemas |
| SQL injection prevention | ✅ Implemented | SQLAlchemy ORM |
| Secrets in Git | ✅ Prevented | .gitignore blocks .env, keys |
| IAM least privilege | ✅ Implemented | EC2 role with S3 read only |
| Image scanning | ✅ Implemented | Trivy in CI/CD |
| Dependency scanning | ✅ Implemented | pip-audit in CI/CD |
| Rate limiting | ❌ Not implemented | Recommend for production |
| CSRF protection | ❌ Not implemented | Recommend for production |
| Audit logging | ❌ Not implemented | Recommend for production |
| Backup automation | ⚠️ Partial | Script exists, not scheduled |
| Monitoring/Alerting | ⚠️ Partial | Config exists, not deployed |
