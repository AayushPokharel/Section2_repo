# Facilitator Guide — Progressive Build: Azure Landing Zone

A teaching script for building the Section 2 landing zone incrementally. Each step reveals **one** `.tf` file, plans it (so students see *only* the new resources), applies it, and gets taught before moving on. State is cumulative — after Step 9 the directory equals the full repo.

---

## How the environment works

- **One working directory, one state file.** `terraform apply` is convergent: already-created resources stay, the newly revealed file's resources get added. This is normal Terraform — no `-target`, no anti-patterns.
- **`steps/0X-*.tf` are inert** until copied into the root. Terraform only loads `.tf` from the working directory, so nothing applies before you reveal it.
- **Forward-only dependencies** (audited): each file only references resources introduced in its own step or earlier, so every `plan` is clean.
- **Recovery:** a failed/behind student runs `make all` (or re-reveals + re-applies) — applies are idempotent.
- **Optional git checkpoints:** after each successful apply, `git add -A && git commit -m "step N" && git tag stepN`. A straggler can `git checkout stepN -- .` then `terraform apply`.

## Instructor prep (do this before class)

Run the whole thing once end-to-end in your own subscription, confirm all nine applies succeed, then `make destroy`. This warms the marketplace image terms and surfaces any subscription quota issues (vCPU quota for 2× `Standard_B2s`, App Service regional availability) before students hit them live.

## Pacing (≈ 4 hours)

| Step | Resource | Build | Teach |
|---|---|---|---|
| 0 | Foundation & auth | 15 min | 15 min |
| 1 | Resource group | 5 | 10 |
| 2 | VNet + subnets | 5 | 20 |
| 3 | NSGs | 5 | 20 |
| 4 | Linux VM | 10 | 20 |
| 5 | Windows VM | 10 | 10 |
| 6 | Storage + Key Vault | 5 | 20 |
| 7 | App Service + slot | 10 | 20 |
| 8 | Private endpoint | 10 | 15 |
| 9 | Outputs + wrap | 5 | 10 |

VM and private-endpoint applies dominate wall-clock time — use those minutes to teach, not to watch a spinner.

---

## Step 0 — Foundation & authentication

**Reveal:** nothing new — `versions.tf`, `variables.tf`, `locals.tf`, `environments/*.tfvars` are already present.

**Setup (each student):**
```bash
az login
az account set --subscription "<SUBSCRIPTION>"
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export TF_VAR_windows_admin_password='<Strong-Passw0rd!>'
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa -N ""   # skip if a key already exists
terraform init
terraform plan -var-file=environments/dev.tfvars
```

**Expected:** `No changes. Your infrastructure matches the configuration.` — there are no resources yet.

**Teach / highlight:**
- Provider **version pinning** (`~> 4.0`) and why we hold off v5 (breaking changes, shipped days ago).
- The three **auth inputs**: `az login` (CLI auth), `ARM_SUBSCRIPTION_ID` (mandatory in v4), and `TF_VAR_*` for secrets that never touch a file.
- **Variables vs locals vs tfvars:** variables are the interface, locals are computed (`name_prefix`, `common_tags`), tfvars supply per-environment values.
- What `init` did: downloaded the provider, wrote `.terraform.lock.hcl`.

---

## Step 1 — Resource Group

**Reveal:** `steps/01-resource-group.tf`  → `make step-1`

**Commands (raw equivalent):**
```bash
cp steps/01-resource-group.tf .
terraform fmt && terraform validate
terraform plan -var-file=environments/dev.tfvars -out=tfplan
terraform apply tfplan
```

**Expected plan:** `Plan: 1 to add, 0 to change, 0 to destroy.`

**Teach / highlight:**
- The resource group as the **lifecycle + RBAC + billing boundary**.
- The **naming standard** `rg-<project>-<env>-<region>` coming from `local.name_prefix`, and the tag map applied to *every* resource.
- Open `terraform.tfstate` (read-only!) to show that state now tracks one real object.

**Verify:**
```bash
az group show -n rg-heapp-dev-eus -o table
```

---

## Step 2 — Virtual Network + tiered subnets

**Reveal:** `steps/02-network.tf`  → `make step-2`  (VNet + 4 subnets)

