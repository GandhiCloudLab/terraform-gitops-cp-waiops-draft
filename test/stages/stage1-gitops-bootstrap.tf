resource null_resource write_outputs {
  provisioner "local-exec" {
    command = "echo \"$${OUTPUT}\" > gitops-output.json"

    environment = {
      OUTPUT = jsonencode({
        name        = module.gitops_cp_waiops.name
        branch      = module.gitops_cp_waiops.branch
        namespace   = module.gitops_cp_waiops.namespace
        server_name = module.gitops_cp_waiops.server_name
        layer       = module.gitops_cp_waiops.layer
        layer_dir   = module.gitops_cp_waiops.layer == "infrastructure" ? "1-infrastructure" : (module.gitops_cp_waiops.layer == "services" ? "2-services" : "3-applications")
        type        = module.gitops_cp_waiops.type
      })
    }
  }
}
