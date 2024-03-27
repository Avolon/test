terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.65.0"
    }
  }
}

provider "yandex" {
  service_account_key_file = file("~/ansible.json")
  cloud_id                 = "ansible"
  folder_id                = "b1g47cmuasifjjhsj7ah"
  zone                     = "ru-central1-a"
}

variable "vm_names" {
  type        = list(string)
  description = "Список имен виртуальных машин"
  default     = ["vm1", "vm2", "vm3"]
}

variable "folder_id" {
  description = "ID папки, где будут создаваться виртуальные машины"
  type        = string
  default     = "b1g47cmuasifjjhsj7ah"
}

data "yandex_compute_image" "ubuntu_image" {
  family = "ubuntu-2004-lts"
}

data "yandex_compute_image" "centos_image" {
  family = "centos-stream-8"
}

resource "yandex_vpc_network" "network" {
  name      = "my-network"
  folder_id = var.folder_id
}

resource "yandex_vpc_subnet" "internal_subnet" {
  count      = length(var.vm_names)
  name       = "internal-subnet-${var.vm_names[count.index]}"
  folder_id  = var.folder_id
  zone       = "ru-central1-a"
  network_id = yandex_vpc_network.network.id
  v4_cidr_blocks = [
    "192.168.${10 + count.index}.0/24",
  ]
}

#resource "yandex_vpc_address" "external_address" {
#  count       = length(var.vm_names)
#  name        = "external-address-${var.vm_names[count.index]}"
#  folder_id   = var.folder_id
#  description = "External address for ${var.vm_names[count.index]}"
#}

resource "yandex_compute_instance" "vms" {
  count = length(var.vm_names)

  name = var.vm_names[count.index]
  zone = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
}
  boot_disk {
    initialize_params {
      image_id = var.vm_names[count.index] == "vm3" ? data.yandex_compute_image.centos_image.id : data.yandex_compute_image.ubuntu_image.id
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.internal_subnet[count.index].id
    nat       = true
#    nat_ip_address = yandex_vpc_address.external_address[count.index].address
  }

  metadata = {
    user-data = "${file("/home/avolon/cloud-config")}"
    ssh-keys = "avolon:${file("~/.ssh/id_rsa.pub")}"
#   serial-port-enable = "true"

  }
}
