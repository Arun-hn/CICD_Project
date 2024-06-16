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
      "sudo yum update –y",
      # Install Git 
      "sudo yum install git -y",

      # Install Jenkins 
      # REF: https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum upgrade",
      "sudo dnf install java-17-amazon-corretto -y",
      "sudo yum install jenkins -y",
      "sudo systemctl enable jenkins",
      "sudo systemctl start jenkins",

      # Install Docker
      # REF: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-docker.html
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker",
      "sudo yum install -y docker",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker jenkins",

      # To avoid below permission error
      # Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock
      "sudo chmod 666 /var/run/docker.sock",

      "sleep 20",

      # Install AWS CLI

      "curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\"",
      "unzip awscliv2.zip",
      "sudo ./aws/install",

      # Download kubectl and its SHA256 checksum
      # Download kubectl 
      "curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl",
      "chmod +x ./kubectl",
      "sudo mv ./kubectl /usr/local/bin/kubectl",
      "kubectl version --client", # Verify kubectl version after installation

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

