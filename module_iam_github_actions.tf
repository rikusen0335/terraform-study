# module "iam_role_github_actions" {
#   source = "./modules/github_actions"

#   project_name = local.project_name
#   account_id   = data.aws_caller_identity.current.account_id
#   github_org   = local.github_org
#   github_repo  = local.github_repo
# }