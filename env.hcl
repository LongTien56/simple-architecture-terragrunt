locals {
    # set_env = get_env("ENV", "dev")
    # env = local.set_env == "prod" ? "production" : "${local.env == "stage" ? "staging" : "${local.env == "dev" ? "dev" : "test"}"}"
    env = get_env("ENV", "dev")
}