terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Replace with your AWS region
}

# Create the EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  # Optional: Enable Kubernetes version 1.24 or higher
  # version = "1.24" 
  # Optional: Enable cluster logging
  # logging {
  #   cluster_logging {
  #     enabled = true
  #     types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  #   }
  # }
}

# Create an IAM Role for the EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement": [
      {
        "Effect"   : "Allow",
        "Principal": {
          "Service": "eks.amazonaws.com"
        },
        "Action"   : "sts:AssumeRole"
      }
    ]
  })
}

# Attach Policies to the IAM Role for EKS Cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Create the EKS Cluster Security Group
resource "aws_security_group" "eks_cluster_sg" {
  name   = "eks-cluster-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a VPC for the EKS Cluster
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  # Optional: Enable DNS Hostnames and DNS Resolution
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Create a Subnet for the EKS Cluster
resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block         = "10.0.1.0/24"
  availability_zone = "us-east-1a" # Replace with your desired Availability Zone

  # Optional: Configure tags
  # tags = {
  #   Name = "eks-cluster-subnet"
  # }
}

# Create an Internet Gateway for the EKS Cluster
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Attach the Internet Gateway to the VPC
resource "aws_vpc_gateway_attachment" "main" {
  vpc_id            = aws_vpc.main.id
  internet_gateway_id = aws_internet_gateway.main.id
}

# Create a Route Table for the EKS Cluster
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  # Optional: Configure tags
  # tags = {
  #   Name = "eks-cluster-route-table"
  # }
}

# Create a Route for the EKS Cluster
resource "aws_route" "main" {
  route_table_id = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id          = aws_internet_gateway.main.id
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "main" {
  subnet_id       = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Create a Kubernetes Namespace for your application
resource "kubernetes_namespace" "main" {
  metadata {
    name = "my-pos-app"
  }
}

# Create a Kubernetes Service for your application
resource "kubernetes_service" "main" {
  metadata {
    name = "my-pos-app"
    namespace = kubernetes_namespace.main.metadata.0.name
  }
  spec {
    selector = {
      app = "my-pos-app"
    }
    ports {
      port = 80
      target_port = 8000 # The port your application listens on
      protocol = "TCP"
    }
    type = "LoadBalancer"
  }
}

# Create a Kubernetes Deployment for your application
resource "kubernetes_manifest" "main" {
  # Define the deployment configuration
  manifest = {
    "kind" = "Deployment"
    "apiVersion" = "apps/v1"
    "metadata" = {
      "name" = "my-pos-app"
      "namespace" = kubernetes_namespace.main.metadata.0.name
      "labels" = {
        "app" = "my-pos-app"
      }
    }
    "spec" = {
      "replicas" = 3 # Adjust the number of replicas as needed
      "selector" = {
        "matchLabels" = {
          "app" = "my-pos-app"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = "my-pos-app"
          }
        }
        "spec" = {
          "containers" = [
            {
              "name" = "my-pos-app"
              "image" = "my-pos-app:latest" # Replace with your Docker image
              "ports" = [
                {
                  "containerPort" = 8000 # The port your application listens on
                }
              ]
              "resources" = {
                "requests" = {
                  "cpu" = "500m"
                  "memory" = "512Mi"
                }
                # Optional: Set limits for resource usage
                # "limits" = {
                #   "cpu" = "1"
                #   "memory" = "1Gi"
                # }
              }
              # Optional: Add environment variables
              # "env" = [
              #   {
              #     "name" = "DATABASE_URL"
              #     "value" = "postgres://user:password@database-host:5432/database-name"
              #   }
              # ]
            }
          ]
        }
      }
    }
  }
}