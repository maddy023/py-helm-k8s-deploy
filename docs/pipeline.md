
# CI/CD Pipeline Documentation

This document provides an overview of the CI/CD pipeline used to build, deploy, and notify the status of deployments for the FastAPI application.

[pipeline.yaml](../.github/workflows/buldndeploy.yaml)

## Pipeline Name: `Build n Deploy Pipeline`

### Secrets Used in the Pipeline


1.  **`DOCKERHUB_USERNAME`**
    
    -   **Description**: The username for DockerHub. Used to log into DockerHub so that the workflow can push Docker images.
    -   **Usage**: Referenced in the `docker_build_push` job under the **login to docker registry** step.
2.  **`DOCKERHUB_TOKEN`**
    
    -   **Description**: The DockerHub token (or password) associated with `DOCKERHUB_USERNAME`. Used to authenticate with DockerHub during the login step.
    -   **Usage**: Referenced in the `docker_build_push` job under the **login to docker registry** step.
3.  **`SONAR_TOKEN`**
    
    -   **Description**: The authentication token for SonarQube, which allows the SonarQube scan action to access the SonarQube server.
    -   **Usage**: Used in the `anlayse` job within the SonarQube scan step to perform code quality and security analysis.
4.  **`SONAR_HOST_URL`**
    
    -   **Description**: The URL of the SonarQube server where the code quality reports are sent.
    -   **Usage**: Used alongside `SONAR_TOKEN` in the `anlayse` job within the SonarQube scan step.
5.  **`KUBE_CONFIG`**
    
    -   **Description**: The Kubernetes configuration file (kubeconfig) for accessing the target Kubernetes cluster (e.g., Azure Kubernetes Service or Amazon EKS).
    -   **Usage**: Used in the `helm_deploy` job with the **kubectl** action to interact with the Kubernetes cluster for deployment.
6.  **`SLACK_WEBHOOK_URL`**
    
    -   **Description**: The webhook URL for a Slack channel. Used to send notifications about the deployment status (success or failure) directly to Slack.
    -   **Usage**: Used in the `helm_deploy` job in the **Notify Slack on Success** and **Notify Slack on Failure** steps to send status updates.

### Adding Secrets to GitHub

To add these secrets to your GitHub repository:

