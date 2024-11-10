locals {
  allowed_github_repositories = [
    "gh-oidc",
  ]
  github_org_name = ""
  full_paths = [
    for repo in local.allowed_github_repositories : "repo:${local.github_org_name}/*:*"
  ]
}