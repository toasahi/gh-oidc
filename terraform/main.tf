data "tls_certificate" "github_actions_tls" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# 現在、thumprint_listのユーザー指定値は無視される。そのため、40文字のダミーでも可（歴史的経緯から必須プロパティ）
resource "aws_iam_openid_connect_provider" "github_actions_oidc" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions_tls.certificates[0].sha1_fingerprint]
}

# GitHub Actions側からはこのIAM Roleを指定する
resource "aws_iam_role" "github_actions_role" {
  name               = "github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions.json
  description        = "IAM Role for GitHub Actions OIDC"
}

data "aws_iam_policy_document" "github_actions" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github_actions_oidc.arn
      ]
    }

    # OIDCを利用できる対象のGitHub Repositoryを制限する
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.full_paths
    }
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_iam_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
  role       = aws_iam_role.github_actions_role.name
}