# Full-Stack DevOps CI/CD Pipeline on AWS 

##  Project Overview
A fully automated CI/CD pipeline that provisions a secure AWS cloud infrastructure from scratch using **Terraform**, configures instances via **Ansible**, and deploys a Node.js application seamlessly using **Jenkins**. 

This project demonstrates a real-world, enterprise-level architecture by deploying the application in a **Private Subnet** and securely managing it through a **Bastion Host**, ensuring maximum security and high availability.

## Architecture & Networking
The infrastructure is completely built as code (IaC) and includes:
* **VPC:** Custom Virtual Private Cloud.
* **Public Subnets:** Hosting the **Bastion Host** and **NAT Gateway**.
* **Private Subnets:** Hosting the **Application Server (EC2)**, **MySQL Database (RDS)**, and **Redis (ElastiCache)**.
* **Security Groups:** Strict firewall rules allowing SSH access *only* through the Bastion Host and application access *only* from defined sources.

##  Tech Stack
* **Cloud Provider:** AWS (VPC, EC2, RDS, ElastiCache, NAT Gateway, EIP)
* **Infrastructure as Code (IaC):** Terraform
* **Configuration Management:** Ansible
* **CI/CD:** Jenkins
* **Application:** Node.js, Express
* **Process Manager:** PM2

## ⚙️ CI/CD Pipeline Flow (Jenkinsfile)
The Jenkins pipeline automatically executes the following stages:
1. **Checkout Code:** Retrieves the latest application and infrastructure code from GitHub.
2. **Terraform Init & Plan:** Initializes the working directory and generates an execution plan.
3. **Terraform Apply:** Provisions the complete AWS infrastructure and dynamically generates an `inventory.ini` file containing the new server IPs.
4. **Deploy Application (Ansible):** * Connects to the isolated Private EC2 via the Bastion Host using custom SSH `ProxyCommand` and local port forwarding.
   * Completely purges old dependencies and installs **Node.js 18** securely.
   * Pulls the latest app code and installs npm packages.
   * Injects dynamic Environment Variables (`DB_HOST`, `REDIS_HOST`, `PORT`) into the application.
   * Restarts the application using **PM2** to ensure zero downtime.

##  Key Challenges Overcome
* **Secure Private Subnet Access:** Configured a custom `ssh_config` inside the Jenkins pipeline to transparently route Ansible SSH traffic through the Bastion Host using `ProxyCommand ssh -W %h:%p`.
* **SSH Timeout & Stability:** Added `ServerAliveInterval` and `ConnectTimeout` to maintain stable connections during heavy resource-intensive tasks (like package installations).
* **Version Conflicts (Node.js):** Solved `MODULE_NOT_FOUND` and package conflicts by creating an Ansible task that completely purges legacy OS packages (`libnode-dev`) before cleanly installing NodeSource repositories.

## Future Enhancements (Roadmap)
* [ ] **Dockerization:** Containerize the Node.js application and Redis to simplify deployments and ensure environment consistency.


## How to Use
1. Clone the repository.
2. Configure your AWS credentials in Jenkins (`aws-access-key`, `aws-secret-key`, `my-aws-key` PEM file).
3. Trigger the Jenkins pipeline, select the target environment (`prod` or `dev`), and choose the `apply` action.
4. Access the application securely via Local Port Forwarding from your local machine to the private instance.



