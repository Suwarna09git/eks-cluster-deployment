# AWS EKS Cluster Deployment using Terraform

> Infrastructure as Code project to provision an Amazon EKS cluster on AWS using Terraform, with IAM configuration and Jenkins CI/CD integration.

---

## Project Overview

This project automates the deployment of an **Amazon Elastic Kubernetes Service (EKS)** cluster on AWS using **Terraform**.

The infrastructure is defined as code, making it easier to create, manage, reproduce, and destroy the Kubernetes infrastructure consistently.

The project also includes a **Jenkinsfile** for integrating Terraform with a CI/CD pipeline.

---

## Architecture

```text
                    Developer
                        |
                        v
                    GitHub
                        |
                        v
                    Jenkins
                        |
                        v
                 Terraform Pipeline
                        |
                        v
                +---------------+
                |      AWS      |
                |               |
                |      EKS      |
                |    Cluster    |
                |               |
                +---------------+
                        |
                        v
                  Kubernetes
                    Workloads
