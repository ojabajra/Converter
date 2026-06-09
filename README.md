# plat-converter

A lightweight HTTP API that converts numbers between decimal, binary, and hexadecimal bases.

```
GET /convert/<value>/<input-format>/<output-format>

# Examples
GET /convert/255/dec/hex   → ff
GET /convert/ff/hex/bin    → 11111111
GET /convert/1010/bin/dec  → 10
```

Formats: `dec`, `bin`, `hex`

## Local Development

### Prerequisites
- Docker
- Docker Compose

### Running Locally
```bash
docker compose up
```

The API will be available at `http://localhost:8080`.

## Deployment

| Target | Guide |
|---|---|
| AWS (ECS Fargate) | [CLOUD-DEPLOYMENT.md](CLOUD-DEPLOYMENT.md) |
| On-premises (VM + Nginx Proxy Manager) | [ON-PREM-DEPLOYMENT.md](ON-PREM-DEPLOYMENT.md) |