**Expected plan:** `Plan: 5 to add.`

**Teach / highlight:**
- The `/16` address space and the **tiering** rationale: shared-services / web / data / appsvc.
- **Subnet delegation** on `snet-appsvc-integration` (`Microsoft.Web/serverFarms`) — this is what lets App Service inject into the VNet in Step 7.
- `private_endpoint_network_policies = "Disabled"` on the data subnet — set *now* so we never do an in-place subnet update mid-course; it's the prerequisite for Step 8.
- Point out these 4 subnets are separate resources in state, not attributes of the VNet.

**Verify:**
```bash
az network vnet subnet list --vnet-name vnet-heapp-dev-eus -g rg-heapp-dev-eus \
  -o table --query "[].{Name:name, Prefix:addressPrefix}"
```

---

## Step 3 — Network Security Groups

**Reveal:** `steps/03-nsg.tf`  → `make step-3`  (2 NSGs + 2 subnet associations)

**Expected plan:** `Plan: 4 to add.`

**Teach / highlight:**
- **Least-privilege** design: web tier takes 80/443 from Internet but SSH only from `mgmt_source_cidr`; data tier takes 1433/3389 *only from the web subnet CIDR* and denies everything else at priority 4096.
- **Rule priority** ordering and the explicit `deny-all-inbound` catch-all.
- **Subnet vs NIC association** — we associate at the subnet, so every NIC in the subnet inherits it; effective rules are the intersection of subnet + NIC NSGs.
- Foreshadow the troubleshooting lab: these exact rules are what IP-flow-verify and connection-troubleshoot will exercise.

**Verify:**
```bash
az network nsg rule list --nsg-name nsg-data-heapp-dev-eus -g rg-heapp-dev-eus \
  -o table --query "[].{Name:name, Prio:priority, Access:access, Port:destinationPortRange}"
```

---

## Step 4 — Linux web VM

**Reveal:** `steps/04-compute-linux.tf`  → `make step-4`  (public IP + NIC + VM)

**Expected plan:** `Plan: 3 to add.` (≈ 2–3 min apply)

**Teach / highlight:**
- A VM is **three resources**: `public_ip` → `network_interface` → `linux_virtual_machine`. Terraform builds the dependency graph from the references between them.
- **Zonal** deployment (`zone = "1"`), Standard-SKU static public IP (required for zones), **Premium managed** OS disk.
- **SSH-key auth** via `file(pathexpand(...))` — no passwords on the Linux box.
- The **image URN** `Canonical:ubuntu-24_04-lts:server:latest`.

**Verify:**
```bash
IP=$(az vm show -d -g rg-heapp-dev-eus -n vm-web-linux-dev --query publicIps -o tsv)
echo "$IP"; ssh -o StrictHostKeyChecking=accept-new azureadmin@"$IP" 'hostname && cat /etc/os-release | head -1'
```

---

## Step 5 — Windows data VM

**Reveal:** `steps/05-compute-windows.tf`  → `make step-5`  (private NIC + VM)

**Expected plan:** `Plan: 2 to add.` (≈ 3–5 min apply)

**Teach / highlight:**
- **No public IP** — this VM lives in the locked-down data tier and is only reachable from the web subnet (per Step 3). That isolation is the point.
- **Password auth** sourced from the environment variable, kept out of state files where possible and flagged `sensitive`.
- Contrast `azurerm_windows_virtual_machine` vs the Linux resource; note the 15-char `computer_name` limit.

**Verify:**
```bash
az vm list -g rg-heapp-dev-eus -o table --query "[].{Name:name, OS:storageProfile.osDisk.osType, Zone:zones[0]}"
```

---

## Step 6 — Storage, Key Vault & data sources

**Reveal:** `steps/06-storage-keyvault.tf`  → `make step-6`  (`random_string` + `client_config` data source + storage + key vault)

**Expected plan:** `Plan: 3 to add.` (the `data` source is *read*, not added)

