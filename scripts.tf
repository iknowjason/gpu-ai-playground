variable "OPENWEB_API_KEY" {
  description = "API key for Open WebUI"
  type        = string
  sensitive   = true
  default     = "CHANGE_BEFORE_FIRST_USING"
}

variable "FOUNDATION_API_KEY" {
  description = "API key for PyTorch Foundation server"
  type        = string
  sensitive   = true
  default     = "CHANGE_BEFORE_FIRST_USING"
}

resource "local_file" "openwebui_test" {
  content = templatefile("${path.module}/files/scripts/openwebui_test.sh.tpl", {
    public_ip       = aws_instance.n8n_gpu_node.public_ip
    OPENWEB_API_KEY = var.OPENWEB_API_KEY
  })
  filename = "${path.module}/test-inference-scripts/openwebui.sh"
}

resource "local_file" "pytorch_test" {
  content = templatefile("${path.module}/files/scripts/pytorch_test.sh.tpl", {
    public_ip          = aws_instance.n8n_gpu_node.public_ip
    FOUNDATION_API_KEY = var.FOUNDATION_API_KEY
  })
  filename = "${path.module}/test-inference-scripts/pytorch.sh"
}
