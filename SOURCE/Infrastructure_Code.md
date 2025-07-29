# Job Seeker Companion - Infrastructure as Code

## Complete AWS Infrastructure (Terraform)

### Project Structure
```
infrastructure/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
├── modules/
│   ├── networking/
│   ├── compute/
│   ├── database/
│   ├── cache/
│   └── monitoring/
└── scripts/
    ├── deploy.sh
    └── migrate.sh
```

### Main Terraform Configuration

```hcl
# main.tf - Production Environment
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "jobseeker-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "JobSeekerCompanion"
      ManagedBy   = "Terraform"
    }
  }
}

# VPC and Networking
module "networking" {
  source = "../../modules/networking"
  
  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
}

# ECS Cluster and Services
module "compute" {
  source = "../../modules/compute"
  
  environment = var.environment
  vpc_id      = module.networking.vpc_id
  
  private_subnet_ids = module.networking.private_subnet_ids
  alb_target_group_arn = module.networking.alb_target_group_arn
  
  # Container configuration
  api_image_tag = var.api_image_tag
  api_cpu       = var.api_cpu
  api_memory    = var.api_memory
  
  # Auto-scaling
  min_capacity = var.min_capacity
  max_capacity = var.max_capacity
  
  # Secrets
  database_url_secret_arn = module.database.connection_secret_arn
  redis_url_secret_arn    = module.cache.connection_secret_arn
}

# RDS PostgreSQL
module "database" {
  source = "../../modules/database"
  
  environment = var.environment
  
  subnet_ids = module.networking.database_subnet_ids
  vpc_security_group_ids = [module.networking.database_security_group_id]
  
  instance_class = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  
  multi_az = var.environment == "prod" ? true : false
  backup_retention_period = var.environment == "prod" ? 30 : 7
  
  # Read replicas
  read_replica_count = var.environment == "prod" ? 2 : 0
}

# ElastiCache Redis
module "cache" {
  source = "../../modules/cache"
  
  environment = var.environment
  
  subnet_ids = module.networking.private_subnet_ids
  security_group_ids = [module.networking.redis_security_group_id]
  
  node_type = var.redis_node_type
  cluster_mode_enabled = var.environment == "prod" ? true : false
}

# Monitoring and Alerts
module "monitoring" {
  source = "../../modules/monitoring"
  
  environment = var.environment
  
  ecs_cluster_name = module.compute.cluster_name
  rds_instance_id  = module.database.instance_id
  redis_cluster_id = module.cache.cluster_id
  
  alert_email = var.alert_email
}
```

### Networking Module

```hcl
# modules/networking/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "jobseeker-${var.environment}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "jobseeker-${var.environment}-igw"
  }
}

# NAT Gateways (one per AZ for high availability)
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"
  
  tags = {
    Name = "jobseeker-${var.environment}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count = length(var.availability_zones)
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "jobseeker-${var.environment}-nat-${count.index + 1}"
  }
}

# Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "jobseeker-${var.environment}-public-${count.index + 1}"
    Type = "public"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "jobseeker-${var.environment}-private-${count.index + 1}"
    Type = "private"
  }
}

resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "jobseeker-${var.environment}-database-${count.index + 1}"
    Type = "database"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "jobseeker-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  
  enable_deletion_protection = var.environment == "prod" ? true : false
  enable_http2              = true
  
  tags = {
    Name = "jobseeker-${var.environment}-alb"
  }
}

# Security Groups
resource "aws_security_group" "alb" {
  name_prefix = "jobseeker-alb-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  lifecycle {
    create_before_destroy = true
  }
}
```

### ECS Module

```hcl
# modules/compute/main.tf
resource "aws_ecs_cluster" "main" {
  name = "jobseeker-${var.environment}"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      
      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs.name
      }
    }
  }
}

# Task Definition
resource "aws_ecs_task_definition" "api" {
  family                   = "jobseeker-api-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.api_cpu
  memory                   = var.api_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn           = aws_iam_role.ecs_task.arn
  
  container_definitions = jsonencode([
    {
      name  = "api"
      image = "jobseeker/api:${var.api_image_tag}"
      
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "PORT"
          value = "3000"
        }
      ]
      
      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = var.database_url_secret_arn
        },
        {
          name      = "REDIS_URL"
          valueFrom = var.redis_url_secret_arn
        }
      ]
      
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.api.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "api"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "api" {
  name            = "jobseeker-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.min_capacity
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "api"
    container_port   = 3000
  }
  
  deployment_configuration {
    minimum_healthy_percent = 100
    maximum_percent         = 200
    
    deployment_circuit_breaker {
      enable   = true
      rollback = true
    }
  }
  
  lifecycle {
    ignore_changes = [desired_count]
  }
}

# Auto Scaling
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "jobseeker-api-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_policy" "memory" {
  name               = "jobseeker-api-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}
```

### Database Module

