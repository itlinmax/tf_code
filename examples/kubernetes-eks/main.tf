provider "aws" {
    region = "eu-central-1"
}

module "eks_cluster" {
    source = "../../modules/services/eks-cluster"
    name = "example-eks-cluster"
    min_size = 1
    max_size = 2
    desired_size = 1
    # Due to the way EKS works with ENIs, t3.small is the smallest
    # instance type that can be used for worker nodes. If you try# something smaller like t2.micro, which only has 4 ENIs,
    # they'll all be used up by system services (e.g., kube-proxy)
    # and you won't be able to deploy your own Pods.
    instance_types = ["t3.small"]
}
