# GPU AI Playground

## Overview

GPU AI Playground is a Terraform-based lab environment designed to easily deploy a GPU-enabled EC2 instance on AWS for experimenting with AI models and applications. This template sets up all necessary cloud infrastructure (networking, security, storage, compute) and bootstraps the GPU instance with required software (e.g., NVIDIA drivers, Docker, AI frameworks) via a user-data script. The goal is to provide a ready-to-use "playground" for running generative AI workloads with minimal manual setup.  It's designed to bootstrap a server with all the necessary components to run local Large Language Models (LLMs), including the container runtime, NVIDIA drivers, private inference server with endpoints, and a pre-loaded Cyber Security language model.

The environment automatically deploys the [n8n Self-Hosted AI Starter Kit](https://github.com/iknowjason/self-hosted-ai-starter-kit) integated with Cisco's [Foundation-Sec-8B-Instruct](https://huggingface.co/fdtn-ai/Foundation-Sec-8B-Instruct), an open-weight, 8-billion parameter instruction-tuned language model specialized for cybersecurity applications.

* **GPU-Accelerated EC2 Instance**: An Ubuntu 22.04 server ready for AI workloads.
* **NVIDIA & Docker Stack**: Installs NVIDIA drivers, the NVIDIA Container Toolkit, and configures Docker to leverage the GPU.
* **Multiple Inference Endpoints**:
    * **Ollama**: Manages and serves the LLM.
    * **Open WebUI**: Provides a user-friendly, ChatGPT-like interface for interacting with the model.
    * **PyTorch/FastAPI Server**: A native Python-based inference API for high-performance programmatic access.
* **Pre-loaded Quantized AI Cyber Security Model**: Automatically downloads and configures the `Mungert/Foundation-Sec-8B-Instruct-GGUF` model from Hugging Face.
* **Automated HTTPS**: Caddy is used as a reverse proxy to provide secure HTTPS access to the web interfaces.

## About
This repository automates the provisioning of an AWS GPU environment suitable for AI development and testing. Using Terraform, it creates an isolated AWS lab including a GPU EC2 instance (with an NVIDIA GPU), networking components, and any supporting resources. On launch, the instance is auto-configured (via cloud-init user-data) with GPU drivers, workflow tools (n8n), and an AI management (Ollama, Open WebUI). The GPU AI Playground is ideal for those who want to quickly spin up a personal AI sandbox in the cloud without manually installing CUDA, frameworks, and tooling.

## Estimated Cost
**Disclaimer:** Deploying this playground will incur AWS charges on your account. The primary cost is the GPU EC2 instance, which on-demand can be roughly $0.50–$0.70 per hour (depending on instance type and region). For example, a g4dn.xlarge is about $0.526 per hour in US East (Ohio) region
instances.vantage.sh
 (approximately $380 per month if run 24/7). Storage costs for the 100 GB volume are minor in comparison (around $10 per month for gp2/gp3 at $0.10 per GB-month
github.com
). There is also a small cost for the S3 bucket if large files are stored (few cents per GB-month) and data transfer fees if downloading big models from S3.

To manage costs:

Run the environment only when needed. Use terraform destroy to tear it down when not in use, and spin it up again later (note that any data on the instance will be lost unless you save it externally).

Consider using a smaller or cheaper instance if appropriate. AWS offers newer GPU instance types (like g5) or spot instances at lower prices (spot can be 50-70% cheaper
instances.vantage.sh
 but can be interrupted).

Monitor your AWS billing dashboard. Terraform outputs the instance ID and other info; you can use AWS Cost Explorer to see running costs in near-real time
github.com
.

For a precise estimate tailored to your region and usage, use the AWS Pricing Calculator
github.com
 – input the EC2 instance type, EBS volume size, and duration you expect to run the lab to calculate the cost. Always remember to shut down the environment to stop charges.

## Requirements and Setup

**Prerequisites:**

* An **AWS Account** with programmatic access keys configured.
* **Terraform** (`~>1.5`) installed on your local machine.
* **AWS CLI** installed and configured with your credentials.

***

## Build and Destroy Resources

### 1. Clone the repository
```bash
git clone [https://github.com/iknowjason/gpu-ai-playground.git](https://github.com/iknowjason/gpu-ai-playground.git)
cd gpu-ai-playground
