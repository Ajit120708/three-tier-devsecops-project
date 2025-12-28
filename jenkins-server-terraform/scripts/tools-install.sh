#!/bin/bash
set -e
exec > /var/log/user-data.log 2>&1

echo "===== Updating system ====="
apt-get update -y

echo "===== Installing Java 17 ====="
apt-get install -y openjdk-17-jdk
java --version

echo "===== Installing Jenkins ====="
apt-get install -y fontconfig openjdk-17-jre
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update -y
apt-get install -y jenkins
systemctl enable jenkins
systemctl start jenkins

echo "===== Installing Docker ====="
apt-get install -y docker.io
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu || true
usermod -aG docker jenkins || true

echo "===== Running SonarQube Container ====="
docker run -d \
  --name sonar \
  -p 9000:9000 \
  -v sonar_data:/opt/sonarqube/data \
  -v sonar_extensions:/opt/sonarqube/extensions \
  sonarqube:lts-community

echo "===== Installing AWS CLI v2 ====="
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt-get install -y unzip
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip
aws --version

echo "===== Installing kubectl ====="
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/
kubectl version --client

echo "===== Installing eksctl ====="
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin
eksctl version

echo "===== Installing Terraform ====="
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update -y
apt-get install -y terraform
terraform version

echo "===== Installing Trivy ====="
apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/trivy.list
apt-get update -y
apt-get install -y trivy
trivy --version

echo "===== Installing Helm ====="
apt-get install -y snapd
snap install helm --classic
helm version

echo "===== DevSecOps Jenkins Server Setup Complete ====="