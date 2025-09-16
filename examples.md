# Example Images

### Accessing n8n
The n8n web application is accessed through a Caddy reverse https proxy listening on port 443.  See terraform output for information on your endpoint.  
![n8n](images/ss1.png "n8n")

### Open WebUI
The Open WebUI console is accessed with http on port 8443.  The following image shows a chat window with the Foundation-sec-8b-instrut model.  It is nice to manage 8b parameter models under your control for private LLM inference R&D.  See terraform output for information on your endpoint.  
![Open WebUI](images/ss2.png "Open WebUI")

### Pytorch FastAPI Inference Endpoint script 
This image shows running a remote bash script against the Pytorch FastAPI server using an OpenAI API compatible request.  The remote inference API is exposed on port 9443.  The Caddy proxy re-directs traffic to TCP port 9000.
![pytorch](images/ss3.png "pytorch")

### Open WebUI Inference Endpoint API
This image shows running a remote bash script against the Open WebUI API server using an OpenAI API compatible request.  The remote inference API is exposed on port 8443.  The Open WebUI has API key management in the console.  You first need to add a new API key and paste the value into the script.
![Open WebUI API](images/ss4.png "Open WebUI ApI")




