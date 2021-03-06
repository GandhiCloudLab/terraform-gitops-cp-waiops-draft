locals {
  name        = "ibm-cp-waiops"
  bin_dir     = module.setup_clis.bin_dir
  chart_dir = "${path.module}/charts/${local.name}"
  yaml_dir    = "${path.cwd}/.tmp/${local.name}/charts/${local.name}"
  service_url = "http://${local.name}.${var.namespace}"
  image_pullsecret_name = "ibm-entitlement-key"

  values_content_catalog = {
    cp_waiops_namespace = var.namespace
  }
  values_content_subscription = {
    cp_waiops_namespace = var.namespace
  }
  values_content_instance = {
    cp_waiops_namespace = var.namespace
    cp_waiops_imagePullSecret = var.image_pullsecret_name
    cp_waiops_storageClass = var.cp_waiops_storageClass
    cp_waiops_storageClassLargeBlock = var.cp_waiops_storageClassLargeBlock
  }
  
  layer              = "services"
  type               = "instances"
  application_branch = "main"
  namespace          = var.namespace
  pullsecret_name    = var.pullsecret_name
  layer_config       = var.gitops_config[local.layer]
}

module "setup_clis" {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

##### --------- --------- ---------  Pre Install  --------- --------- ---------  

module pull_secret {
  source = "github.com/cloud-native-toolkit/terraform-gitops-pull-secret"

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  server_name = var.server_name
  kubeseal_cert = var.kubeseal_cert
  namespace = var.namespace
  docker_username = "cp"
  docker_password = var.entitlement_key
  docker_server   = "cp.icr.io"
  secret_name     = var.image_pullsecret_name
}

##### --------- --------- ---------  Catalog  --------- --------- ---------  

resource "null_resource" "create_yaml_catalog" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.name}-catalog'  '${local.chart_dir}-catalog' '${local.yaml_dir}-catalog'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content_catalog)
    }
  }
}

resource "null_resource" "setup_gitops_catalog" {
  depends_on = [null_resource.create_yaml_catalog]

  triggers = {
    name            = "${local.name}-catalog"
    namespace       = var.namespace
    yaml_dir        = "${local.yaml_dir}-catalog"
    server_name     = var.server_name
    layer           = "infrastructure"
    type            = "base"
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
    bin_dir         = local.bin_dir
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --delete --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

}


##### --------- --------- ---------  Subscription  --------- --------- ---------  


resource "null_resource" "create_yaml_subscription" {
    depends_on = [null_resource.setup_gitops_catalog]

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.name}-subscription'  '${local.chart_dir}-subscription' '${local.yaml_dir}-subscription'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content_subscription)
    }
  }
}

resource "null_resource" "setup_gitops_subscription" {
  depends_on = [null_resource.create_yaml_subscription]

  triggers = {
    name            = "${local.name}-subscription"
    namespace       = var.namespace
    yaml_dir        = "${local.yaml_dir}-subscription"
    server_name     = var.server_name
    layer           = "services"
    type            = "operators"
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
    bin_dir         = local.bin_dir
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --delete --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

}

##### --------- --------- ---------  Instance  --------- --------- ---------  

resource "null_resource" "create_yaml_instance" {
    depends_on = [null_resource.setup_gitops_subscription]

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.name}-instance'  '${local.chart_dir}-instance' '${local.yaml_dir}-instance'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content_instance)
    }
  }
}

resource "null_resource" "setup_gitops_instance" {
  depends_on = [null_resource.create_yaml_instance]

  triggers = {
    name            = "${local.name}-instance"
    namespace       = var.namespace
    yaml_dir        = "${local.yaml_dir}-instance"
    server_name     = var.server_name
    layer           = "services"
    type            = "instances"
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
    bin_dir         = local.bin_dir
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --delete --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

}


##### --------- --------- ---------  Post Install  --------- --------- ---------  

resource null_resource run_post_install {
  depends_on = [null_resource.setup_gitops_instance]

  provisioner "local-exec" {
    command = "${path.module}/scripts/run-post-install.sh"

    environment = {
      IBMCLOUD_API_KEY = var.ibmcloud_api_key
      NAMESPACE = var.namespace
    }
  }
}
