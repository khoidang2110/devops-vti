
GitLab Setup on EC2 (m5.xlarge)

1. SSH into EC2 Instance

ssh -i ~/Downloads/khoidang.pem ec2-user@52.63.119.97

2. Update System and Install Docker

sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo systemctl enable docker

3. Add User to Docker Group and Check Docker Version

sudo usermod -aG docker $USER
newgrp docker
docker --version

4. Run GitLab Container

docker run --detach \
  --hostname 52.63.119.97 \
  --publish 8080:80 \
  --publish 8004:22 \
  --name gitlab \
  --restart always \
  --volume gitlab_config:/etc/gitlab \
  --volume gitlab_logs:/var/log/gitlab \
  --volume gitlab_data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest

5. Retrieve Initial Root Password

docker exec -it gitlab cat /etc/gitlab/initial_root_password
