# GPU AI Playground

## Overview

GPU AI Playground is a Terraform-based lab environment designed to easily deploy a NVIDIA GPU-enabled EC2 instance on AWS for experimenting with AI models and applications. I've been using it in research for my own Cyber Security use cases but it can be used for any LLM self-hosting inference lab purpose you can imagine.  This template sets up all necessary cloud infrastructure and bootstraps the GPU instance with required software (i.e., NVIDIA drivers, Docker, AI frameworks) via a user-data script. You can easily adapt it to scale up or down on the GPU instance, and adapt the cloud-init user_data script for any customizations.  On launch, the instance is auto-configured (via cloud-init user-data) with GPU drivers, workflow automation tools (n8n), and AI management frameworks (Ollama, Open WebUI). The GPU AI Playground is ideal for those who want to quickly spin up a personal AI sandbox in the cloud without manually installing CUDA, frameworks, and tooling.  The goal is to provide a ready-to-use "playground" for running generative AI workloads with minimal manual setup.  It's designed to bootstrap a server with all the necessary components to run local Large Language Models (LLMs), including the container runtime, NVIDIA drivers, private inference server with endpoints, and a pre-loaded Cyber Security language model.

The environment automatically deploys the [n8n Self-Hosted AI Starter Kit](https://github.com/iknowjason/self-hosted-ai-starter-kit) integated with Cisco's [Foundation-Sec-8B-Instruct](https://huggingface.co/fdtn-ai/Foundation-Sec-8B-Instruct), an open-weight, 8-billion parameter instruction-tuned language model specialized for cybersecurity applications.

* **GPU-Accelerated EC2 Instance**: An Ubuntu 22.04 server ready for AI workloads.
* **NVIDIA & Docker Stack**: Installs NVIDIA drivers, the NVIDIA Container Toolkit, and configures Docker to leverage the GPU.
* **Multiple Inference Endpoints**:
    * **Ollama**: Manages and serves the LLM.
    * **Open WebUI**: Provides a user-friendly, ChatGPT-like interface for interacting with the model.
    * **PyTorch/FastAPI Server**: A native Python-based inference API for high-performance programmatic access.
* **Pre-loaded Quantized AI Cyber Security Model**: Automatically downloads and configures the `Mungert/Foundation-Sec-8B-Instruct-GGUF` model from Hugging Face.
* **Foundation Instruct Model with Native Pytorch Inference:** Downloads and runs the Foundation-Sec-8B-Instruct model for better inference performance using a FastAPI exposed endpoint.
* **Automated HTTPS**: Caddy is used as a reverse proxy to provide secure HTTPS access to the web interfaces.

## Estimated Cost
**Disclaimer:** Deploying this playground will incur AWS charges on your account. The primary cost is the GPU EC2 instance.  This playground uses Amazon EC2 [G5 instances](https://aws.amazon.com/ec2/instance-types/g5/).  This can be customized in [variables.tf](https://github.com/iknowjason/gpu-ai-playground/blob/main/variables.tf#L11).   The cost of the default ```g5.2xlarge``` instance is $1.212 per hour for On-Demand usage. Based on my research and testing this is the most cost effective and minimal hardware for running a GPU instance with an 8 billion parameter model such as [Cisco's Foundation-Sec-8b-Instruct](https://huggingface.co/fdtn-ai/Foundation-Sec-8B-Instruct) model with both native PyTorch FastAPI inference server as well as Quantized f16 model hosted through Ollama.

**Instance Information:**  Check the AWS Pricing page to confirm the latest pricing.
| Instance Family | Instance Size | Hourly Cost | vCPU | Memory | GPU Memory |
| :------- | :------: | -------: | -------: | -------: | -------: |  
| G5 | G5.2xlarge | $1.212 | 8 | 32 | 24 |


**To manage costs:**

Run the environment only when needed. Use terraform destroy to tear it down when not in use, and spin it up again later (note that any data on the instance will be lost unless you save it externally).

Consider using a smaller or cheaper instance if appropriate. AWS offers GPU instance types or spot instances at lower prices.

Monitor your AWS billing dashboard. Terraform outputs the instance ID and other info; you can use AWS Cost Explorer to see running costs in near-real time.

For a precise estimate tailored to your region and usage, use the AWS Pricing Calculator
 – input the EC2 instance type, EBS volume size, and duration you expect to run the lab to calculate the cost. Always remember to shut down the environment to stop charges.

## Requirements and Setup

## Screen Shots
[Some examples.](examples.md)

## Requirements and Setup

**Tested with:**

* Mac OS 13.4 or Ubuntu 22.04
* terraform 1.5.7
* AWS Service Limits: Ensure your AWS account can launch GPU instances in the chosen region. New accounts may need limit increases for GPU instance types.

**Clone this repository:**
```
git clone https://github.com/iknowjason/gpu-ai-playground
cd gpu-ai-playground
```

**Credentials Setup:**

Generate an IAM programmatic access key that has permissions to build resources in your AWS account.  Setup your .env to load these environment variables.  You can also use the direnv tool to hook into your shell and populate the .envrc.  Should look something like this in your .env or .envrc:

```
export AWS_ACCESS_KEY_ID="VALUE"
export AWS_SECRET_ACCESS_KEY="VALUE"
```

## Build and Destroy Resources

### Run terraform init
Change into the ```gpu-ai-playground``` working directory and type:

```
terraform init
```

### Run terraform plan or apply
```
terraform apply -auto-approve
```
or
```
terraform plan -out=run.plan
terraform apply run.plan
```

### Destroy resources
```
terraform destroy -auto-approve
```

### View terraform created resources
The lab has been created with important terraform outputs showing services, endpoints, IP addresses, and credentials.  To view them:
```
terraform output
```

# Details and Usage

## Accessing the Services

Once the deployment is complete, use the values from the ```terraform output``` command to access the services.

- n8n Admin Console: https://PUBLIC_IP

- Open WebUI Console: http://PUBLIC_IP:8443

- SSH Access: ssh -i ssh_key.pem ubuntu@PUBLIC_IP

## Monitoring the Bootstrap Process

The user_data.sh script handles the entire setup process. You can monitor its progress by SSHing into the instance and tailing the log file. The setup is complete when you see "End of bootstrap script".
```
# SSH into the server first
tail -f /var/log/cloud-init-output.log
```

You can also check the status of the PyTorch FastAPI server to ensure it's running:
```
sudo systemctl status foundation
```
Verify that the PyTorch FastAPI server is listening on port 9000:
```
sudo netstat -tulpn | grep 9000
```

## API Usage and Testing

The bootstrap process creates several test scripts in /home/ubuntu/test_inference_scripts/ on the server. Additionally, api_usage.txt provides instructions for remote testing.

### Remote Testing

### Open WebUI API Testing

Log in to the Open WebUI Console and create an API key in the settings.

Terraform creates a test script for you at ./test-inference-scripts/openwebui.sh. Edit this file and replace the CHANGE_BEFORE_FIRST_USING placeholder with your new API key.

Run the script from your local machine: bash ./test-inference-scripts/openwebui.sh

### PyTorch FastAPI API Testing

The API key is generated randomly during setup. SSH into the server to retrieve it:
```
grep FOUNDATION_API_KEY /home/ubuntu/foundation_server/.env
```
Terraform creates a test script at ./test-inference-scripts/pytorch.sh. Edit this file and replace the CHANGE_BEFORE_FIRST_USING placeholder with the key you just retrieved.

Run the script from your local machine: bash ./test-inference-scripts/pytorch.sh

### Example Terraform Output

After a successful deployment, your output will look similar to this:
```
n8n Admin Console
-------------
https://ec2-44-220-87-247.compute-1.amazonaws.com

Open WebUI Console
------------------
http://ec2-44-220-87-247.compute-1.amazonaws.com:8443

SSH
---
ssh -i ssh_key.pem ubuntu@44.220.87.247

BOOTSTRAP MONITORING
--------------------
1. SSH into the system (command above)
2. Tail the cloudinit logfile (Wait for it to output 'End of bootstrap script')
tail -f /var/log/cloud-init-output.log
3. Check the PyTorch API service (Wait for it to be listening on port 9000)
sudo systemctl status foundation
sudo netstat -tulpn | grep 9000

Remote Inference APIs (see api_usage.txt for how to use them)
------------------------------------------------------------
PyTorch FastAPI:
http://44.220.87.247:9443/generate

Open WebUI:
http://44.220.87.247:8443/api/chat/completions
```


# License
This project is licensed under the MIT License, which allows for reuse and modification with attribution. See the LICENSE file for details. All included third-party tools and libraries maintain their respective licenses. Enjoy your AI playground responsibly!