**Teach / highlight:**
- **Data sources** — `azurerm_client_config` reads the current tenant/subscription context to wire the Key Vault's `tenant_id`. Data ≠ resource: Terraform reads it, never creates it.
- **`random_string`** solves **globally-unique** naming for storage/KV/web-app; introduce it here because Step 7 depends on it.
- **Storage hardening:** `min_tls_version = TLS1_2`, `https_traffic_only_enabled`, access tier.
- **RBAC-authorization Key Vault** (`enable_rbac_authorization = true`) instead of legacy access policies.

**Verify:**
```bash
az storage account list -g rg-heapp-dev-eus -o table --query "[].{Name:name, Tier:sku.name, TLS:minimumTlsVersion}"
az keyvault list -g rg-heapp-dev-eus -o table --query "[].{Name:name, RBAC:properties.enableRbacAuthorization}"
```

---

## Step 7 — App Service plan, web app & staging slot

**Reveal:** `steps/07-appservice.tf`  → `make step-7`  (plan + web app + slot)

**Expected plan:** `Plan: 3 to add.`

**Teach / highlight:**
- **Why the SKU is `S1`:** deployment slots **and** regional VNet integration both need Standard+. F1/B1 would silently fail the slot — a great "read the SKU matrix" lesson.
- **Regional VNet integration** via `virtual_network_subnet_id` pointing at the delegated subnet from Step 2 — this is why the delegation had to exist first.
- **Deployment slots** (`staging`) for zero-downtime swap; the app name carries the random suffix for global DNS uniqueness.

**Verify:**
```bash
APP=$(az webapp list -g rg-heapp-dev-eus --query "[0].name" -o tsv)
az webapp show -g rg-heapp-dev-eus -n "$APP" --query "{Host:defaultHostName, State:state}" -o table
az webapp deployment slot list -g rg-heapp-dev-eus -n "$APP" -o table
```

---

## Step 8 — Private endpoint & private DNS

**Reveal:** `steps/08-private-endpoint.tf`  → `make step-8`  (private DNS zone + VNet link + private endpoint)

**Expected plan:** `Plan: 3 to add.` (≈ 2–3 min apply)

**Teach / highlight:**
- **Private Link**: the private endpoint plants a NIC in the data subnet that maps to the storage blob service — traffic never traverses the public internet.
- **Private DNS**: the `privatelink.blob.core.windows.net` zone + VNet link is what makes `<storage>.blob.core.windows.net` resolve to the private `10.20.3.x` address from inside the VNet. Break the link and you've reproduced the classic "private endpoint resolves to a public IP" incident — the exact DNS troubleshooting scenario.
- This is why Step 2 set `private_endpoint_network_policies = "Disabled"` up front.

**Verify:**
```bash
az network private-endpoint list -g rg-heapp-dev-eus -o table --query "[].{Name:name, State:provisioningState}"
az network private-dns zone list -g rg-heapp-dev-eus -o table --query "[].{Zone:name, Records:numberOfRecordSets}"
```

---

## Step 9 — Outputs & convergence check

**Reveal:** `steps/09-outputs.tf`  → `make step-9`  (outputs only)

**Expected plan:** `Plan: 0 to add` with `Changes to Outputs:` shown.

**Teach / highlight:**
- **Outputs** as the module's public contract — VM IPs, App Service URL, KV URI — the values a downstream stage or the troubleshooting lab consumes.
- Run a final `terraform plan` → **`No changes`** proves the incremental build converged to the same state as the monolithic repo.

**Verify:**
```bash
terraform apply tfplan
terraform output
terraform plan -var-file=environments/dev.tfvars   # => No changes.
```

**Equivalence:** these nine files (24 resources) provision the identical landing zone as your flat repo — `01-05` map to `network.tf`/`compute.tf`, `06`+`08` to `data.tf`, `07` to `appservice.tf`, `09` to `outputs.tf`.

---

## Wrap-up options

- Hand off directly into the **Network Watcher troubleshooting lab** (Steps 14–17 of the main guide) — the NSGs, VMs, and private endpoint are all in place and the outputs feed the `az network watcher` commands.
- Re-run `make step-2` after editing a subnet to demonstrate **in-place updates** vs the create-only applies students just saw.
- `ENV=test make step-1 … apply` to show the **same code, different tfvars** producing a parallel environment.

## Teardown
```bash
make destroy     # or: terraform destroy -var-file=environments/dev.tfvars
```
