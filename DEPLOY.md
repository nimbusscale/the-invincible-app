This file includes the details needed to deploy the Invincible App for yourself. This will require a DO account along with Terraform and way to build and publish a container.

After the deployment, you will have all the components such as VPCs, databases, Kubernetes clusters, global load-balancing, and the application running in two regions. A new project will be created within your account 

# Prerequisites

- DO Account
- DO Container Repo configured for the account
- Terraform
- Docker or another tool that can build and push containers
- A DO managed DNS domain where a sub-domain will be created for the application and global load-balancing
- A Spaces bucket to be used as the Terraform backend along with an access/secret key that can be used to read/write from the bucket.

# Build and Publish Container
Everything you need to build the container. Using Docker it would look like something like this, where `${REPO_NAME}` would be the name the DO container repo in your account.

> **_NOTE:_**  We use the "latest" tag for this example, it's generally not recommended using the "latest" for a production deployment.

```
export REPO_NAME=repo_name 
cd container
docker build -t registry.digitalocean.com/${REPO_NAME}/invincible-app .
docker push registry.digitalocean.com/${REPO_NAME}/invincible-app
```

# Deploy via Terraform

Deployment of all the resources and application is done via Terraform. Deployment is done using three modules each run sequentially. The deployment needs to be setup this way as one module relies on resources created in previous modules. 

Modules are organized into two different kinds of modules:

- `terraform/resource` contain resource modules that are responsible for the creation of resources. These are, in theory, reusable.
- `terraform/deploy` contain deployment modules which are responsible for using the resource modules to do a deployment.

## Var File
Prior to deployment you need to update the following lines in this file `terraform/deploy/invincible-app.tfvars`:\

```
  parent_domain = "REPLACE"
  image_repository = "registry.digitalocean.com/REPLACE/invincible-app"
```

When you need to change `REPLACE` to the values used for the deployment.

# Initialize and Deploy Modules
You'll need to initialize 





