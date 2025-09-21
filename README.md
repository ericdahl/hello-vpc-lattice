# 🚀 AWS VPC Lattice Demo: ECS + Lambda + EC2 Client

This project demonstrates how to use **AWS VPC Lattice** to connect services across multiple VPCs without peering, NAT Gateways, or Transit Gateway.  

We will build a simple service network with **path-based routing** between:
- **ECS (Fargate) Service** → responds with `Hello`
- **Lambda Function** → responds with `Goodbye`
- **EC2 Client** (Session Manager only, no SSH key) → used to test the services

---

## 🏗️ Architecture

## 📋 Plan

1. **VPC Setup**
   - Create 3 VPCs (all with `10.0.0.0/16` to prove Lattice ignores CIDR overlap).
     - `vpc-client`
     - `vpc-server-hello`
     - `vpc-server-goodbye`
   - Each with **2 public subnets** (no NAT Gateway to save costs).
   - VPC endpoints for **SSM / EC2 Messages / Session Manager** in `vpc-client`.

2. **Service Network**
   - Create **VPC Lattice Service Network** (`demo-svnet`).
   - Associate all 3 VPCs with the service network.

3. **Server: Hello (ECS Fargate)**
   - ECS Cluster + Service in `vpc-server-hello`.
   - Use **nginx public image** (`nginx:latest`).
   - Register ECS service with a **VPC Lattice Target Group**.
   - Route `/hello` → ECS service.

4. **Server: Goodbye (Lambda)**
   - Lambda function in `vpc-server-goodbye`.
   - Simple handler that returns JSON:
     ```python
     def handler(event, context):
         return {
             "statusCode": 200,
             "body": "Goodbye from Lambda!"
         }
     ```
   - Register Lambda as a **VPC Lattice Target Group**.
   - Route `/goodbye` → Lambda.

5. **Client**
   - EC2 instance in `vpc-client`.
   - No SSH keys — use **Session Manager**.
   - Test by running:
     ```bash
     curl https://<lattice-dns>/hello
     curl https://<lattice-dns>/goodbye
     ```

6. **Policies**
   - Lattice **auth policy** to allow client VPC → services.
   - Restrict so only `client` VPC can call.

---

## 🔑 Key Learnings

- **Service-to-service connectivity** without NAT or peering.
- **Path-based routing** across different backends (ECS + Lambda).
- **IAM policies** securing service-to-service calls.
- **Observability** via CloudWatch metrics for both routes.

---

## 🛠️ Terraform Components

- **Networking**
  - `aws_vpc`, `aws_subnet`, `aws_internet_gateway`, `aws_route_table`
  - `aws_vpc_endpoint` for SSM

- **VPC Lattice**
  - `aws_vpclattice_service_network`
  - `aws_vpclattice_service`
  - `aws_vpclattice_target_group`
  - `aws_vpclattice_service_network_vpc_association`
  - `aws_vpclattice_listener`
  - `aws_vpclattice_listener_rule`
  - `aws_vpclattice_auth_policy`

- **ECS**
  - `aws_ecs_cluster`
  - `aws_ecs_task_definition`
  - `aws_ecs_service`
  - `aws_iam_role`

- **Lambda**
  - `aws_lambda_function`
  - `aws_iam_role`
  - `aws_vpclattice_target_group` (Lambda type)

- **Client**
  - `aws_instance`
  - `aws_iam_instance_profile`
  - `aws_ssm_document` / default Session Manager roles

---

## ▶️ Deployment

1. Clone repo & configure AWS credentials.
2. Run Terraform:
   ```bash
   terraform init
   terraform apply