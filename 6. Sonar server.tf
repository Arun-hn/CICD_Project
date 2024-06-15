resource "aws_instance" "sonarqube_server" {
  ami                    = "ami-00fa32593b478ad6e"
  instance_type          = "t2.medium"
  vpc_security_group_ids = [aws_security_group.open_ports.id]
  subnet_id              = aws_subnet.public1.id
  key_name               = aws_key_pair.key_pair.key_name
  tags = {
    Name = "sonarqube_Server"
  }
  # Consider EBS volume 20GB
  root_block_device {
    volume_size = 20    # Volume size 30 GB
    volume_type = "gp2" # General Purpose SSD
  }
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

      # Install Docker
      # REF: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-docker.html
      "sudo amazon-linux-extras install docker",
      "sudo yum install -y docker",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",

      # To avoid below permission error
      # Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock
      "sudo chmod 666 /var/run/docker.sock",

      "sleep 20",

      # Pull and run SonarQube container
      "docker run -d --name sonarqube -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true -p 9000:9000 sonarqube:latest",

    ]
  }
}

