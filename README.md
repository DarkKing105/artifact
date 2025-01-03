# CI/CD Implementation in Home-Lab

Welcome! This document outlines how I configured and implemented a full CI/CD process in my home-lab for a Python-based microservice application. This project provided an excellent opportunity to build a setup closer to enterprise-grade with high availability, observability, and security.

---

## 🎥 Watch the Workflow

Check out the full CI/CD configuration workflow in this [video](https://www.youtube.com/watch?v=48VoodoVpuo). 📹✨

[same video without subtitles and in high resolution.](https://www.youtube.com/watch?v=eqJcqAufGxI)

---

## 📜 Application Overview

The application is a Python-based microservice designed to scrape and fetch real-time level 2 data of the Indian stock market. It connects to the internet, scrapes the data, and emits it internally via a socket.

### Motivation

Deploying this app to my Raspberry Pi traditionally involved manual copy-paste methods, which were time-intensive and prone to errors. This project aimed to:
- Automate deployment.
- Enhance performance.
- Ensure high availability.
- Improve observability and security. 🌟💡

---

## ⚙️ Steps to Achieve Full CI/CD

### 1. Setting Up the Home-Lab

#### Proxmox Installation
I installed **Proxmox** on an old laptop and configured a cloud-init image, similar to Amazon AMI. This image was later used by Terraform.

![Proxmox Setup](https://img.shields.io/badge/-Proxmox-E57000?logo=proxmox&logoColor=white&style=for-the-badge)

---

### 2. Infrastructure Provisioning

#### Using Terraform
I provisioned the VMs and started them using Terraform scripts. You can find the script [here](https://github.com/DarkKing105/artifact/blob/main/terraform/main.tf).

---

### 3. Kubernetes Cluster Setup

#### Using Ansible
With the VMs ready, I used their IPs to configure an Ansible script that installed and started an **RKE2 cluster**. Thanks to [Jim’s Garage](https://github.com/JamesTurland/JimsGarage) for the well explained script.

#### Kubernetes the Hard Way
To deepen my understanding, I followed **Kubernetes the Hard Way** ([link](https://github.com/kelseyhightower/kubernetes-the-hard-way)). After a few attempts, the K8s cluster was successfully up and running. 🚀😅

Now, I have two Kubernetes clusters running on bare metal.

---

### 4. Observability with Rancher

I installed **Rancher** following its documentation. Initially, I faced access issues because the Rancher service was exposed via `ClusterPort`. After exploring options, I configured **MetalLB** to act as a production-grade LoadBalancer.

#### MetalLB Configuration
I installed MetalLB using [their documentation](https://metallb.universe.tf/installation/). The LoadBalancer allowed me to expose services with a defined IP range, ensuring seamless access.

---

### 5. Application Deployment

#### Helm for Simplified Deployment
I installed **Helm** ([docs link](https://helm.sh/docs/intro/install/)) to streamline application installations.

Installed tools using Helm:
- **Jenkins**
- **ArgoCD**
- **SonarQube**

#### Jenkins Cloud Agents
The standout feature of Jenkins is its ability to provision agents as Kubernetes pods. These agents scale horizontally based on workload. [Learn more](https://plugins.jenkins.io/kubernetes/).

---

### 6. CI/CD Workflow

#### GitHub Actions
I configured two workflows that trigger on pull requests to `main` and `staging` branches:

1. **Build and Test Workflow**
   - Installs necessary packages.
   - Creates a Docker image.
   - Runs unit tests to ensure the app emits data on port `6789`.
   ```yaml
   name: Docker Build and Unittest

    on:
      pull_request:
        branches:
          - staging
          - main
    
    jobs:
      unittest:
        runs-on: arc-runner-set

    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up Python
        run: |
          sudo apt-get update
          sudo apt-get install -y python3 python3-pip

      - name: Set up Docker Build
        uses: docker/setup-buildx-action@v2

      - name: Build Docker Image
        env:
          TV_AUTH_TOKEN: ${{ secrets.TV_AUTH_TOKEN }}
          USER_DATA_DIR: ${{ secrets.USER_DATA_DIR }}
        run: |
          docker build \
            --build-arg TV_AUTH_TOKEN=$TV_AUTH_TOKEN \
            --build-arg USER_DATA_DIR=$USER_DATA_DIR \
            -t test-image:latest .

      - name: Run app Server in Docker
        run: |
          docker run --rm -d -p 6789:6789 test-image:latest


      - name: Run Unittests 
        run: |
          pip install -r requirements.txt
          python3 -m unittest test_port_connection.py
   ```

2. **Code Quality Workflow**
   - Triggers a **SonarQube scan**.
   - Fails the workflow if code violations are found.
   ```yaml
   name: Run SonarQube

    on:
      pull_request:
        branches:
          - staging
          - main
    
    jobs:
      sonar-scan:
        runs-on: arc-runner-set
        steps:
          - name: Checkout code
            uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          if [ -f requirements.txt ]; then pip install -r requirements.txt; fi

      - name: SonarQube Scan
        uses: sonarsource/sonarqube-scan-action@master
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}

      - name: Wait for Quality Gate
        uses: sonarsource/sonarqube-quality-gate-action@master
        timeout-minutes: 5
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
   ```

#### Integration with Jenkins
After passing workflows, the `staging` branch merges trigger a final GitHub Action:
- Starts a Jenkins pipeline to build, tag, and push the Docker image to GitHub Container Registry.

![Jenkins Pipeline Screenshot](https://github.com/DarkKing105/artifact/blob/main/Images/Screenshot%202025-01-03%20153015.png)

#### Deployment with ArgoCD
The updated Docker image tag is added to the `values.yaml` file. **ArgoCD** automatically deploys the updated application to the cluster.

![ArgoCD Deployment Screenshot](https://github.com/DarkKing105/artifact/blob/main/Images/Screenshot%202025-01-02%20211555.png).

---

