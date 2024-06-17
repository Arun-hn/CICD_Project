# EC2 Instance for Jenkins Server
resource "aws_instance" "Jenkins_server" {
  ami                         = "ami-00fa32593b478ad6e"
  instance_type               = "t2.large"
  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.open_ports.id]
  subnet_id                   = aws_subnet.public1.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name

  key_name = aws_key_pair.key_pair.key_name


  # Consider EBS volume 30GB
  root_block_device {
    volume_size = 30    # Volume size 30 GB
    volume_type = "gp2" # General Purpose SSD
  }

  tags = {
    Name = "Jenkins_Server"
  }

  # USING REMOTE-EXEC PROVISIONER TO INSTALL TOOLS
  provisioner "remote-exec" {
    # ESTABLISHING SSH CONNECTION WITH EC2
    connection {
      type        = "ssh"
      private_key = tls_private_key.rsa_2048.private_key_pem
      user        = "ec2-user"
      host        = self.public_ip
    }

    inline = [
      # wait for 20sec before EC2 initialization
      "sleep 20",
      "sudo yum update –y && echo 'yum update completed",
      # Install Git 
      "sudo yum install git -y && echo 'Git installed'",

      # Install Jenkins 
      # REF: https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum upgrade",
      "sudo dnf install java-17-amazon-corretto -y && echo 'Java installed'",
      "sudo yum install jenkins -y && echo 'Jenkins installed'",
      "sudo systemctl enable jenkins && echo 'Jenkins service enabled'",
      "sudo systemctl start jenkins && echo 'Jenkins service started'",

      # Install Docker
      # REF: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-docker.html
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker",
      "sudo yum install -y docker && echo 'Docker installed'",
      "sudo systemctl start docker && echo 'Docker service started'",
      "sudo systemctl enable docker && echo 'Docker service enabled'",
      "sudo usermod -aG docker jenkins && echo 'Added Jenkins to Docker group'",

      # To avoid below permission error
      # Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock
      "sudo chmod 666 /var/run/docker.sock && echo 'Set Docker socket permissions'",

      # Install Trivy
      # REF: https://aquasecurity.github.io/trivy/v0.18.3/installation/
      "sudo rpm -ivh https://github.com/aquasecurity/trivy/releases/download/v0.18.3/trivy_0.18.3_Linux-64bit.rpm",
      "echo 'Trivy installed'",
      "sleep 20",

      # Install AWS CLI

      "curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\"",
      "unzip awscliv2.zip",
      "sudo ./aws/install",
      "echo 'AWS CLI installed'",

      # Download kubectl and its SHA256 checksum
      # Download kubectl 
      "curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl",
      "chmod +x ./kubectl",
      "sudo mv ./kubectl /usr/local/bin/kubectl",
      "echo 'Kubectl installed'",
      "kubectl version --client", # Verify kubectl version after installation
      
      # create and Move Monitoring directory
      "cd ~",
      "mkdir monitoring",
      "cd monitoring",
      
      # Install Prometheus
      "wget https://github.com/prometheus/prometheus/releases/download/v2.52.0/prometheus-2.52.0.linux-amd64.tar.gz",
      "tar -xzvf prometheus-2.52.0.linux-amd64.tar.gz",
      "mv prometheus-2.52.0.linux-amd64 prometheus",
      "rm prometheus-2.52.0.linux-amd64.tar.gz",
      "cd prometheus\",
      "./prometheus &",
      "echo 'Prometheus installed and running with port 9090'",
        
      # Move back to Monitoring directory
      "cd ..",

      # Install Blackbox Exporter
      "wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.25.0/blackbox_exporter-0.25.0.linux-amd64.tar.gz",
      "tar -xzvf blackbox_exporter-0.25.0.linux-amd64.tar.gz",
      "mv blackbox_exporter-0.25.0.linux-amd64 blackbox_exporter",
      "rm blackbox_exporter-0.25.0.linux-amd64.tar.gz",
      "cd blackbox_exporter\",
      "./blackbox_exporter &",
      "echo 'Blackbox Exporter installed and running with port  9115'",

      # Move back to Monitoring directory
      "cd ..",

      # Install Node Exporter
      "wget https://github.com/prometheus/node_exporter/releases/download/v1.8.1/node_exporter-1.8.1.linux-amd64.tar.gz",
      "tar -xzvf node_exporter-1.8.1.linux-amd64.tar.gz",
      "mv node_exporter-1.8.1.linux-amd64 node_exporter",
      "rm node_exporter-1.8.1.linux-amd64.tar.gz",
      "cd node_exporter\",      
      "./node_exporter &",
      "echo 'Node Exporter installed and running with port  9100'",

               
      # Move back to Monitoring directory
      "cd ..",

      # Install Grafana
      "mkdir grafana",
      "cd grafana\",

      "sudo tee /etc/yum.repos.d/grafana.repo<<EOF",
      "[grafana]",
      "name=grafana",
      "baseurl=https://packages.grafana.com/oss/rpm",
      "repo_gpgcheck=1",
      "enabled=1",
      "gpgcheck=1",
      "gpgkey=https://packages.grafana.com/gpg.key",
      "EOF",
      "sudo yum install -y grafana && echo 'Grafana installed'",
      "sudo systemctl start grafana-server && echo 'Grafana service started'",
      "sudo systemctl enable grafana-server && echo 'Grafana service enabled'",
      "echo 'Grafana is running with port  9100'",

    ]
  }

}


# Configure Jenkins on the EC2 instance
resource "null_resource" "configure_jenkins" {
  depends_on = [aws_eks_cluster.eks, aws_instance.Jenkins_server]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = aws_instance.Jenkins_server.public_ip
      user        = "ec2-user"                               # Adjust based on the AMI
      private_key = tls_private_key.rsa_2048.private_key_pem # Ensure the private key path is correct
    }

    inline = [
      "aws configure set region ${var.region}",
      "aws sts get-caller-identity",
      "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.eks.id}",
      "sudo mkdir -p /var/jenkins_home/.kube",
      "sudo cp ~/.kube/config /var/jenkins_home/.kube/config",
      "sudo chown jenkins:jenkins /var/jenkins_home/.kube/config",
    ]
  }
}

