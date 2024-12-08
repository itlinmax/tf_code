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

resource "github_repository" "openwrt" {
    name        = "openwrt_configs"
    description = "configs for my router"
    visibility  = "public"
    auto_init   = true
}

resource "github_repository" "configs" {
    name        = "configs"
    description = "my configs"
    visibility  = "public"
    auto_init   = true
}
