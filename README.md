# mcp-host-provision

Terraform IaC that spins up the AWS host (and supporting services) for a remote MCP sandbox, then hands off to [mcp-host-configure](https://github.com/geomux/mcp-host-configure) to install [mcp-server-remote](https://github.com/geomux/mcp-server-remote) via Ansible.

*Intended to stand up disposable cloud infrastructure with an AI-integrated remote MCP server primed and ready to go.*

Provision, test, `terraform destroy`.

```
Backend:    tf-state-backend --> S3 bucket + native lock (run ONCE, first)
Provision:  terraform apply --> EC2 host + SG + S3 + CloudTrail --> (host ready)
Configure:  mcp-host-configure (Ansible) --> installs mcp-server-remote onto the host
Result:     {internet} <--> {host:443} <--> nginx <--> mcp-server-remote <--> tools
```

## What Gets Spun Up

| Resource            | Purpose                                                              |
| ------------------- | ------------------------------------------------------------------- |
| `aws_instance`      | The EC2 host that will run `mcp-server-remote`                       |
| `aws_security_group`| Ingress rules for the sandbox (HTTPS / tunnel traffic)              |
| `aws_s3_bucket`     | Storage for artifacts, logs, and Ansible-consumed assets            |
| `aws_cloudtrail`    | Audit trail of all API activity against the sandbox account         |

## Repo Layout

| File               | Purpose                                                       |
| ------------------ | ------------------------------------------------------------- |
| `main.tf`          | Root config ...wires modules and providers together            |
| `variables.tf`     | Root input variables (fill via `terraform.tfvars`)            |
| `outputs.tf`       | Exposes host IP, bucket name, etc. after apply                |
| `modules/`         | Reusable submodules (ec2 host, networking, logging)        |

## User Guide | Prerequisite: State Backend (run first)

Before running this repo, stand up the remote state backend with [tf-state-backend](https://github.com/geomux/tf-state-backend). It creates the S3 bucket that holds this repo's `terraform.tfstate`, using Terraform **v1.10** native S3 state locking (lockfile in the bucket, no DynamoDB). Run it once, then point this repo's backend config at that bucket.

## User Guide | Usage

Requires Terraform **>= 1.10** and AWS credentials configured (`aws configure` or env vars).

```bash
git clone git@github.com:geomux/mcp-host-provision.git
cd mcp-host-provision
cp terraform.tfvars.example terraform.tfvars    # fill in your values
terraform init                                  # connect to the tf-state-backend S3 bucket
terraform apply
```

When finished, tear the cloud infrastructure down:

```bash
terraform destroy
```

## User Guide | Hand-off to Ansible

Once `terraform apply` reports the host is up, point [mcp-host-configure](https://github.com/geomux/mcp-host-configure) at the output host IP to install, then start `mcp-server-remote`.

## User Guide | Connect a Client

With the host provisioned and configured, use [mcp-client-console](https://github.com/geomux/mcp-client-console) to reach the remote MCP server in your cloud stack. Set its `[server]` `url` to the host (via the output IP/DNS or a tunnel) and the bearer `token`, then drive the server's tools with LLM natural language processing.

## Related / Required Repos

- [mcp-host-configure](https://github.com/geomux/mcp-host-configure) - Ansible that configures the provisioned host
- [mcp-server-remote](https://github.com/geomux/mcp-server-remote) - the MCP server installed onto the host
- [mcp-client-console](https://github.com/geomux/mcp-client-console) - client + LLM to access the remote MCP server in your stack
- [mcp-sandbox-setup](https://github.com/geomux/mcp-sandbox-setup) - Docker-based equivalent of this sandbox
- [tf-state-backend](https://github.com/geomux/tf-state-backend) - S3 remote state bucket + lock (run first)

## Project Status

- [x] Create provision repo
- [x] Root Terraform scaffolding (main / variables / outputs)
- [ ] Wire backend to tf-state-backend S3 bucket
- [ ] EC2 host + security group module
- [ ] S3 + CloudTrail modules
- [ ] End-to-end: `terraform apply` --> `mcp-host-configure` --> live MCP server
