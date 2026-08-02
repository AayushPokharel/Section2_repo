# Progressive-build harness for the Azure Landing Zone lab.
# Usage: `make init` once, then `make step-1`, review the plan, `make apply`, repeat.
ENV     ?= dev
VARFILE := environments/$(ENV).tfvars

.PHONY: help init plan apply all reset destroy fmt validate
help:
	@echo "make init         # terraform init (run once)"
	@echo "make step-N       # reveal step N's file, then fmt + validate + plan"
	@echo "make apply        # apply the plan produced by the last step-N"
	@echo "make all          # reveal + apply every step in order (catch-up / smoke test)"
	@echo "make reset        # remove revealed step files + plan (state untouched)"
	@echo "make destroy      # terraform destroy everything"
	@echo "ENV=test make ...  # target a different environment"

init:      ; terraform init -input=false
fmt:       ; terraform fmt
validate:  ; terraform validate
plan: fmt validate
	terraform plan -var-file=$(VARFILE) -out=tfplan
apply:     ; terraform apply tfplan

step-1: ; cp steps/01-resource-group.tf .    && $(MAKE) plan
step-2: ; cp steps/02-network.tf .            && $(MAKE) plan
step-3: ; cp steps/03-nsg.tf .                && $(MAKE) plan
step-4: ; cp steps/04-compute-linux.tf .      && $(MAKE) plan
step-5: ; cp steps/05-compute-windows.tf .    && $(MAKE) plan
step-6: ; cp steps/06-storage-keyvault.tf .   && $(MAKE) plan
step-7: ; cp steps/07-private-endpoint.tf .   && $(MAKE) plan
step-8: ; cp steps/08-outputs.tf .            && $(MAKE) plan

all:
	@for f in steps/*.tf; do \
		echo "==> revealing $$f"; cp $$f .; \
		terraform apply -var-file=$(VARFILE) -auto-approve; \
	done

reset: ; rm -f [0-9][0-9]-*.tf tfplan
destroy: ; terraform destroy -var-file=$(VARFILE)
