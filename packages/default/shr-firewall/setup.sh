load_setup() {
    # âctivate and configure firwalld

  sudo systemctl enable --now firewalld
  sudo systemctl start firewalld
}

unload_setup() {
  sudo systemctl stop firewalld
  sudo systemctl disable --now firewalld
  sudo systemctl clean firewalld
}