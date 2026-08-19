# mcp-host-provision

Terraform IaC that spins up the AWS host (and supporting services) for a remote MCP sandbox, then calls [mcp-host-configure](https://github.com/geomux/mcp-host-configure) to install [mcp-server-remote](https://github.com/geomux/mcp-server-remote) via Ansible.

*Intended to stand up disposable cloud infrastructure with an AI-integrated remote MCP server quickly & effectively.*

Provision, test, `terraform destroy`.

```
Backend:    tf-state-backend --> S3 bucket + native lock (run ONCE, first)
Provision:  terraform apply --> EC2 host + SG + S3 + CloudTrail --> (host ready)
Configure:  *(automated by User Data script within Terraform)* mcp-host-configure --> installs mcp-server-remote onto the host
Result:     {internet} <--> {host:443} <--> nginx <--> mcp-server-remote <--> tools
```

## User Guide | Setup

### 1. Prerequisites

- Install Terraform **>= 1.10** (native S3 bucket state locking)
- Configure AWS credentials (`aws configure`)
- Create an SSH keypair for the host:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/mcp-host -C "mcp-host-provision"
```


### 2. Stand up the state backend (run once)

This repo keeps its `terraform.tfstate` in S3, not on your local machine. First create the bucket with [tf-state-backend](https://github.com/geomux/tf-state-backend).


### 3. Clone and configure

```bash
git clone https://github.com/geomux/mcp-host-provision.git
cd mcp-host-provision
cp terraform.tfvars.example terraform.tfvars   
nano terraform.tfvars # fill in your values
```

Point the backend at the bucket you just created with tf-state-backend.
Replace `BUCKET_NAME_HERE` in the `backend "s3"` block at the top of `main.tf`.

> [!IMPORTANT]
> Set `allowed_ssh_cidr` in `terraform.tfvars` to **your public IP**.

*Find your public IP.*
```bash
curl -s https://checkip.amazonaws.com   # -> "203.0.113.7", so use "203.0.113.7/32"
```


### 4. Apply

```bash
terraform init      # connects to the tf-state-backend S3 bucket & downloads AWS provider
terraform apply     # the money command
```

Outputs in terminal will include the host's public IPv4, instance ID, and EBS volume ID.


### 5. Tear down when finished

> [!CAUTION]
> You must remember to tear down your cloud infra when you are done using it to prevent racking up excess bills!

```bash
terraform destroy
```


## Hand-off to Ansible

The "hand-off" is automatic. `modules/compute/scripts/user_data.sh` runs on the ec2 instance as a `user_data` script, so on **first boot** it runs as root and:

1. Installs `git`, `pipx`, `openssl`, and Ansible (`pipx install --include-deps ansible`)
2. Clones [mcp-host-configure](https://github.com/geomux/mcp-host-configure) to `/opt/mcp-host-configure`
3. Generates a random bearer token and writes `inventory/hosts.yaml` + `group_vars/all.yaml`
4. Runs `ansible-playbook -i inventory/hosts.yaml playbook.yaml`

The generated inventory in the Ansible playbook uses a local connection to configure the cloud hosted host created with Terraform.


### Verifying it worked

`terraform apply` returns as soon as AWS reports the instance running. 
SSH into the remote host:

```bash
ssh -i ~/.ssh/mcp-host ubuntu@<mcp_server_public_ip>

sudo cat /opt/mcp-host-provision/provision-complete   # timestamp = finished OK
sudo tail -f /var/log/cloud-init-output.log           # full run log, or why it failed
```

No `provision-complete` file means the script stopped early; the tail of the log shows where.


### Setting your own server values

`user_data.sh` writes `group_vars/all.yaml` with **defaults plus a randomly generated auth token**. That is enough to bring the server up, but the values are almost certainly not the ones you want. Read the generated token, then adjust the rest on the host:

```bash
sudo cat /opt/mcp-host-provision/mcp_auth_token.txt   # the bearer token, 64 hex chars
sudo nano /opt/mcp-host-configure/group_vars/all.yaml
```

| Value             | Default written by `user_data.sh` | What it does                                        |
| ----------------- | --------------------------------- | --------------------------------------------------- |
| `mcp_server_name` | `mcp-cloud-box`                   | Label for this box              |
| `mcp_server_port` | `9000`                            | Port `mcp-server-remote` binds on `127.0.0.1`        |
| `mcp_server_path` | `/mcp`                            | URL path nginx proxies through to the MCP server     |
| `mcp_auth_token`  | `openssl rand -hex 32` output     | Bearer token `mcp-client-console` authenticates with |

Re-run the playbook to apply changes you might make to the all.yaml Ansible config.

```bash
cd /opt/mcp-host-configure
sudo ansible-playbook -i inventory/hosts.yaml playbook.yaml
```


## Connect a Client

With the remote host provisioned and configured, use [mcp-client-console](https://github.com/geomux/mcp-client-console) to reach the remote MCP server in your cloud stack. Set its `[server]` `url` to the host (via the output IP or tunnel) and the bearer `token`. Call the remote MCP server's tools with LLM natural language processing.


## Configuration

All configurable values are in root `variables.tf`, private values are in root `terraform.tfvars`.
All values are forwarded into the config modules, so nothing needs to be edited inside `modules/`.

| Variable              | Required | Default              | Purpose                                      |
| --------------------- | -------- | -------------------- | -------------------------------------------- |
| `allowed_ssh_cidr`    | yes      | -                    | CIDR range allowed to SSH into the host   |
| `project_name`        | no       | `mcp-host`           | Name prefix applied to every resource        |
| `ssh_public_key_path` | no       | `~/.ssh/mcp-host.pub`| Public key uploaded as the EC2 key pair      |
| `aws_region`          | no       | `us-east-1`          | Region (determines default AZ too)   |
| `instance_type`       | no       | `t3.micro`           | EC2 instance size                            |
| `ebs_volume_size`     | no       | `8`                  | Size (GB) of the attached `gp3` volume     |


## Repo Layout

| Path                    | Purpose                                                        |
| ----------------------- | -------------------------------------------------------------- |
| `main.tf`               | Root config: backend, provider, key pair, module wiring       |
| `variables.tf`          | Root input variables: fill via `terraform.tfvars`             |
| `outputs.tf`            | Prints host public IP, instance ID, volume ID after `terraform apply`     |
| `terraform.tfvars.example` | Tracked .git template: copy to the gitignored `terraform.tfvars` |
| `modules/networking/`   | VPC, subnet, gateway, routing, security group + rules          |
| `modules/compute/`      | EC2 host, EBS volume, AMI lookup, User Data configuration script   |


## What Gets Spun Up

Each module splits its resources into **main** infrastructure (the services) and **auxiliary** infrastructure (the settings).

| Main Resources         | Module       | Purpose                                                                      |
| ---------------------- | ------------ | ---------------------------------------------------------------------------- |
| `aws_key_pair`         | root         | Registers your SSH public key with AWS so you can reach the host             |
| `aws_vpc`              | `networking` | Isolated private network the whole sandbox lives in                          |
| `aws_internet_gateway` | `networking` | Gives the VPC a path to and from the public internet                         |
| `aws_route_table`      | `networking` | Routes all non-local traffic (`0.0.0.0/0`) out through the internet gateway  |
| `aws_subnet`           | `networking` | Public subnet in AZ `<region>a` ...auto-assigns a public IPv4 on launch        |
| `aws_security_group`   | `networking` | Virtual firewall attached to the host (rules defined as auxiliary resources) |
| `aws_instance`         | `compute`    | The EC2 host that will run `mcp-server-remote`, bootstrapped via `user_data` |
| `aws_ebs_volume`       | `compute`    | `gp3` data volume for the host, sized by `ebs_volume_size`                   |

| Auxiliary Resources                   | Module       | Purpose                                                                 |
| ------------------------------------- | ------------ | ----------------------------------------------------------------------- |
| `data.aws_caller_identity`            | root         | Looks up the account/ARN Terraform is authenticating as                 |
| `aws_route_table_association`         | `networking` | Binds the route table to the subnet, making the subnet public           |
| `aws_vpc_security_group_ingress_rule` | `networking` | Inbound SSH on `22`, restricted to `allowed_ssh_cidr`                   |
| `aws_vpc_security_group_ingress_rule` | `networking` | Inbound HTTPS on `443` from anywhere, for MCP / tunnel traffic          |
| `aws_vpc_security_group_egress_rule`  | `networking` | Outbound all protocols to anywhere, so the host can pull packages/repos |
| `data.aws_ami`                        | `compute`    | Resolves the newest Canonical Ubuntu 22.04 AMI for the instance         |
| `aws_volume_attachment`               | `compute`    | Attaches the EBS volume to the instance at `/dev/sdf`                   |


## Design Notes

- **Remote state, native locking.** State lives in S3 with >= Terraform 1.10 `use_lockfile`. No DynamoDB table is needed to hold a lock.
- **No secrets in state.** The MCP bearer token is generated *on the host* by `user_data.sh`, never passed in as a Terraform variable. Important because variable values are stored as text in the state file.
- **SSH is scoped to one address.** `allowed_ssh_cidr` is the only required variable, and it has no default. Provisioning will not open port 22 to the world (e.g. no CIDR 0.0.0.0/0).
- **Modules are reusable.** Every module is has values declared and forwared in root `variables.tf`. No need to edit modules- they work as is.
- **Disposable by design.** `terraform destroy` removes everything, and a quick `terraform apply` rebuilds/reconfigures from scratch.


## Related / Required Repos

- [mcp-host-configure](https://github.com/geomux/mcp-host-configure) - Ansible that configures the provisioned host
- [mcp-server-remote](https://github.com/geomux/mcp-server-remote) - the MCP server installed onto the host
- [mcp-client-console](https://github.com/geomux/mcp-client-console) - client + LLM to access the remote MCP server in your stack
- [mcp-sandbox-setup](https://github.com/geomux/mcp-sandbox-setup) - Docker-based equivalent of this cloud infra "sandbox"
- [tf-state-backend](https://github.com/geomux/tf-state-backend) - S3 remote state bucket + lock (run as step #1 prerequ for this repo)


## Project Status

- [x] Create provision repo
- [x] Root Terraform scaffolding (main / variables / outputs)
- [x] Backend block wired to tf-state-backend S3 bucket
- [x] Networking module (VPC, subnet, routing, security group)
- [x] Compute module (EC2 host, EBS volume, cloud-init hand-off)
- [ ] Logging module (S3 + CloudTrail)
- [ ] End-to-end: run `terraform apply` -> autos `mcp-host-configure` -> access live MCP server from [mcp-client-console]
