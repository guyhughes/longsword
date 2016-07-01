#!/bin/sh
main_switch () {
  ACTION="$1"
  shift
  case "$ACTION" in
    d*)
      deps
      ;;
    i*)
      init "$@"
      ;;
    k*)
      kill "$@"
      ;;
    r*)
      restart "$@"
      ;;
    *)
      printf "fatal\n"
      print_usage
      exit 1
      ;;
  esac
}
print_usage () {
      printf "USAGE:\t$0 [deps|init|kill|restart]\n"
      printf "\t\td[eps]                    # Dependencies install, setup\n"
      printf "\t\ti[nit] [WLAN_DEVICE_NAME] # Initialize wifi ap\n"
      printf "\t\tk[ill]                    # Kill wifi ap\n"
      printf "\t\tr[restart]                # Restart wifi ap\n"
}
deps () {
  printf "\nDownload the openvpn files to /etc/openvpn and add your secrets\s"
  set -x
  pacman -S --needed hostapd dhcpcd haveged
  systemctl enable hostapd
  systemctl enable haveged
  systemctl start haveged
  mkdir -p /etc/hostapd
  ln -s "$PWD/hostapd.conf" /etc/hostapd
  ln -s "$PWD/dhcpd.conf" /etc/dhcpd.conf
}


init () {
  WLAN="wlo1"
  [ -n "$1" ] && WLAN="$1"

  iptables-restore iptables.save
  sysctl -w net.ipv4.ip_forward=1 &>/dev/null

  #transparent proxying on $WLAN assuming the clients have custom gateway set, disable ICMP redirects
  echo 0 > /proc/sys/net/ipv4/conf/$WLAN/send_redirects

  systemctl restart hostapd
  systemctl restart dhcpd4

  ip link set "$WLAN" type wlan
  ifconfig "$WLAN" 192.168.25.1 netmask 255.255.255.0
  ip link set "$WLAN" up
}
kill () {
  pkill hostapd
  systemctl stop hostapd
  systemctl stop dhcpd4
}
restart () {
  set -x
  pkill -USR1 openpvn
  set +x
  init "$@"
}

main_switch "$@"
