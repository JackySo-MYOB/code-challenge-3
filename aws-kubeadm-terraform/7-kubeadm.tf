data "template_file" "master-userdata" {
    template = "${file("${var.master-userdata}")}"

    vars {
        k8stoken = "${var.k8stoken}"
    }
}

data "template_file" "worker-userdata" {
    template = "${file("${var.worker-userdata}")}"

    vars {
        k8stoken = "${var.k8stoken}"
        masterIP = "${aws_instance.controller_etcd.private_ip}"
    }
}

data "template_file" "etcd-userdata" {
    template = "${file("${var.etcd-userdata}")}"

    vars {
        k8stoken = "${var.k8stoken}"
        masterIP = "${aws_instance.controller_etcd.private_ip}"
    }
}

############
## Outputs
############

output "kubernetes_master" {
  value = "${join(",", aws_instance.controller_etcd.*.public_ip)}"
}