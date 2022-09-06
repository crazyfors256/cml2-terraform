output "server_urls" {
	value = join(", ", formatlist("https://%s/", openstack_compute_floatingip_associate_v2.cml2_fip[*].floating_ip))

  depends_on = [null_resource.check_http]
}

output "cml2_login" {
  value = "admin"

  depends_on = [null_resource.check_http]
}

output "cml2_password" {
  value = var.cml2_password

  depends_on = [null_resource.change_cml2_password]
}
