data "openstack_networking_network_v2" "external_network" {
  name = "external-network"
}

resource "openstack_networking_floatingip_v2" "cml2_fip" {
  count = var.replicas
  pool  = "external-network"
}

resource "openstack_networking_router_v2" "cml2_router" {
  count               = var.replicas
  name                = "cml2-${random_string.cml2_random_name[count.index].result}-router"
  external_network_id = data.openstack_networking_network_v2.external_network.id
}

resource "openstack_networking_network_v2" "cml2_network" {
  count = var.replicas
  name  = "cml2-${random_string.cml2_random_name[count.index].result}-network"
}

resource "openstack_networking_subnet_v2" "cml2_subnet" {
  count       = var.replicas
  network_id  = openstack_networking_network_v2.cml2_network[count.index].id
  name        = "cml2-${random_string.cml2_random_name[count.index].result}-subnet"
  cidr        = "192.168.0.0/24"
  gateway_ip  = "192.168.0.1"
  enable_dhcp = true
}

resource "openstack_networking_router_interface_v2" "cml2_router_interface" {
  count     = var.replicas
  router_id = openstack_networking_router_v2.cml2_router[count.index].id
  subnet_id = openstack_networking_subnet_v2.cml2_subnet[count.index].id
}