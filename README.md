# Azure Landing Zone — Progressive Build Environment

A hands-on, instructor-led lab that builds the Section 2 landing zone **one resource group at a time**.
Students start with only the foundation files and reveal one `.tf` file per step. Every `terraform apply`
is cumulative, so by Step 8 the working directory equals the full landing zone.

## Layout
```
.
├── versions.tf variables.tf locals.tf   # foundation (present from the start)
├── environments/{dev,test,prod}.tfvars  # per-env values
├── steps/0X-*.tf                         # instructor reveal files (NOT loaded until copied to root)
├── Makefile                              # optional harness (make step-1, make apply, ...)
└── facilitator-guide.md                  # the step-by-step teaching script
```

## One-time setup (each student)
```bash
az login
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export TF_VAR_windows_admin_password='<Strong-Passw0rd!>'
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa -N ""   # if you don't already have a key
terraform init      # or: make init
```
