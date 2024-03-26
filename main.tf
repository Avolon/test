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

variable "internal_ips" {
  type        = map(string)
  description = "Список внутренних IP-адресов для виртуальных машин"
  default     = {
    vm1 = "192.168.10.1"
    vm2 = "192.168.10.2"
    vm3 = "192.168.10.3"
  }
}

variable "folder_id" {
  description = "ID папки, где будут создаваться виртуальные машины"
}

data "yandex_compute_image" "ubuntu_image" {
  family = "ubuntu-2004-lts"
}

data "yandex_compute_image" "centos_image" {
  family = "centos-stream-8"
}

resource "yandex_compute_instance" "vms" {
  count = length(var.vm_names)

  name = var.vm_names[count.index]
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20 #отключаемая и горонтированный процент
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_names[count.index] == "vm3" ? data.yandex_compute_image.centos_image.id : data.yandex_compute_image.ubuntu_image.id
      size     = 20
    }
  }

  network_interface {
    subnet_id = "default-ru-central1-a"
    ip_address = var.internal_ips[var.vm_names[count.index]]
  }

  metadata = {
    ssh-keys = "avolon:${file("~/.ssh/id_rsa.pub")}"
  }
}
