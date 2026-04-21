# The Libre Life | Dual-Target GitOps Deployment Pipeline 🚀

[![CI/CD Pipeline](https://github.com/shresth-kumar-lal/thelibrelife-site/actions/workflows/deploy.yml/badge.svg)](https://github.com/shresth-kumar-lal/thelibrelife-site/actions)
[![Hugo Version](https://img.shields.io/badge/Hugo-v0.160.1_Extended-blue.svg)](https://gohugo.io/)
[![Docker Base](https://img.shields.io/badge/Docker-Nginx_Alpine-blue.svg)](https://hub.docker.com/_/nginx)
[![AWS ECR](https://img.shields.io/badge/AWS-Elastic_Container_Registry-FF9900.svg)](https://aws.amazon.com/ecr/)
[![Live Site](https://img.shields.io/badge/Live-thelibrelife.org-success.svg)](https://thelibrelife.org)

This repository houses the source code and fully automated continuous delivery pipeline for **[The Libre Life](https://thelibrelife.org)**. It serves as a proof-of-concept for enterprise-grade GitOps, demonstrating how to engineer a single GitHub Actions workflow that simultaneously deploys a highly-optimized static application to a global CDN, while securely packaging and pushing a production-ready Docker container to a private AWS cloud registry.

## Architecture & Pipeline Flow

```mermaid
flowchart TD
    Dev([Developer]) --&gt;|git push origin main| Repo[(GitHub Repository)]

    subgraph CI_CD [&quot;CI/CD Pipeline (GitHub Actions)&quot;]
        direction TB
        Repo --&gt; Trigger{Push to main}
        
        Trigger --&gt; Job1[Job 1: Build &amp; Deploy to Pages]
        Trigger --&gt; Job2[Job 2: Build &amp; Push Docker Image]

        subgraph PagesPipeline [&quot;Target 1: Static Hosting&quot;]
            Job1 --&gt; InstallHugo[Install Hugo v0.160.1 &amp; Dart Sass]
            InstallHugo --&gt; Compile[Compile Static Assets]
            Compile --&gt; Upload[Upload Pages Artifact]
        end

        subgraph DockerPipeline [&quot;Target 2: Enterprise Artifact&quot;]
            Job2 --&gt; Auth[Authenticate AWS IAM]
            Auth --&gt; BuildImg[Build Multi-stage Nginx Container]
            BuildImg --&gt; TagImg[Tag Image with Git SHA]
        end
    end

    subgraph Production [&quot;Production Hosting&quot;]
        Upload --&gt;|Deploy| GHPages[GitHub Pages Global CDN]
    end

    subgraph AWSRegistry [&quot;AWS Cloud Vault&quot;]
        TagImg --&gt;|Push Image| ECR[(Amazon ECR)]
    end

    subgraph DNS [&quot;DNS Routing (Porkbun)&quot;]
        Domain(thelibrelife.org) -.-&gt;|A &amp; CNAME Records| GHPages
    end

    User([Internet User]) --&gt;|HTTPS Request| Domain

    %% Styling
    style GHPages fill:#e6ffe6,stroke:#2ca02c,stroke-width:2px,color:#000
    style ECR fill:#fff3e6,stroke:#ff9900,stroke-width:2px,color:#000
    style CI_CD fill:#f0f6ff,stroke:#0366d6,stroke-width:2px,color:#000
    style Production fill:#f9f9f9,stroke:#333,stroke-width:1px,color:#000
    style AWSRegistry fill:#f9f9f9,stroke:#333,stroke-width:1px,color:#000
```

The deployment lifecycle is 100% automated using a parallel-job GitHub Actions pipeline. No manual server intervention is required.

1. **Version Control:** Developer pushes markdown content or configuration changes to the `main` branch.
2. **Parallel CI/CD Jobs:** GitHub Actions spins up ephemeral `ubuntu-latest` runners to execute two targets concurrently:
   - **Target 1 (Production Hosting):** Injects the Dart Sass compiler, builds the static assets, and deploys directly to GitHub Pages CDN natively bound to the `thelibrelife.org` apex domain.
   - **Target 2 (Enterprise Artifact):** Authenticates with AWS IAM via secure secrets, executes a multi-stage Docker build, and pushes an immutable, Nginx-backed container to a private Amazon Elastic Container Registry (ECR) in the `eu-north-1` (Stockholm) region.
3. **DNS Routing:** Porkbun DNS dynamically routes `A` and `CNAME` requests to GitHub's global Anycast IP network, enforcing strict SSL/HTTPS.


## Technology Stack

* **Static Site Generator:** Hugo Extended (v0.160.1)
* **Theme & UI:** Blowfish (Installed as a Git Submodule)
* **Containerization:** Docker (Multi-stage builds, minimal Nginx Alpine image)
* **CI/CD:** GitHub Actions (Dual-Target Matrix)
* **Cloud Infrastructure:** AWS IAM, Amazon ECR
* **Networking:** Porkbun DNS, GitHub Pages Global CDN

## Engineering Challenges Overcome

Building an automated pipeline exposes the fragile nature of open-source dependency matrices. During the architectural design of this CI/CD pipeline, several complex challenges were identified and resolved:

* **The `:latest` Tag Trap & Upstream Registry Changes:** Initial Docker builds failed because the `:latest` tag pulled bleeding-edge Hugo binaries that fractured the theme's native `Locale` compiler. When attempting to pin the version, the upstream registry maintainers altered their tagging taxonomy. **Solution:** Conducted registry reconnaissance and refactored the `Dockerfile` to explicitly pin `hugomods/hugo:debian-reg-dart-sass-node-0.160.1`, guaranteeing deterministic, immutable builds.
* **Pipeline Synchronization:** Discovered a drift where the Docker pipeline and GitHub Pages pipeline were compiling with mismatched Hugo binaries, causing simultaneous failures and successes. **Solution:** Bound both workflow jobs to a unified `HUGO_VERSION` environment variable, ensuring absolute parity between the containerized artifact and the live CDN deployment.
* **Deprecation Resolution in CI Logs:** The strict compiler flagged legacy top-level TOML parameters. **Solution:** Refactored the data structure to securely nest `locale` and `label` configurations inside the `[params]` block.
* **Regional Vault Mapping:** The CI runner authenticated with AWS successfully but failed the push due to geographic routing restrictions. **Solution:** Remapped repository secrets to explicitly target the correct regional ECR endpoint (`eu-north-1`).

## Run the Container Locally

Want to see the AWS-bound containerized application running on your own machine? You don't need AWS access to test the build. 

Ensure you have [Docker](https://www.docker.com/) and Git installed, then run these commands:

```bash
# 1. Clone the repository and fetch the Blowfish submodule
git clone --recurse-submodules git@github.com:shresth-kumar-lal/thelibrelife-site.git

# 2. Navigate into the directory
cd thelibrelife-site

# 3. Execute the multi-stage Docker build
docker build -t thelibrelife-local .

# 4. Run the secure Nginx container on port 8080
docker run -p 8080:80 thelibrelife-local
