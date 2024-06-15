# To Generate Private Key
resource "tls_private_key" "rsa_2048" {
  algorithm = "RSA"
  rsa_bits  = 2048


}

#Save PEM file locally
resource "local_file" "private_key" {
  content  = tls_private_key.rsa_2048.private_key_pem
  filename = "cicd.pem"

  provisioner "local-exec" {
    command = "chmod 400 cicd.pem" # Adjust the path as per your directory structure
  }

}
# Create Key Pair for Connecting EC2 via SSH
resource "aws_key_pair" "key_pair" {
  key_name   = "cicd"
  public_key = tls_private_key.rsa_2048.public_key_openssh
}