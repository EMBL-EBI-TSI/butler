resource "null_resource" "ssh-bastion" {
#
# This updates the ~/.ssh/config file on the bastion host so that
# from there, you can just 'ssh salt-master' etc, and it will work,
# and it creates an 'ssh-config' file locally that you can use to
# 'ssh -F ssh-config salt-master' etc, and that will work too.
#
  depends_on = [
                  "openstack_compute_instance_v2.db-server",
                  "openstack_compute_instance_v2.job-queue",
                  "openstack_compute_instance_v2.salt-master",
                  "openstack_compute_instance_v2.tracker",
                  "openstack_compute_instance_v2.worker"
               ]

  triggers {
    something = "${uuid()}" # trigger on random number, i.e. run every time
  }

  provisioner "local-exec" {
    command = <<EOF
/bin/rm -f ssh-config.bastion
(
  echo "Host *"
  echo "  User      ${var.user}"
  echo "  StrictHostKeyChecking   no"
  echo "  IdentityFile ${var.key_file}"
  echo "  UserKnownHostsFile /dev/null"
  echo " "
  echo "Host salt-master"
  echo "  HostName ${openstack_compute_instance_v2.salt-master.access_ip_v4}"
  echo " "
  echo "Host db-server"
  echo "  HostName ${openstack_compute_instance_v2.db-server.access_ip_v4}"
  echo " "
  echo "Host tracker"
  echo "  HostName ${openstack_compute_instance_v2.tracker.access_ip_v4}"
  echo " "
  echo "Host job-queue"
  echo "  HostName ${openstack_compute_instance_v2.job-queue.access_ip_v4}"
  echo " "
  echo "Host worker-0"
  echo "  HostName ${openstack_compute_instance_v2.worker.0.access_ip_v4}"
) | tee ssh-config.bastion
EOF
  }

  connection {
    private_key = "${file(var.bastion_key_file)}"
    host = "${var.bastion_host_ip}"
    user = "${var.bastion_user}"
    agent = false
  }

  provisioner "file" {
    source      = "ssh-config.bastion"
    destination = "/home/${var.bastion_user}/.ssh/config.bastion"
  }
  provisioner "remote-exec" {
    inline = [
      "/bin/rm -f ~/.ssh/config",
      "/bin/mv ~/.ssh/config.bastion ~/.ssh/config",
      "chmod 400 ${var.bastion_key_file} ~/.ssh/config"
    ]
  }

  provisioner "local-exec" {
    command = <<EOF
/bin/rm -f ssh-config
(
  echo "Host *"
  echo "  User      ${var.bastion_user}"
  echo "  StrictHostKeyChecking no"
  echo "  IdentityFile          ${var.bastion_key_file}"
  echo "  UserKnownHostsFile    /dev/null"
  echo "  "
  echo "Host ${var.bastion_host_name}"
  echo "  HostName ${var.bastion_host_ip}"
  echo "  "
  echo "Host salt-master"
  echo "  HostName ${openstack_compute_instance_v2.salt-master.access_ip_v4}"
  echo "  ProxyCommand ssh -i ${var.bastion_key_file} ${var.bastion_user}@${var.bastion_host_ip} -W %h:%p"
  echo " "
  echo "Host db-server"
  echo "  HostName ${openstack_compute_instance_v2.db-server.access_ip_v4}"
  echo "  ProxyCommand ssh -i ${var.bastion_key_file} ${var.bastion_user}@${var.bastion_host_ip} -W %h:%p"
  echo " "
  echo "Host tracker"
  echo "  HostName ${openstack_compute_instance_v2.tracker.access_ip_v4}"
  echo "  ProxyCommand ssh -i ${var.bastion_key_file} ${var.bastion_user}@${var.bastion_host_ip} -W %h:%p"
  echo " "
  echo "Host job-queue"
  echo "  HostName ${openstack_compute_instance_v2.job-queue.access_ip_v4}"
  echo "  ProxyCommand ssh -i ${var.bastion_key_file} ${var.bastion_user}@${var.bastion_host_ip} -W %h:%p"
  echo " "
  echo "Host worker-0"
  echo "  HostName ${openstack_compute_instance_v2.worker.0.access_ip_v4}"
  echo "  ProxyCommand ssh -i ${var.bastion_key_file} ${var.bastion_user}@${var.bastion_host_ip} -W %h:%p"
  echo " "
) | tee ssh-config
EOF
  }

}
