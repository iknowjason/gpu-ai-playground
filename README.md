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

***

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
