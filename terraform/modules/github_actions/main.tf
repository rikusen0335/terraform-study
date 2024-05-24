variable "project_name" {}
variable "account_id" {}
variable "github_org" {}
variable "github_repo" {}

resource "aws_iam_role" "github_actions" {
  name = "${terraform.workspace}-${var.project_name}-github-actions"
  assume_role_policy = templatefile("./assume_role.json",
    {
      account_id  = var.account_id,
      github_org  = var.github_org,
      github_repo = var.github_repo
    }
  )
}

resource "aws_iam_policy" "github_actions" {
  name   = "${terraform.workspace}-${var.project_name}-github-actions"
  policy = templatefile("./administrator.json", {})
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}