1.  Go to your repository on GitHub.
2.  Navigate to **Settings** > **Secrets and variables** > **Actions**.
3.  Click **New repository secret**.
4.  Enter each secret name (e.g., `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, etc.) and the corresponding value.
5.  Save each secret.

### Tools Used

1.  **GitHub Actions**
    
    -   **Purpose**: Provides the CI/CD platform that automates the pipeline. GitHub Actions allows the workflow to respond to various triggers (e.g., manual, on-push) and to manage jobs that run code analysis, testing, building, and deploying.
    -   **Usage in Workflow**: Automates the entire build, test, and deployment process with parallel job execution and status tracking.
2.  **Pylint**
    
    -   **Purpose**: A Python linter used to analyze the codebase for adherence to coding standards and to catch potential issues like syntax errors or style violations.
    -   **Usage in Workflow**: Executes during the `anlayse` job to ensure the code follows Python standards before deployment.
3.  **unittest**
    
    -   **Purpose**: The standard Python testing framework, used to execute unit tests and verify application functionality.
    -   **Usage in Workflow**: Runs in the `anlayse` job, allowing the pipeline to catch errors early by validating core application logic.
4.  **SonarQube**
    
    -   **Purpose**: Provides static code analysis to detect bugs, vulnerabilities, and code smells (maintainability issues).
    -   **Usage in Workflow**: Integrates within the `anlayse` job to provide insights into code quality and security, using the `SONAR_TOKEN` and `SONAR_HOST_URL` secrets for authentication.
5.  **Docker**
    
    -   **Purpose**: Containerizes the application to make it portable and deployable in various environments.
    -   **Usage in Workflow**: Builds the application image and pushes it to a Docker registry in the `docker_build_push` job, where the image can be reused in different stages or environments.
6.  **Helm**
    
    -   **Purpose**: A package manager for Kubernetes that manages application deployments with Helm charts, which simplify complex Kubernetes configurations.
    -   **Usage in Workflow**: Deploys the application to the Kubernetes cluster in the `helm_deploy` job using Helm charts, allowing flexible versioning and updates.
7.  **Kubectl**
    
    -   **Purpose**: A command-line tool for managing Kubernetes clusters.
    -   **Usage in Workflow**: Used within the `helm_deploy` job to communicate with the Kubernetes cluster, deploying and managing the Helm release.
8.  **Slack Webhook**
    
    -   **Purpose**: Sends messages to Slack channels for team notifications, helping to track deployment status and quickly address failures.
    -   **Usage in Workflow**: Notifies the designated Slack channel about the success or failure of the deployment in the `helm_deploy` job, using the `SLACK_WEBHOOK_URL` secret for secure communication.

### Trigger

The pipeline is manually triggered by `workflow_dispatch`. Future updates can expand this to include branch-based triggers (e.g., `main`), currently commented out.

```yaml
on:
  workflow_dispatch:
```

### Environment Variables

Several environment variables are set up for use across the workflow:

-   **APPLICATION_NAME**: Name of the GitHub repository.
-   **DOCKER_IMAGE**: The Docker image name, retrieved from GitHub secrets.
-   **HELM_RELEASE_NAME**: Release name for Helm deployment.
-   **DEPLOY_TAG**: Deployment tag set as the Git commit SHA.

```yaml
env:
  APPLICATION_NAME: ${{ github.event.repository.name }}
  DOCKER_IMAGE: ${{secrets.DOCKERHUB_USERNAME}}/python-nonprod-app
  HELM_RELEASE_NAME: pubip
  DEPLOY_TAG: ${{ github.sha }}` 
```

## Jobs

### Jobs

#### 1. **Code Analysis Job: `anlayse`**

**Purpose**: To analyze the code for issues such as linting problems and to run unit tests.

**Job Name**: `anlayse`  
**Runs-on**: `ubuntu-latest`

1. **actions/checkout**: This action checks out the repository so that the subsequent steps can work with the code.

```yaml
    - name: Checkout repository
      uses: actions/checkout@v4` 
```

2.  **actions/setup-python**: This action sets up Python 3.11 for the job. It ensures that the Python version specified is installed on the runner.

```yaml
- name: Set up Python
  uses: actions/setup-python@v2
  with:
    python-version: 3.11` 
```

3. **Install dependencies**: This step upgrades pip and installs the dependencies from the `requirements.txt` file.

```yaml
- name: Install dependencies
  run: |
    python -m pip install --upgrade pip
    pip install -r requirements.txt` 
```

4.   **Pylint**: Runs static code analysis using `pylint` on the `./src` directory to check for coding style violations, errors, or potential issues.


```yaml
- name: Code Lint with Pylint
  run: pylint ./src` 
```

5.  **Unit Tests**: Runs the unit tests from the `tests/test_main.py` file using Python's built-in `unittest` framework. This ensures the code behaves as expected.

```yaml
 - name: Run Unit Tests
  run: unittest tests/test_main.py` 
```


6. **SonarQube Scan**: This step runs a SonarQube scan to analyze the code quality and security. The `SONAR_TOKEN` and `SONAR_HOST_URL` are stored in GitHub Secrets to ensure secure access to the SonarQube server.

```yaml
- uses: sonarsource/sonarqube-scan-action@master
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
    SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}` 
```


### 2. Docker Build and Push

**Purpose**:  This job builds and pushes a Docker image to the Docker registry.

**Job Name**: `docker_build_push`  
**Runs-on**: `ubuntu-latest`

#### Steps

1.  **Checkout Repository**: Uses `actions/checkout@v4` to clone the repository for Docker build context.
    
```yaml
- name: Checkout repository
  uses: actions/checkout@v4
```

2.  **Login to Docker Registry**: Uses `docker/login-action@v3` to authenticate to DockerHub with credentials stored in GitHub secrets.
    
```yaml
  - name: login to docker registry
    uses: docker/login-action@v3
    with:
        username: ${{secrets.DOCKERHUB_USERNAME}}
        password: ${{secrets.DOCKERHUB_TOKEN}}
``` 
    
3.  **Build and Push Docker Image**: Uses `docker/build-push-action@v5` to build the image from the repository context and push it to the registry with `DEPLOY_TAG` as the tag.
    
```yaml
  - name: build and push docker image to registry
    uses: docker/build-push-action@v5
    with:
        context: .
        push: true
        tags: ${{ env.DOCKER_IMAGE }}:${{ env.DEPLOY_TAG }}
```

4. **Docker Image Scan**: Scans the built Docker image for vulnerabilities using the Anchore scan action. This ensures that no critical vulnerabilities exist in the image before it’s deployed. `fail-build: false` ensures that the build continues even if vulnerabilities are found, but you can change this to `true` if you want to fail the pipeline on critical vulnerabilities.

