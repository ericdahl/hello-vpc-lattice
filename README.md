# hello-vpc-lattice

Basic Hello World demo of AWS VPC Lattice with Terraform:

- ECS Service (Fargate) in "vpc-hello" returning nginx default page
- Lambda Function in "vpc-goodbye" returning "Goodbye"
- VPC Lattice Service "random-service" which forwards traffic to both "hello" and "goodbye" targets
- EC2 test instance in "vpc-client" used to invoke "random-service"

Notes:
- VPCs have no direct interconnectivity (peering, TGW, PrivateLink) and are all using same CIDR


Example:

```
terraform apply

aws ssm start-session --target $INSTANCE_ID

[root@ip-10-0-1-162 ~]# curl https://random-service-0b2ed0d770b3c1f46.7d67968.vpc-lattice-svcs.us-east-1.on.aws/ ; echo
"Goodbye from Lambda!"
[root@ip-10-0-1-162 ~]# curl https://random-service-0b2ed0d770b3c1f46.7d67968.vpc-lattice-svcs.us-east-1.on.aws/ ; echo
"Goodbye from Lambda!"
[root@ip-10-0-1-162 ~]# curl https://random-service-0b2ed0d770b3c1f46.7d67968.vpc-lattice-svcs.us-east-1.on.aws/ ; echo
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```
