# GadgetsOnline — Docker Build & Run Guide

## Overview

GadgetsOnline is an ASP.NET Core MVC e-commerce web application built on .NET 8, using Entity Framework 6 with SQL Server. Database credentials are retrieved at startup from **AWS Secrets Manager**; a fallback connection string in `appsettings.json` is used if Secrets Manager is unavailable.

---

## Prerequisites

- Docker installed and running
- AWS credentials available (for Secrets Manager access at runtime)
- A reachable SQL Server / RDS instance

---

## Build

The build context must be the **root of the extracted source directory** (the directory containing `GadgetsOnline/` and `GadgetsOnline.sln`).

```bash
# From the root of the extracted source archive:
docker build -t gadgetsonline .
```

---

## Run

### With AWS Secrets Manager (recommended for production)

The container requires an IAM role or AWS credentials with the following permissions:
- `secretsmanager:GetSecretValue`
- `secretsmanager:ListSecrets`

When running on **ECS**, attach an ECS Task Role with the above permissions — no environment variables for credentials are needed.

When running **locally** with AWS credentials:

```bash
docker run -p 8080:8080 \
  -e AWS_ACCESS_KEY_ID=<your-access-key> \
  -e AWS_SECRET_ACCESS_KEY=<your-secret-key> \
  -e AWS_SESSION_TOKEN=<your-session-token> \
  -e ASPNETCORE_ENVIRONMENT=Production \
  gadgetsonline
```

### With a direct connection string (fallback / local development)

If AWS Secrets Manager is not available, the app falls back to the `DefaultConnection` connection string:

```bash
docker run -p 8080:8080 \
  -e ConnectionStrings__DefaultConnection="Server=<host>,1433;Database=<dbname>;User Id=<user>;Password=<password>;TrustServerCertificate=true;Encrypt=true" \
  -e ASPNETCORE_ENVIRONMENT=Development \
  gadgetsonline
```

The application will be available at: **http://localhost:8080**

---

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `ConnectionStrings__DefaultConnection` | No (fallback) | SQL Server connection string used when Secrets Manager is unavailable |
| `ASPNETCORE_ENVIRONMENT` | No | ASP.NET Core environment (`Development`, `Staging`, `Production`). Default: `Production` |
| `AWS_REGION` | Yes | AWS region for Secrets Manager (currently hardcoded to `us-east-1` in source; override if deploying to another region) |

---

## Secret Handling

For production deployments, **do not pass database credentials as plain environment variables**. Use:

- **ECS:** [AWS Secrets Manager integration for ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/secrets-envvar-secrets-manager.html) — inject secrets via the ECS task definition `secrets` field.
- **EKS:** [AWS Secrets Manager integration for EKS](https://docs.aws.amazon.com/eks/latest/userguide/security-k8s.html) — use the Secrets Store CSI Driver or KMS encryption.

---

## Exposed Ports

| Port | Protocol | Description |
|---|---|---|
| `8080` | HTTP | ASP.NET Core MVC web application |

---

## External Dependencies

| Dependency | Port | Notes |
|---|---|---|
| MS SQL Server (RDS) | 1433 | Required at startup. App will fail to start if unreachable. |
| AWS Secrets Manager | 443 (HTTPS) | Required at startup unless `DefaultConnection` fallback is configured. |