```yaml
- name: Scan image
  uses: anchore/scan-action@v3
  with:
    image: ${{ env.DOCKER_IMAGE }}:${{ env.DEPLOY_TAG }}
    fail-build: false
    severity-cutoff: critical
```

### 2. Helm Deployment

**Purpose**:  This job deploys the application to the Kubernetes cluster using Helm and sends Slack notifications on success or failure.

**Job Name**: `helm_deploy`  
**Runs-on**: `ubuntu-latest`

#### Steps

1.  **Checkout Repository**: Clones the repository, ensuring the Helm chart and configurations are available.
    
```yaml
    - name: Checkout repository
      uses: actions/checkout@v4
```

2.  **Install Helm**: Sets up Helm using `azure/setup-helm@v4.2.0` to version `3.16.0`.
    
```yaml
- uses: azure/setup-helm@v4.2.0
    with:
    version: '3.16.0'
    id: install`
```

3.  **Extract Branch Name**: Extracts the branch name from the `GITHUB_REF`, setting it as an output for later use in Slack notifications.
    
```yaml
    - name: Extract branch name
    id: extract_branch
    shell: bash
    run: echo "##[set-output name=branch;]$(echo ${GITHUB_REF#refs/heads/})"
```
    
4.  **Set Up kubectl**: Sets up `kubectl` to interact with the target K8s cluster. Requires the `KUBE_CONFIG` secret for access.
    
```yaml
    - uses: actions-hub/kubectl@master
      env:
        KUBE_CONFIG: ${{ secrets.KUBE_CONFIG }}
```
    
5.  **Deploy Helm Chart**: Deploys or updates the Helm release using `helm upgrade --install` with values from `values.yaml` and the Docker image tag set to `DEPLOY_TAG`. `--wait` ensures deployment waits until all resources are available.
    
```yaml
    - name: Deploy Helm Chart
      run: |
        helm upgrade --install ${{ env.HELM_RELEASE_NAME }} ./charts \
          --values ./charts/values.yaml \
          --set image.tag=${{ env.DEPLOY_TAG }} --wait
```
    
6.  **Notify Slack on Success**: If the deployment is successful, sends a formatted message to Slack with key deployment details. Uses the `SLACK_WEBHOOK_URL` secret to send the message.
    
```yaml
  - name: Notify Slack on Success
    if: success()
    env:
        BRANCH_NAME: ${{ steps.extract_branch.outputs.branch }}
    run: |
        MESSAGE="{\"text\":\"$MESSAGE\"}"
        curl -X POST -H 'Content-type: application/json' --data "$MESSAGE" ${{ secrets.SLACK_WEBHOOK_URL }}
```
    
7.  **Notify Slack on Failure**: If the deployment fails, sends an error message to Slack with deployment status, reason, and a link to the failed pipeline run for review.
    
```yaml
  - name: Notify Slack on Failure
    if: failure()
    env:
        BRANCH_NAME: ${{ steps.extract_branch.outputs.branch }}
    run: |
        MESSAGE="{\"text\":\"$MESSAGE\"}"
        curl -X POST -H 'Content-type: application/json' --data "$MESSAGE" ${{ secrets.SLACK_WEBHOOK_URL }}` 
``` 

### Future Improvements for a Simplified, Reusable, and Developer-Friendly Pipeline

**1. Modular, Reusable Workflows**  
Break the pipeline into smaller, modular workflows (e.g., `lint`, `test`, `build`, `deploy`) using composite actions. This makes steps reusable across repositories, simplifying updates and reducing code duplication.

**2. Environment-Specific Configurations**  
Use environment-based configuration files for settings like domains and resources. Developers can update environment-specific settings without editing core workflows, making deployments more adaptable.

**3. Branch-Based Deployments**  
Enable branch-based workflows to deploy changes to specific environments based on branch names (e.g., `staging`, `main`). This makes environment-specific deployments automatic and consistent.

**4. Job Templates for Testing and Quality Checks**  
Create reusable templates for SAST, testing, and quality checks that can run in parallel. Separate workflows for PR-based jobs would provide early feedback by posting test and code analysis results directly to the PR.

**5. Centralized Secrets Management**  
Document and centralize secrets for each environment, improving security and reducing maintenance complexity. Scoped secrets management allows each job to access only relevant secrets, enhancing security.

**6. Workflow Dispatch for Manual Deployments**  
Use `workflow_dispatch` to enable manual deployments with custom parameters, giving developers flexibility for specific deployments without modifying the pipeline code.

**7. Automated Workflow Documentation**  
Implement auto-generated documentation for workflow steps to increase transparency and ease onboarding. This provides developers with a quick reference to understand and contribute to the CI/CD logic.