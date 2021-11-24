# Trento Telemetry Service

This repo holds the source code of the service Trento uses to collect telemetry data.

## Deployment

The project offers a terraform deployment option in order to deploy the __Trento Telemetry Service__.
The deployment project deploys the service on AWS ECS (Elastic Containers Service).

The deployment consists of:
- VPC networking layer including all the needed resources
- Amazon load balancer
- Elastic container service based on Fargate (serverless container service)

### Requirements

- terraform version >=0.13.x installed
- AWS access and secret keys (with ECS, Load balancer, VPC management, etc IAM rights)
- Already deployed InfluxDB database. The service url, organization id, bucket name and api token with write/right access to this bucket are needed

## How to deploy

Follow the next steps to deploy the service:

1. Access the `deployment` folder
2. Create a new `terraform.tfvars` file. Use the [terraform.tfvars.example](deployment/terraform.tfvars.example) as example
3. Run:
```
terraform init
terraform apply
```
4. When the deployment is completed the terraform output shows the `dns_name` which Trento should send the telemetry data

## Development

### Requirements

1. [Docker](https://docs.docker.com/get-docker/)
2. [Docker Compose](https://docs.docker.com/compose/install/)

### Environment configuration

Start the platform infrastructure by running `make start`

It spawns an `influx` instance and a `postgres` instance.

Fill `.env` as needed and Leverage docker compose override features by `cp docker-compose.override.yaml.dist docker-compose.override.yaml` for customization.