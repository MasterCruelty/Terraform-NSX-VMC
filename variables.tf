# NSX Manager
variable "nsx_manager" {
  #default = "https://nsxmanager.sddc-x-x-x-x.vmwarevmc.com/login.jsp?idp=local"
  #default = "ip address of vmc nsx manager"
  default = "nsxmanager.sddc-x-x-x-x.vmwarevmc.com"
}

# Username & Password for NSX-T Manager
variable "username" {
  default = "username"
}

variable "password" {
  default = "your_pw"
}