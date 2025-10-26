# hello-vpc-lattice

Basic Hello World demo of AWS VPC Lattice with Terraform:

- ECS Service (Fargate) in "vpc-hello" returning nginx default page
- Lambda Function in "vpc-goodbye" returning "Goodbye"
- VPC Lattice Service "random-service" which forwards traffic to both "hello" and "goodbye" targets
- EC2 test instance in "vpc-client" used to invoke "random-service"
    - this one has full access to the Service Network
- EC2 test instance in "vpc-client-untrusted" used to invoke "random-service"
    - only has access to the one Random service, requiring IAM auth
- redis/valkey instance in "vpc-redis" just running an Elasticsearch endpoint
    - this is to demo the Resource Configuration type of VPC Lattice, rather than traditional VPC layer 7 type. Resource Configuration supports TCP directly

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

[root@ip-10-0-1-149 ~]# valkey-cli -h snra-0288f748319cecde5.rcfg-061bb95e7c2d2f44c.4232ccc.vpc-lattice-rsc.us-east-1.on.aws -p 6379 --tls
snra-0288f748319cecde5.rcfg-061bb95e7c2d2f44c.4232ccc.vpc-lattice-rsc.us-east-1.on.aws:6379> ping
PONG
```

IAM Auth for "untrusted" VPC:

```
[root@ip-10-0-1-30 ~]# python3 /home/ec2-user/test.py https://random-service-0ae9f759414f7d7a7.7d67968.vpc-lattice-svcs.us-east-1.on.aws
<!DOCTYPE html>
<html>
...
```

note: custom python script to do SigV4 auth. `awscurl` seems to require body be signed, but Lattice doesn't do that. `curl` native requires more setup

## Notes

- Support for:
    - ECS (EC2 or Fargate)
    - EKS
    - Lambda
- IAM
    - service-to-service lockdown via IAM policies on the Lattice Service is possible, but then requires client to SigV4 sign APIs which would require significant cahnges to legacy codebases
- Internet Ingress not directly supported
    - requires setting up ALB or NLB and forwarding to proxy, e.g., nginx
        - see <https://github.com/aws-solutions-library-samples/guidance-for-external-connectivity-amazon-vpc-lattice>

### Components

- Service Network - top level logical grouping
    - can have security policies
    - can share via RAM to other accounts
- Service Network VPC Association (`aws_vpclattice_service_network_vpc_association`)
    - allows clients within this VPC to access service network
    - optional security groups
    - a VPC can only be _associated_ to one service network
    - results in DNS lookups to Service DNS going to `169.254.171.0/24` or similar
        - VPC route table has these inserted with Target=VpcLattice:
            - `169.254.171.0/24`
            - `129.224.0.0/17`
            - `fd00:ec2:80::/64`
- Service Network VPC Endpoint
    - similar but using standard PrivateLink endpoints
    - enables VPC to connect to one _or more_ service networks
    - anything with network access to VPC Endpoint can use it, e.g., data center with DX
- Lattice Services (`aws_vpclattice_service`)
    - original feature
    - endpoint to connect to
    - protocols supported: HTTP, HTTPS, gRPC, TLS
        - plain TCP _not_ supported
    - Sub-components:
        - Listeners (`aws_vpclattice_listener`)
            - protocol - HTTP, HTTPS or TLS_PASSTHROUGH (_no plain TCP_)
            - port
            - default action - forward or fixed response
        - Routing Rules (`aws_vpclattice_listener_rule`)
            - match/action logic
                - can have multiple rules routing to different TGs
            - match
                - HTTP header/method/path - 
                    - _no support for query parameter_
                    - prefix/contains/exact
            - action
                - fixed response, or forward to TG
                - weight - determines percentage of traffic to one vs other
        - Target Groups (`aws_vpclattice_target_group`)
            - type: IP, Lambda, Instance or ALB
            - health check - HTTP path/timeout/interval
            - port
            - protocol: HTTP or HTTPS
- Lattice VPC Resources
    - newer feature
        - more general than Services. Supports TCP
    - IP Address, DNS target or AWS Managed Resource (e.g., RDS)
    - Sub-components
        - Resource Gateway (`aws_vpclattice_resource_gateway`)
            - Subnets
            - IPv4 addr per ENI (?)
        - Resource Configuration (`aws_vpclattice_resource_configuration`)
            - protocol - TCP only
            - port - can be a range
            - type: Group, Child, Single, Arn
            - Definition - DNS IP or ARN




## TODO

- ECS on EC2 service? cleanup
    - remove capacity provider
    - debug failed HCs for whoami
- more fine grained rules