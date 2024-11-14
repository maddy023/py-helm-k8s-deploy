
# Project Documentation 

This repository hosts a Python-based FastAPI application, designed to be deployed on a Kubernetes (K8s) cluster. The following documentation outlines the steps required to prepare, build, and deploy the application using a CI/CD pipeline.

For detailed information about the pipeline, including multi-job workflows, step-by-step configurations, and requirements, please refer to the following link:  
[Pipeline Documentation](./docs/pipeline.md)


## Repository Structure:
├── src/                  # Application source code
│   └── main.py           
├── tests/                # UnitTest files
│   └── test_main.py      
├── charts/               # Helm deployment
│   ├── templates/        
│   ├── values.yaml       
│   └── Chart.yaml        
├── Dockerfile          
├── docs/                 # Documentations
│   └── pipeline.md       # CI/CD Process
├── .github/workflows/    # GitHub Actions
├── requirements/         # Dependencies
├── Makefile              # Build automation
├── README.md             # Project documentation
└── .gitignore            # Git ignore patterns
└── .dockerignore         # Docker ignore patterns

### Step 1. Setting Up the Python Environment

To begin development, create a virtual environment and install the necessary dependencies for FastAPI:

```bash
# Create a new virtual environment
python3 -m venv venv  
# Activate the virtual environment
source venv/bin/activate  
# Install dependencies` 
pip install fastapi uvicorn requests  
```

After writing the FastAPI application code in `main.py`, you can test the app locally with the command:

```bash
uvicorn main:app --host 0.0.0.0 --port 80` 
```

This command runs the FastAPI server locally, allowing for functionality testing before containerization. Once Code and Requirements are freezed , created req.txt file

```bash
pip freeze > requirements.txt
```

### Step 2. Docker Containerization

After verifying that the app works locally, the next step is to containerize it. We explored two Dockerfile configurations to create an optimized Docker image.

#### Attempt 1: Initial Dockerfile (1.1GB)

The initial Dockerfile was straightforward but resulted in a large image size. This file installed dependencies and ran the FastAPI app:

Dockerfile

Copy code

```dockerfile
FROM python:3.9
WORKDIR /app
COPY ./requirements.txt .
RUN pip install --no-cache-dir --upgrade -r ./requirements.txt
COPY . .
CMD ["fastapi", "run", "main.py", "--port", "80"]
```

#### Attempt 2: Optimized Dockerfile (Under 300MB)

To reduce the image size, a multi-stage build approach was implemented with `python:3.11-slim` as the base image. This configuration reduced the image size significantly by separating the build environment from the runtime environment and only including necessary files and dependencies.

```dockerfile
# Build Stage
FROM python:3.11-slim as build-stage
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libhdf5-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean
COPY ./requirements.txt .
RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt \
    && rm -rf /root/.cache/pip

# Runtime Stage
FROM python:3.11-slim as runtime-stage
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    libhdf5-103 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean
COPY --from=build-stage /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=build-stage /usr/local/bin /usr/local/bin
COPY /src /app
EXPOSE 80
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
```

### Building the Docker Image and Run in Local

To build the Docker image locally, navigate to the directory containing your Dockerfile and use the following command. Replace `your-image-name` with the desired name for the image (e.g., `fastapi-app`):

```bash
docker build -t your-image-name
docker run -p 80:80 your-image-name

# Output
INFO:     Started server process [1]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:80 (Press CTRL+C to quit)
INFO:     192.168.65.1:53508 - "GET / HTTP/1.1" 200 OK
INFO:     Shutting down
```

### Testing the FastAPI Application

To confirm that the application is running as expected, open a web browser or use a tool like `curl` to access the app at `http://localhost:80`:

```bash
curl http://localhost:80
# Output
{"public_ip":"49.37.215.66"}
```

### Step 3: Deploying with Helm Charts

To deploy the FastAPI application on Kubernetes using Helm, follow these steps:

1.  **Create the Helm Chart**: Use Helm to scaffold a new chart:
        
```bash
helm create chart-name
```

 This command generates a new Helm chart directory structure in the `chart-name` folder. Move into the newly created chart folder and configure the application:

2.  **Added `cert.yaml` for Certificate Management**: Create a `cert.yaml` file within the `templates` folder. This file will define the certificate resource using Cert-Manager.
    
3.  **Modify `values.yaml`**: Update `values.yaml` to include configuration values for the certificate. Add a section that allows users to enable or disable certificate creation and customize certificate details: This `enabled` variable gives users control over certificate management.

