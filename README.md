# Azure VM Terraform Deployment with Azure Pipelines

Deploy and manage Azure Linux Virtual Machines using Infrastructure-as-Code (Terraform) with automated CI/CD pipelines powered by Azure Pipelines.

## Overview

This repository contains a complete infrastructure-as-code solution for deploying, managing, and destroying Azure resources. It demonstrates best practices for:

- **Terraform Configuration**: Modular setup for Azure VMs with networking, security, and access management
- **Remote State Management**: Centralized state storage in Azure Storage Account for team collaboration
- **CI/CD Automation**: Automated deployment pipelines with plan, apply, and destroy stages
- **Infrastructure Security**: Network security groups, encrypted credentials, and proper RBAC

## Prerequisites

Before getting started, ensure you have:

### Local Development
- [Terraform](https://www.terraform.io/downloads.html) (latest version)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) v2.0+
- An Azure subscription with contributor access

### Azure Pipeline Requirements
- Azure DevOps project with pipeline access
- Azure Service Connection (`azure-tfm-sc`) configured in your project
- Variable group `dev-secrets` with the following secret:
  - `VM_PASS`: Admin password for the virtual machine
- Self-hosted agent pool named `Default` (or configure your preferred pool)

### Backend State Storage
- Azure Storage Account: `azweutfstate`
- Resource Group: `tfm-tfstate`
- Container: `tfstate`

## Project Structure

```
test-azpipelines/
├── .pipelines/                    # Azure Pipeline definitions
│   ├── az-rg-display-pipeline.yml # Display resource groups
│   ├── vm-build.yml              # Plan → Apply deployment pipeline
│   └── vm-destroy.yml            # Destroy all resources pipeline
├── az-vm-tfm/                     # Terraform configuration
│   ├── main.tf                    # Main resource definitions
│   └── variables.tf               # Input variables and configuration
├── scripts/                       # Utility scripts
│   └── rg-display.sh             # List Azure resource groups
└── README.md                      # This file
```

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd test-azpipelines
```

### 2. Configure Azure Authentication

```bash
az login
az account set --subscription <your-subscription-id>
```

### 3. Initialize Terraform

```bash
cd az-vm-tfm
terraform init \
  -backend-config="resource_group_name=tfm-tfstate" \
  -backend-config="storage_account_name=azweutfstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=vm-deploy.tfstate"
```

### 4. Review and Deploy Locally

```bash
# Plan the deployment
export TF_VAR_admin_password="YourSecurePassword123!"
terraform plan -out=tfplan

# Apply the changes
terraform apply tfplan

# View outputs
terraform output
```

## Configuration

### Customizable Variables

Edit `az-vm-tfm/variables.tf` or pass variables via `-var` flag:

| Variable | Default | Description |
|----------|---------|-------------|
| `resource_group_name` | `rg-terraform-vm-demo` | Azure resource group name |
| `location` | `West Europe` | Azure region for resources |
| `vm_name` | `my-linux-vm` | Virtual machine hostname |
| `admin_username` | `azureuser` | VM admin username |
| `admin_password` | (required) | VM admin password (sensitive) |

### Example: Custom Deployment

```bash
cd az-vm-tfm
terraform plan \
  -var="resource_group_name=my-custom-rg" \
  -var="location=East US" \
  -var="vm_name=custom-vm" \
  -var="admin_password=MySecurePassword123!"
```

## Azure Resources Created

The Terraform configuration creates:

- **Resource Group**: Contains all resources
- **Virtual Network**: 10.0.0.0/16 address space
- **Subnet**: 10.0.2.0/24 for VM deployment
- **Public IP**: Static IP for VM access
- **Network Interface**: VM network connectivity
- **Network Security Group**: Allows SSH (port 22) inbound
- **Linux Virtual Machine**: Ubuntu-based, cost-effective `Standard_B1s` size

## CI/CD Automation with Azure Pipelines

### Available Pipelines

#### 1. **VM Build Pipeline** (`vm-build.yml`)
Automated deployment pipeline with manual approval gates.

- **Trigger**: Manual
- **Stages**:
  - `Plan`: Terraform plan (auto-approved)
  - `Deploy`: Terraform apply (requires environment approval)

**To Run:**
```bash
# Via Azure DevOps UI
# 1. Go to Pipelines
# 2. Select "vm-build"
# 3. Click "Run pipeline"
# 4. Select branch (dev/main)
# 5. Approve deployment in the "dev" environment
```

#### 2. **VM Destroy Pipeline** (`vm-destroy.yml`)
Destroys all infrastructure - use with caution!

- **Trigger**: Manual
- **Stage**: Terraform destroy (requires environment approval)

**To Run:**
```bash
# Via Azure DevOps UI
# 1. Go to Pipelines
# 2. Select "vm-destroy"
# 3. Click "Run pipeline"
# 4. Select branch
# 5. Approve destruction in the "dev" environment
```

#### 3. **Resource Group Display Pipeline** (`az-rg-display-pipeline.yml`)
Utility pipeline for viewing all resource groups.

### Pipeline Configuration

#### Set Up Service Connection

1. In Azure DevOps, go to **Project Settings** → **Service connections**
2. Create new **Azure Resource Manager** connection
3. Name it: `azure-tfm-sc`
4. Grant necessary permissions

#### Create Variable Group

1. Go to **Pipelines** → **Library** → **Variable groups**
2. Create group: `dev-secrets`
3. Add secret variable: `VM_PASS` (your VM admin password)
4. Allow pipelines to access this group

#### Configure Agent Pool

If using self-hosted agents:
1. Go to **Project Settings** → **Agent pools**
2. Create or use existing pool named `Default`
3. Add agent machines as needed

## Secrets Management

Sensitive data (admin passwords) are handled securely:

- **Local Development**: Use environment variables
  ```bash
  export TF_VAR_admin_password="YourPassword"
  terraform plan
  ```

- **Azure Pipelines**: Use variable groups with secrets
  - Stored in Azure DevOps secure storage
  - Injected into pipeline environment
  - Masked in logs automatically

**Never commit secrets to version control!**

## Useful Commands

### View Infrastructure State

```bash
cd az-vm-tfm

# Show all resources
terraform state list

# Show specific resource details
terraform state show azurerm_virtual_machine.vm

# Display output values
terraform output
```

### Display Resource Groups

```bash
# Using provided script
bash scripts/rg-display.sh

# Or directly with Azure CLI
az group list --query '[].name' -o table
```

### Clean Up Local State

```bash
cd az-vm-tfm

# Remove local state files (use pipeline for remote cleanup)
rm -rf .terraform/
rm terraform.tfstate*
```

## Troubleshooting

### Common Issues

**Authentication Errors**
```bash
# Re-authenticate with Azure
az login
az account show
```

**Backend State Lock**
```bash
# If locked, force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

**Pipeline Service Connection Issues**
- Verify service connection exists in project settings
- Check Azure subscription access
- Ensure variable group `dev-secrets` is accessible

**VM Access Issues**
```bash
# Get VM public IP
terraform output

# SSH into VM
ssh azureuser@<public_ip>
```

## Branching Strategy

- **`main`**: Production-ready code
- **`dev`**: Development and testing
- Feature branches for new changes

Pipelines are triggered manually to ensure controlled deployments.

## Cost Optimization

The configuration uses cost-effective resources:
- **VM Size**: `Standard_B1s` (burstable, low-cost)
- **Storage**: Managed disks only
- **Network**: Basic configuration, minimal charges

To estimate costs, use [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/).

## Security Considerations

- Network Security Group restricts access to SSH only
- Admin credentials passed as secrets (not hardcoded)
- Terraform state stored remotely with encryption
- Use strong passwords (min 12 chars, mixed case, numbers, symbols)

## Contributing

1. Create a feature branch
2. Make changes with descriptive commit messages
3. Test locally with `terraform plan`
4. Submit pull request for review
5. Merge to `main` after approval

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues or questions:
1. Check the Troubleshooting section
2. Review [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
3. Check [Azure CLI Documentation](https://learn.microsoft.com/cli/azure/)
4. Open an issue in this repository
