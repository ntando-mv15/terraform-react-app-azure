# Deploy React App on Azure VM with Terraform

A hands-on Infrastructure as Code (IaC) project that provisions an Azure Ubuntu Virtual Machine using Terraform and deploys a React application served over HTTP.

---

## Table of Contents

- [Deploy React App on Azure VM with Terraform](#deploy-react-app-on-azure-vm-with-terraform)
  - [Table of Contents](#table-of-contents)
  - [Project Overview](#project-overview)
  - [Architecture](#architecture)
  - [Prerequisites](#prerequisites)
  - [Project Structure](#project-structure)
  - [Infrastructure Provisioned](#infrastructure-provisioned)
  - [Step-by-Step Deployment Guide](#step-by-step-deployment-guide)
    - [Step 1: Clone This Repo](#step-1-clone-this-repo)
    - [Step 2: Authenticate with Azure](#step-2-authenticate-with-azure)
    - [Step 3: Initialize Terraform](#step-3-initialize-terraform)
    - [Step 4: Plan and Apply](#step-4-plan-and-apply)
    - [Step 5: SSH into the VM](#step-5-ssh-into-the-vm)
    - [Step 6: Install Dependencies](#step-6-install-dependencies)
    - [Step 7: Clone and Build the React App](#step-7-clone-and-build-the-react-app)
    - [Step 8: Serve the App on Port 80](#step-8-serve-the-app-on-port-80)
    - [Step 9: Test the Deployment](#step-9-test-the-deployment)
  - [Clean Up Resources](#clean-up-resources)
  - [Key Learnings](#key-learnings)

---

## Project Overview

This project demonstrates how to:

- Use **Terraform** to provision cloud infrastructure on **Microsoft Azure**
- Configure networking (VNet, Subnet, NSG, Public IP, NIC) programmatically
- Deploy an **Ubuntu 20.04 VM** and connect via SSH
- Install **Node.js, npm, and Git** on a fresh Linux server
- Clone, build, and serve a **React application** from the VM

> 🔗 React App Source: [pravinmishraaws/my-react-app](https://github.com/pravinmishraaws/my-react-app)

---

## Architecture

```
Internet
    │
    ▼
┌─────────────────────────────────────────┐
│           Azure Resource Group          │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │        Virtual Network          │    │
│  │   (10.0.0.0/16)                 │    │
│  │                                 │    │
│  │  ┌──────────────────────────┐   │    │
│  │  │         Subnet           │   │    │
│  │  │      (10.0.2.0/24)       │   │    │
│  │  │                          │   │    │
│  │  │  ┌────────────────────┐  │   │    │
│  │  │  │   Ubuntu 20.04 VM  │  │   │    │
│  │  │  │                    │  │   │    │
│  │  │  │                    │  │   │    │
│  │  │  │  React App :80     │  │   │    │
│  │  │  │  SSH       :22     │  │   │    │
│  │  │  └────────────────────┘  │   │    │
│  │  └──────────────────────────┘   │    │
│  └─────────────────────────────────┘    │
│                                         │
│  NSG: Allow 22 (SSH) + 80 (HTTP)        │
│  Public IP ──► NIC ──► VM               │
└─────────────────────────────────────────┘
```

---

## Prerequisites

Before you begin, make sure you have the following installed and configured:

1. Terraform >= 1.3.0 
2. Azure CLI >= 2.40.0 
3. An Azure Account

---

## Project Structure

```
terraform-react-azure/
├── public/               
├── src/                  # React app source code (components, styles, JS)
├── terraform/
│   └── main.tf           # Terraform config — provisions all Azure infrastructure
├── .gitignore            # Excludes node_modules, Terraform state files, and secrets
├── package-lock.json     
├── package.json          
└── README.md             # Project documentation and deployment guide
```

---

## Infrastructure Provisioned

The `main.tf` file provisions the following Azure resources:

| Resource | Name in Azure | Terraform Resource |
|----------|--------------|-------------------|
| Resource Group | `reactapp_rg` | `azurerm_resource_group.app_rg` |
| Virtual Network | `reactapp_vnet` | `azurerm_virtual_network.app_vnet` |
| Subnet | `internal` (10.0.2.0/24) | `azurerm_subnet.internal` |
| Network Security Group | `allowHTTPandSSH` | `azurerm_network_security_group.web_sg` |
| Public IP Address | `appvm_ip` | `azurerm_public_ip.app_ip` |
| Network Interface | `reactapp_nic` | `azurerm_network_interface.vm_nic` |
| NIC ↔ NSG Association | — | `azurerm_network_interface_security_group_association.nic_nsg` |
| Virtual Machine | `reactapp-vm` | `azurerm_virtual_machine.app_vm` |

**VM Specs:**
- OS: Ubuntu Server 22.04 LTS (Jammy)
- Size: `Standard_D2ls_v5`
- Admin user: `azureadmin`
- Auth: Password-based

---

## Step-by-Step Deployment Guide

### Step 1: Clone This Repo

```bash
git clone https://github.com/ntando-mv15/terraform-react-app-azure.git
cd terraform-react-app-azure
```

### Step 2: Authenticate with Azure

Log in to your Azure account via the CLI:

```bash
az login
```

A browser window will open. Sign in with your Azure credentials. Once authenticated, confirm your active subscription:

```bash
az account show
```

If you have multiple subscriptions, set the correct one:

```bash
az account set --subscription "<your-subscription-id>"
```

### Step 3: Initialize Terraform

Download the Azure provider plugin and set up the working directory:

```bash
terraform init
```

You should see:

```
Terraform has been successfully initialized!
```

### Step 4: Plan and Apply

Preview the infrastructure changes before creating anything:

```bash
terraform plan
```

Review the output — it will list every resource Terraform will create. When you're ready, apply:

```bash
terraform apply
```

Type `yes` when prompted to confirm. Provisioning typically takes **2–5 minutes**.

At the end, Terraform will output your VM's **Public IP address**. Copy it — you'll need it in the next steps.

### Step 5: SSH into the VM

```bash
ssh azureuser@<public-ip>
```

Replace `<public-ip>` with the IP address from the Terraform output. Accept the fingerprint prompt on first connection.

> 💡 **Tip:** If you used an SSH key pair, make sure your private key is in `~/.ssh/` or specify it with `-i ~/.ssh/id_rsa`.

### Step 6: Install Dependencies

Once inside the VM, update the system and install the required tools:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install nodejs npm git -y
```

Verify the installations:

```bash
node -v
npm -v
git --version
```

> ⚠️ **Note:** The version of Node.js from the default Ubuntu apt repo may be outdated. If the React build fails, install a newer version using [NodeSource](https://github.com/nodesource/distributions):
>
> ```bash
> curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
> sudo apt install -y nodejs
> ```

### Step 7: Clone and Build the React App

```bash
git clone https://github.com/pravinmishraaws/my-react-app.git
cd my-react-app
npm install
npm run build
```

The `build/` folder now contains the static production files.

### Step 8: Serve the App on Port 80

Install a lightweight static file server and serve the build output on port 80:

```bash
sudo npm install -g serve
sudo serve -s build -l 80
```

> Alternatively, use `npx serve -s build -l 80` without a global install.

To keep the app running after you disconnect your SSH session, use `pm2`:

```bash
sudo npm install -g pm2
sudo pm2 serve build 80 --spa
sudo pm2 startup
sudo pm2 save
```

### Step 9: Test the Deployment

Open a browser and navigate to:

```
http://<your-vm-public-ip>
```

You should see the React application homepage. Test navigation across the app to confirm it is fully functional.

---

## Clean Up Resources

To avoid ongoing Azure charges, destroy all provisioned infrastructure when you're done:

```bash
terraform destroy
```

Type `yes` to confirm. This will delete the resource group and everything inside it.


---

## Key Learnings

- **Terraform** declaratively manages cloud infrastructure, making environments reproducible and version-controlled
- **Azure NSGs** act as virtual firewalls — only explicitly allowed ports are reachable
- **`terraform plan`** is a dry-run that prevents surprises; always review before applying
- **`terraform destroy`** cleanly removes all provisioned resources, avoiding cloud bill surprises
- A React app's production output is a folder of static files that any static file server can serve
- Running a process in the background with **pm2** keeps your app alive after SSH disconnects

---