```yaml
cert:
  enabled: true
```

4. **Test the Helm Template Locally**: Before deploying, test the Helm template rendering locally to ensure configurations are correct. Use the following command to render the templates and output them to `data.yaml`:
    
```bash
helm template release-name ./charts --values values.yaml --set image.tag=v2`
```  
    This command:
    
    -   Renders the chart templates without deploying, using the `values.yaml` file and overridden values for `image.tag` and `image.repository`.

2.    **Deploy with Helm**: Install or upgrade the Helm release for your application. Replace `my-release` with your desired release name:

```bash    
helm upgrade --install my-release ./chart-name -f values.yaml
```

This command will deploy the application along with the configured certificate in the Kubernetes cluster, ensuring it’s properly secured with TLS via Cert-Manager.

### Step 4: Installing Required Helm Chart Dependencies in Cluster

Before deploying the FastAPI application, you’ll need to install the following Helm charts in the target Kubernetes cluster as dependencies for ingress and certificate management:

1.  **Ingress-NGINX**: This Helm chart sets up an NGINX Ingress Controller to manage HTTP(S) access to your application.
    
    Install the Ingress-NGINX chart from the official repository:
    
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace` 
```    
    -   This will install the Ingress-NGINX controller in the `ingress-nginx` namespace.
    -   For further configuration details, refer to the [Ingress-NGINX GitHub repository](https://github.com/kubernetes/ingress-nginx/tree/main).

2.  **Cert-Manager**: This Helm chart installs Cert-Manager to manage SSL/TLS certificates in your Kubernetes cluster.
    
    Install the Cert-Manager chart from the Artifact Hub repository:

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true` 
```

    -   This installs Cert-Manager in the `cert-manager` namespace, with CRDs necessary for certificate management.
    -   For further configuration and setup options, refer to the [Cert-Manager Helm chart on Artifact Hub](https://artifacthub.io/packages/helm/cert-manager/cert-manager).

Once these dependencies are installed, you can proceed with deploying the FastAPI application using the Helm chart configured in previous steps.


### Step 5: Prepare Kubeconfig

To create a `kubeconfig` file for a Service Account (SA) with the required permissions to deploy an application, follow these high-level steps:

1.  **Create a Namespace (if needed):**
    
    -   Define a specific namespace in your target Kubernetes cluster where the SA will operate (e.g., `app-deploy-namespace`).
2.  **Create a Service Account (SA):**
    
    -   Create a Service Account in the specified namespace (e.g., `deploy-sa`).
3.  **Assign Roles to the SA:**
    
    -   Create a `Role` or `ClusterRole` (e.g., `deployer-role`) with permissions such as `create`, `update`, and `delete` for resources like `pods`, `deployments`, `services`, etc.
    -   Bind the Role to the Service Account using a `RoleBinding` (for namespace-specific access) or a `ClusterRoleBinding` (for cluster-wide access).
4.  **Extract the SA Token:**
    
    -   Retrieve the SA's token by describing the SA's secret or using kubectl to fetch the token directly.
5.  **Create the kubeconfig File:**
    
    -   Use the cluster's server address, CA certificate, and the SA token to create a kubeconfig file for the SA. Structure it to include:
        -   **Cluster**: Add the Kubernetes API server’s URL and CA certificate.
        -   **User**: Define the SA user with the token.
        -   **Context**: Set a context linking the cluster and the SA user.
6.  **Test the kubeconfig File:**
    
    -   Validate access by listing resources in the namespace (e.g., `kubectl get pods --kubeconfig=/path/to/kubeconfig`).

This kubeconfig file can now be used for deploying applications in your CI/CD pipeline.

### Challenges Faced

1.  **Optimizing Docker Image Size and Security**  
    Faced challenges in minimizing the Docker image size and reducing vulnerabilities. Tested multiple base images, ultimately choosing a smaller, security-focused base to reduce vulnerabilities significantly, though not entirely eliminate them.
    
2.  **Learning Python-Specific CI Tools**  
    Researching Python tools for linting, formatting, and unit testing required a shift, as it differs from typical Terraform workflows. Developed familiarity with `pylint`, `black` (for formatting), and `unittest`, and integrated them into the pipeline to ensure code quality and maintainability.

3.  **Caching Mechanisms**: Explored caching strategies to optimize build times (e.g., for Docker layers and dependencies) but kept them aside for this use case to avoid added complexity.

4.  **Enhanced Security Scans**: While advanced security scanning for dependencies and container images was considered, it was deferred for simplicity, as it could introduce unnecessary complexity at this stage.