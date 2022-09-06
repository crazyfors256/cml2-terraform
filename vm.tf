data "openstack_images_image_v2" "cml2_image" {
  most_recent = true
  visibility  = "shared"
  name        = "cml2-image"
}

resource "random_string" "cml2_random_name" {
  count   = var.replicas
  length  = 8
  special = false
}

resource "openstack_compute_flavor_v2" "cml2_flavor" {
  count     = var.replicas
  name      = "cml2-${random_string.cml2_random_name[count.index].result}-flavor"
  ram       = "4096"
  vcpus     = "2"
  disk      = "32"
  is_public = "false"
}

resource "openstack_compute_instance_v2" "cml2_server" {
  count           = var.replicas
  name            = "cml2-${random_string.cml2_random_name[count.index].result}-server"
  image_id        = data.openstack_images_image_v2.cml2_image.id
  flavor_id       = openstack_compute_flavor_v2.cml2_flavor[count.index].id
  availability_zone = "ru-3a"

  network {
    uuid = openstack_networking_network_v2.cml2_network[count.index].id
  }

  vendor_options {
    ignore_resize_confirmation = true
  }

  depends_on = [openstack_networking_subnet_v2.cml2_subnet, openstack_networking_router_interface_v2.cml2_router_interface]
}

resource "openstack_compute_floatingip_associate_v2" "cml2_fip" {
  count = var.replicas
  floating_ip = openstack_networking_floatingip_v2.cml2_fip[count.index].address
  instance_id = openstack_compute_instance_v2.cml2_server[count.index].id
}

resource "null_resource" "check_http" {
  count = var.replicas
  
  provisioner "local-exec" {
    command = "./scripts/curl.sh ${openstack_networking_floatingip_v2.cml2_fip[count.index].address}"
    interpreter = ["bash", "-c"]
  }

  depends_on = [openstack_compute_floatingip_associate_v2.cml2_fip]
}

resource "null_resource" "change_os_password" {
  count = var.replicas

  connection {
    type     = "ssh"
    user     = "sysadmin"
    password = var.current_os_password
    port     = 1122
    host     = openstack_networking_floatingip_v2.cml2_fip[count.index].address
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.current_os_password} | sudo -S echo sysadmin:${var.os_password} | sudo -S chpasswd"
    ]
  }

  depends_on = [null_resource.check_http]
}

resource "null_resource" "change_cml2_password" {
  count = var.replicas
  
  provisioner "local-exec" {
    command = "./scripts/cml2-change-pass.sh ${openstack_networking_floatingip_v2.cml2_fip[count.index].address} ${var.current_cml2_password} ${var.cml2_password}"
    interpreter = ["bash", "-c"]
  }

  depends_on = [null_resource.check_http]
}