```hcl
# modules/database/main.tf
resource "random_password" "db" {
  length  = 32
  special = true
}

resource "aws_db_subnet_group" "main" {
  name       = "jobseeker-${var.environment}"
  subnet_ids = var.subnet_ids
  
  tags = {
    Name = "jobseeker-${var.environment}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier = "jobseeker-${var.environment}"
  
  engine         = "postgres"
  engine_version = "15.3"
  instance_class = var.instance_class
  
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2
  storage_encrypted     = true
  storage_type          = "gp3"
  
  db_name  = "jobseeker"
  username = "jobseeker_admin"
  password = random_password.db.result
  
  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  multi_az               = var.multi_az
  publicly_accessible    = false
  deletion_protection    = var.environment == "prod"
  
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  
  enabled_cloudwatch_logs_exports = ["postgresql"]
  
  tags = {
    Name = "jobseeker-${var.environment}-db"
  }
}

# Read Replicas
resource "aws_db_instance" "replica" {
  count = var.read_replica_count
  
  identifier          = "jobseeker-${var.environment}-replica-${count.index + 1}"
  replicate_source_db = aws_db_instance.main.identifier
  
  instance_class = var.replica_instance_class != "" ? var.replica_instance_class : var.instance_class
  
  publicly_accessible = false
  auto_minor_version_upgrade = false
  
  performance_insights_enabled = true
  
  tags = {
    Name = "jobseeker-${var.environment}-db-replica-${count.index + 1}"
  }
}

# Secrets Manager for connection string
resource "aws_secretsmanager_secret" "db_connection" {
  name = "jobseeker-${var.environment}-db-connection"
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "db_connection" {
  secret_id = aws_secretsmanager_secret.db_connection.id
  
  secret_string = jsonencode({
    url = "postgresql://${aws_db_instance.main.username}:${random_password.db.result}@${aws_db_instance.main.endpoint}/${aws_db_instance.main.db_name}"
    host = aws_db_instance.main.address
    port = aws_db_instance.main.port
    database = aws_db_instance.main.db_name
    username = aws_db_instance.main.username
    password = random_password.db.result
  })
}
```

### Kubernetes Migration Configuration

```yaml
# kubernetes/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jobseeker-api
  labels:
    app: jobseeker-api
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: jobseeker-api
  template:
    metadata:
      labels:
        app: jobseeker-api
        version: v1
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - jobseeker-api
              topologyKey: kubernetes.io/hostname
      containers:
      - name: api
        image: jobseeker/api:latest
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: NODE_ENV
          valueFrom:
            configMapKeyRef:
              name: jobseeker-config
              key: environment
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: jobseeker-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: jobseeker-secrets
              key: redis-url
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]
```

### CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: jobseeker-api

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Use Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - run: npm ci
      - run: npm test
      - run: npm run lint
      
  build-and-deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
      
      - name: Build, tag, and push image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG -t $ECR_REGISTRY/$ECR_REPOSITORY:latest .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
      
      - name: Update ECS service
        run: |
          aws ecs update-service \
            --cluster jobseeker-prod \
            --service jobseeker-api \
            --force-new-deployment
      
      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster jobseeker-prod \
            --services jobseeker-api
```

### Migration Scripts

```bash
#!/bin/bash
# scripts/migrate-to-datacenter.sh

set -e

ENVIRONMENT=$1
PHASE=$2

if [ -z "$ENVIRONMENT" ] || [ -z "$PHASE" ]; then
  echo "Usage: ./migrate-to-datacenter.sh <environment> <phase>"
  echo "Phases: prepare, replicate, switchover, complete"
  exit 1
fi

case $PHASE in
  prepare)
    echo "Preparing data center infrastructure..."
    
    # Deploy Kubernetes cluster
    ansible-playbook -i inventory/datacenter kubernetes-setup.yml
    
    # Install monitoring stack
    kubectl apply -f kubernetes/monitoring/
    
    # Set up database servers
    ansible-playbook -i inventory/datacenter postgres-setup.yml
    ;;
    
  replicate)
    echo "Setting up data replication..."
    
    # Configure PostgreSQL streaming replication
    psql -h $AWS_RDS_ENDPOINT -U admin -c "CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD '$REPL_PASSWORD';"
    
    # Start replication on data center servers
    ssh postgres-dc1 "pg_basebackup -h $AWS_RDS_ENDPOINT -D /var/lib/postgresql/data -U replicator -W -P -R"
    
    # Monitor replication lag
    watch -n 5 "psql -h postgres-dc1 -U postgres -c 'SELECT now() - pg_last_xact_replay_timestamp() AS replication_lag;'"
    ;;
    
  switchover)
    echo "Switching traffic to data center..."
    
    # Update DNS to point to data center load balancer
    aws route53 change-resource-record-sets \
      --hosted-zone-id $ZONE_ID \
      --change-batch file://dns-switchover.json
    
    # Scale down AWS services
    aws ecs update-service --cluster jobseeker-$ENVIRONMENT --service jobseeker-api --desired-count 1
    ;;
    
  complete)
    echo "Completing migration..."
    
    # Promote data center database to primary
    ssh postgres-dc1 "touch /tmp/postgresql.trigger"
    
    # Update application configuration
    kubectl set env deployment/jobseeker-api DATABASE_URL=$DC_DATABASE_URL
    
    # Terminate AWS resources (after verification)
    read -p "Terminate AWS resources? (yes/no) " -n 3 -r
    if [[ $REPLY =~ ^yes$ ]]; then
      terraform destroy -auto-approve
    fi
    ;;
esac
```

## Key Takeaways

1. **Cloud-Agnostic Design**: Using containers and standard tools (PostgreSQL, Redis) ensures easy migration
2. **Infrastructure as Code**: Everything is version-controlled and reproducible
3. **Gradual Migration**: No service interruption during the transition
4. **Cost Optimization**: Save ~35% at scale by moving to data center
5. **Maintain Flexibility**: Keep AWS for burst capacity and disaster recovery 