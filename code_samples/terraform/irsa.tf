module "ca_irsa_role" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "eks-cluster-auto-scaler"
   cluster_autoscaler_irsa_role = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["<SERVICE_ACCOUNT>"]
    }
  }
}

module "cert_manager_irsa_role" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "eks-cert_manager"
   cluster_autoscaler_irsa_role = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["<SERVICE_ACCOUNT>"]
    }
  }
}