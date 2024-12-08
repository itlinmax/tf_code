provider "github" {
    token = var.token
    owner = var.owner
}

resource "github_repository" "example" {
    name        = "tf_code"
    description = "some terraform files"
    visibility  = "public"
    auto_init   = true
}

resource "github_branch" "development" {
    repository = github_repository.example.name
    branch     = "master"
}
