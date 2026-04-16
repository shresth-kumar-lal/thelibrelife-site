# The Libre Life | Automated GitOps Deployment to AWS ECR 🚀

[![CI/CD Pipeline](https://github.com/shresth-kumar-lal/thelibrelife-site/actions/workflows/deploy.yml/badge.svg)](https://github.com/shresth-kumar-lal/thelibrelife-site/actions)
[![Hugo Version](https://img.shields.io/badge/Hugo-v0.148.0_Extended-blue.svg)](https://gohugo.io/)
[![Docker Base](https://img.shields.io/badge/Docker-Nginx_Alpine-blue.svg)](https://hub.docker.com/_/nginx)
[![AWS ECR](https://img.shields.io/badge/AWS-Elastic_Container_Registry-FF9900.svg)](https://aws.amazon.com/ecr/)

This repository houses the source code and fully automated continuous delivery pipeline for **The Libre Life**. It serves as a proof-of-concept for enterprise-grade GitOps, demonstrating how to securely containerize a modern static site and automate its delivery to a private AWS cloud registry.

## Architecture & Pipeline Flow

The deployment lifecycle is 100% automated using GitHub Actions. No manual server intervention is required.

1. **Version Control:** Developer pushes markdown content or configuration changes to the `main` branch via SSH.
2. **Environment Provisioning:** GitHub Actions spins up an ephemeral `ubuntu-latest` runner.
3. **AWS Authentication:** The runner securely authenticates with AWS IAM using repository secrets to obtain temporary session tokens.
4. **Multi-Stage Build:** - *Stage 1 (Builder):* Uses `hugomods/hugo:exts-0.148.0` to compile the Blowfish theme and minify the HTML/CSS/JS artifacts.
   - *Stage 2 (Production):* Copies *only* the compiled static assets (`/public`) into a highly secure, lightweight `nginx:alpine` web server.
5. **Artifact Storage:** The immutable Docker image is tagged with the unique Git commit SHA (for easy rollbacks) and pushed to a private **Amazon Elastic Container Registry (ECR)** in the `eu-north-1` (Stockholm) region.

## Technology Stack

* **Static Site Generator:** Hugo Extended
* **Theme:** Blowfish (Installed as a Git Submodule)
* **Containerization:** Docker (Multi-stage builds, `.dockerignore` optimized)
* **Web Server:** Nginx (Alpine Linux)
* **CI/CD:** GitHub Actions
* **Cloud Infrastructure:** AWS IAM, Amazon ECR

## Engineering Challenges Overcome

Building an automated pipeline exposes the fragile nature of open-source dependency matrices. During the development of this CI/CD pipeline, several breaking changes were identified and resolved:

* **The `:latest` Tag Trap & Deterministic Builds:** Initial builds failed because the Docker base image used the `:latest` tag, which pulled a bleeding-edge version of Hugo that broke the theme's compiler. **Solution:** Refactored the `Dockerfile` to implement strict version pinning (`hugomods/hugo:exts-0.148.0`), ensuring immutable, deterministic builds that will not fracture during upstream updates.
* **Deprecation Resolution in CI Logs:** The pipeline exposed deprecation warnings where legacy `locale` and `label` variables were placed at the top-level of the `languages.en.toml` file. **Solution:** Refactored the TOML structure to nest variables under the `[params]` block, satisfying modern Hugo compiler constraints.
* **Regional Vault Mapping:** Pipeline authenticated with AWS successfully but failed to locate the ECR repository due to a geographic mismatch. **Solution:** Re-mapped GitHub Action secrets to explicitly target the `eu-north-1` endpoint.

## Run it Locally

Want to see the containerized application running on your own machine? You don't need AWS access to test the build. 

Ensure you have [Docker](https://www.docker.com/) and Git installed, then run these commands:

```bash
# 1. Clone the repository and fetch the Blowfish submodule
git clone --recurse-submodules git@github.com:shresth-kumar-lal/thelibrelife-site.git

# 2. Navigate into the directory
cd thelibrelife-site

# 3. Execute the multi-stage Docker build
docker build -t thelibrelife-local .

# 4. Run the Nginx container on port 8080
docker run -p 8080:80 thelibrelife-local
