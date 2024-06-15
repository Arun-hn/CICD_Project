output "endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "ACCESS_YOUR_JENKINS_HERE" {
  value = "http://${aws_instance.Jenkins_server.public_ip}:8080"
}

output "Jenkins_Initial_Password_location" {
  value = "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
}

output "ACCESS_YOUR_NEXUS_HERE" {
  value = "http://${aws_instance.Nexus_server.public_ip}:8081"
}

output "ACCESS_YOUR_SONARQUBE_HERE" {
  value = "http://${aws_instance.sonarqube_server.public_ip}:9000"
}
output "MASTER_SERVER_PUBLIC_IP" {
  value = aws_instance.Jenkins_server.public_ip
}

output "MASTER_SERVER_PRIVATE_IP" {
  value = aws_instance.Jenkins_server.private_ip
}
