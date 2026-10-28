# Automated Web Application Deployment Using Terraform, Jenkins CI/CD and Microsoft Azure

A small Flask web app. Every `git push` is tested, packed into a Docker image and deployed to Azure automatically.
Terraform creates the Azure resources. Jenkins runs the pipeline.

```
Developer --git push--> GitHub --webhook/poll--> Jenkins
   Jenkins: Checkout > Build > Test > Docker build+push > Deploy (az CLI) > Verify
   Docker Hub (image)  --->  Azure App Service (Linux, container)  --->  https://<app>.azurewebsites.net
   Terraform (once)  --->  Resource Group + App Service Plan + Web App
```

## Folder structure

| Path | What it does |
|---|---|
| `app/app.py` | Flask app with `/` and `/health` |
| `app/templates/index.html` | The web page |
| `app/requirements.txt` | Python packages |
| `tests/test_app.py` | Automated tests (pytest) |
| `Dockerfile` | Packs the app into a container image |
| `terraform/providers.tf` | Which cloud (Azure) and provider version |
| `terraform/variables.tf` | Inputs (names, region, size) |
| `terraform/main.tf` | The Azure resources |
| `terraform/outputs.tf` | Prints the app URL and names |
| `terraform/terraform.tfvars.example` | Template for your private values |
| `terraform/backend.tf.example` | Optional remote state in Azure Storage |
| `jenkins/Dockerfile` | Jenkins with Python, Docker CLI and Azure CLI |
| `Jenkinsfile` | The CI/CD pipeline |
| `report/` | Screenshots and report |

## Part A: Run locally (Windows, in VS Code terminal, project root)

```
python -m venv .venv
.venv\Scripts\activate
pip install -r app/requirements.txt
pytest tests/ -v
python app/app.py
```
Open http://localhost:5000 and http://localhost:5000/health. Expected: `3 passed`.

Docker test (Docker Desktop must be running):
```
docker build -t devops-flask-app .
docker run -p 8000:8000 -e APP_ENV=production devops-flask-app
```
Open http://localhost:8000. It should say Environment: production.

## Part B: GitHub and Docker Hub

1. Create an empty public repo `devops-azure-project` on https://github.com (no README).
2. In the project folder:
```
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/devops-azure-project.git
git push -u origin main
```
3. Create a free account at https://hub.docker.com. Make an access token: Account Settings > Personal access token > Read & Write.
4. Push the first image (Azure needs one to exist):
```
docker login
docker build -t YOUR_DOCKERHUB_USERNAME/devops-flask-app:latest .
docker push YOUR_DOCKERHUB_USERNAME/devops-flask-app:latest
```
Keep the Docker Hub repository **public**.

## Part C: Terraform (from the `terraform` folder)

1. Install: `winget install Hashicorp.Terraform` and `winget install Microsoft.AzureCLI`. Close and reopen the terminal.
2. `az login`, then `az account show --query id -o tsv` to get your subscription ID.
3. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values.
4. Run:
```
terraform init            # download the Azure provider
terraform fmt             # tidy formatting
terraform validate        # check syntax
terraform plan -out=tfplan  # preview: 3 resources to add
terraform apply tfplan    # create them
terraform output          # shows app_url, web_app_name, resource_group_name
```
Open `app_url` (wait 1-2 minutes on first load).

Destroy everything after the demo so you are not charged:
```
terraform destroy
```

### Remote state (optional, for state-management marks)
```
az group create --name rg-tfstate --location centralindia
az storage account create --name <UNIQUE_LOWERCASE_NAME> --resource-group rg-tfstate --sku Standard_LRS
az storage container create --name tfstate --account-name <UNIQUE_LOWERCASE_NAME>
```
Copy `backend.tf.example` to `backend.tf`, put your storage account name in it, then `terraform init -migrate-state`.

## Part D: Jenkins (Docker Desktop must be running)

```
docker build -t jenkins-devops ./jenkins
docker run -d --name jenkins -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock jenkins-devops
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```
Open http://localhost:8080, paste the password, install suggested plugins, create an admin user.

Create a service principal for Jenkins (keep the output private):
```
az ad sp create-for-rbac --name devops-sp --role Contributor --scopes /subscriptions/<SUBSCRIPTION_ID>
```
Jenkins > Manage Jenkins > Credentials > System > Global > Add Credentials:

| Kind | ID | Value |
|---|---|---|
| Username with password | `dockerhub-creds` | Docker Hub username + access token |
| Secret text | `azure-client-id` | `appId` |
| Secret text | `azure-client-secret` | `password` |
| Secret text | `azure-tenant-id` | `tenant` |
| Secret text | `azure-subscription-id` | subscription ID |

New Item > `devops-azure-pipeline` > Pipeline > Pipeline script from SCM > Git > your repo URL, branch `*/main`, script path `Jenkinsfile` > Save > Build Now.

Automatic trigger: job > Configure > Build Triggers > Poll SCM > `H/2 * * * *`.
(Or a GitHub webhook through ngrok: `https://<ngrok-url>/github-webhook/`.)

## Part E: Test the automation

Change the heading in `app/templates/index.html` (and keep test text "Terraform" in it), commit and push. Jenkins should build by itself, and the Azure page should show the new version number.

## Troubleshooting

| Problem | Fix |
|---|---|
| `python` not recognized | Reinstall Python with "Add python.exe to PATH" ticked |
| `terraform` not recognized | Close and reopen the terminal after installing |
| `SubscriptionNotFound` / auth error | `az login` again, check `subscription_id` |
| Name already taken | Change `web_app_suffix` |
| Quota error for B1 | Change `location` (e.g. `southindia`, `eastus`) |
| Jenkins: `docker: permission denied` | Run Jenkins with the socket mount as shown (container runs as root) |
| Jenkins: `az: command not found` | Rebuild the Jenkins image |
| Verify stage keeps returning 503 | Container is still starting; check `az webapp log tail --name <app> --resource-group rg-devopsflask-production` |
| Docker push `denied` | Wrong Docker Hub username/token or token is read-only |
| Resource group name mismatch | `RESOURCE_GROUP` in Jenkinsfile must be `rg-<project_name>-<environment>` |

## Cost

App Service plan B1 is a paid plan that bills while it exists (check the current price in the Azure pricing page or your credit balance). Run `terraform destroy` as soon as your demo is done.
