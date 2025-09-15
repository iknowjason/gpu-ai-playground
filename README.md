# GPU AI Playground

## Overview

This repository provides a Terraform template to rapidly deploy a complete, GPU-powered AI environment in AWS. It's designed to bootstrap a server with all the necessary components to run local Large Language Models (LLMs), including the container runtime, NVIDIA drivers, inference servers, and a pre-loaded Cyber Security .

The environment automatically deploys the [n8n Self-Hosted AI Starter Kit](https://github.com/iknowjason/self-hosted-ai-starter-kit) and Cisco's [Foundation-Sec-8B-Instruct](https://huggingface.co/fdtn-ai/Foundation-Sec-8B-Instruct), an open-weight, 8-billion parameter instruction-tuned language model specialized for cybersecurity applications.

* **GPU-Accelerated EC2 Instance**: A powerful Ubuntu 22.04 server ready for AI workloads.
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
