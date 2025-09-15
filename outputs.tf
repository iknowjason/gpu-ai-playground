
output "n8n_server_details" {
  value = <<CONFIGURATION
-----------------
GPU Linux Server
-----------------

n8n Admin Console
-------------
https://${aws_instance.n8n_gpu_node.public_dns}

Open WebUI Console
------------------
http://${aws_instance.n8n_gpu_node.public_dns}:8443

SSH
---
ssh -i ssh_key.pem ubuntu@${aws_instance.n8n_gpu_node.public_ip}

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
http://${aws_instance.n8n_gpu_node.public_ip}:9443/generate

Open WebUI:
http://${aws_instance.n8n_gpu_node.public_ip}:8443/api/chat/completions
 
CONFIGURATION
}
