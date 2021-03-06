resource "openstack_compute_instance_v2" "db-server" {

        depends_on = ["openstack_compute_instance_v2.salt_master"]

  	image_id = "${var.image_id}"
	flavor_name = "s1.huge"
	security_groups = ["butler-internal"]
	name = "db-server"
	network = {
		uuid = "${var.main_network_id}"
	}
	connection {
		user = "${var.user}"
	 	private_key = "${file(var.key_file)}"
	 	bastion_private_key = "${file(var.bastion_key_file)}"
	 	bastion_host = "${var.bastion_host}"
	 	bastion_user = "${var.bastion_user}"
	 	agent = true
	 	
	}
	key_pair = "${var.key_pair}"
	provisioner "remote-exec" {
		inline = [
		    "sudo yum install epel-release -y",
		    "sudo yum -y update",
		    "sudo yum install yum-plugin-priorities -y",
		    "sudo yum install -y https://repo.saltstack.com/yum/redhat/salt-repo-2016.11-2.el7.noarch.rpm",
			"sudo yum install salt-minion -y",
			"sudo service salt-minion stop",
			"echo 'master: ${null_resource.masterip.triggers.address}' | sudo tee  -a /etc/salt/minion",
			"echo 'id: db-server' | sudo tee -a /etc/salt/minion",
			"echo 'roles: [db-server, consul-client]' | sudo tee -a /etc/salt/grains",
			"sudo hostname db-server",
			"sudo service salt-minion start"
		]
	}
}

