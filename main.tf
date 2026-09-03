data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default-vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Automatically picks up whichever IAM identity is running `terraform apply`
data "aws_caller_identity" "current" {}

resource "aws_eks_cluster" "project-cluster" {
  name     = "project-cluster"
  role_arn = aws_iam_role.example.arn

  vpc_config {
    subnet_ids = data.aws_subnets.default-vpc.ids
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions  = true
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.example-AmazonEKSVPCResourceController,
  ]
}

output "endpoint" {
  value = aws_eks_cluster.project-cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.project-cluster.certificate_authority[0].data
}

resource "aws_eks_node_group" "node-grp" {
  cluster_name    = aws_eks_cluster.project-cluster.name
  node_group_name = "pc-node-group"
  node_role_arn   = aws_iam_role.worker.arn
  subnet_ids      = data.aws_subnets.default-vpc.ids
  capacity_type   = "ON_DEMAND"
  disk_size       = "40"
  instance_types  = ["c7i-flex.large"]
  labels          = tomap({ env = "dev" })

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
  ]
}

# --- New: explicit access entry so your console identity has admin access too ---
resource "aws_eks_access_entry" "current_user" {
  cluster_name  = aws_eks_cluster.project-cluster.name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "current_user_admin" {
  cluster_name  = aws_eks_cluster.project-cluster.name
  principal_arn = aws_eks_access_entry.current_user.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
