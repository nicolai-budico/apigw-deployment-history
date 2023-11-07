output "deployment_id" {
  value = shell_script.deploy_api.output["id"]
}
