data "external" "example" { 
  program = ["./get-oneclient-version-json.sh"] 
} 

resource "openstack_compute_instance_v2" "worker" {

  availability_zone = "${var.availability_zone}"
  flavor_name     = "${var.worker_flavor}"
  security_groups = ["${openstack_compute_secgroup_v2.allow-traffic.name}", "${var.main_security_group_name}"]
  name            = "${var.namespace}-worker-${count.index}"

  block_device {
    uuid = "${var.image_id}"
    source_type = "image"
    volume_size = "${var.disk_size_gb}"
    boot_index = 0
    destination_type = "volume"
    delete_on_termination = true
  }

  network = {
    uuid = "${var.main_network_uuid}"
  }

  connection {
    user                = "${var.user}"
    private_key         = "${file(var.key_file)}"
#    bastion_private_key = "${file(var.bastion_key_file)}"
#    bastion_host        = "${var.bastion_host_ip}"
#    bastion_user        = "${var.bastion_user}"
    agent               = false
  }

  count    = "${var.worker_count}"
  key_pair = "${var.key_pair}"

  provisioner "file" {
    source      = "salt-setup.sh"
    destination = "/home/${var.user}/salt-setup.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.user}/salt-setup.sh",
    ]
  }

  provisioner "file" {
    source      = "mount-oneclient.sh"
    destination = "/home/${var.user}/mount-oneclient.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.user}/mount-oneclient.sh",
      "/home/${var.user}/mount-oneclient.sh ${var.oneclient_token} ${data.external.example.result.vsn}"
    ]
  }

  #
  # This sets the reference genome to the complete reference genome, via the oneclient mount
  provisioner "file" {
    source      = "set-freebayes-reference-genome.sh"
    destination = "/home/${var.user}/set-freebayes-reference-genome.sh"
  }
  provisioner "remote-exec" {
    inline = [
       "chmod +x /home/${var.user}/set-freebayes-reference-genome.sh",
       "sudo /home/${var.user}/set-freebayes-reference-genome.sh",
    ]
  }

}
