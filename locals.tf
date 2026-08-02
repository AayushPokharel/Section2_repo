# locals.tf
locals {
  # Consistent naming: <type>-<project>-<env>-<region>
  name_prefix = "${var.project}-${var.environment}-${var.location_short}"

  common_tags = merge(
    {
      project     = var.project
      environment = var.environment
      managed_by  = "terraform"
      cost_center = "platform-engineering"
    },
    var.extra_tags
  )
}
