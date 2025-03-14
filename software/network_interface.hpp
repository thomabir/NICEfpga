#pragma once

#include <stdio.h>
#include <string.h>
#include <xil_types.h>

#include "lwip/err.h"
#include "lwip/init.h"
#include "lwip/udp.h"
#include "netif/xadapter.h"
#include "network_config.hpp"  // Include the network configuration
#include "platform_config.h"
#include "xil_printf.h"

class NetworkInterface {
 private:
  struct netif server_netif;
  struct netif* echo_netif;
  struct udp_pcb* pcb;
  struct ip4_addr remote_addr;
  struct ip4_addr ipaddr;
  struct ip4_addr netmask;
  struct ip4_addr gw;
  u16_t remote_port;
  struct pbuf* send_buffer;
  unsigned char mac_ethernet_address[6];

  void print_ip(char* msg, struct ip4_addr* ip) {
    print(msg);
    xil_printf("%d.%d.%d.%d\n\r", ip4_addr1(ip), ip4_addr2(ip), ip4_addr3(ip),
               ip4_addr4(ip));
  }

  void print_ip_settings(struct ip4_addr* ip, struct ip4_addr* mask,
                         struct ip4_addr* gw) {
    print_ip("Board IP: ", ip);
    print_ip("Netmask : ", mask);
    print_ip("Gateway : ", gw);
  }

  void configure_ip_settings() {
    /* Copy pre-configured IP addresses */
    ipaddr = NetworkConfig::FPGA_IP_ADDR;
    netmask = NetworkConfig::FPGA_NETMASK;
    gw = NetworkConfig::FPGA_GATEWAY;
    remote_addr = NetworkConfig::REMOTE_IP_ADDR;
  }

  int init_network_interface() {
    /* Initialize the lwip for UDP */
    lwip_init();

    /* Add network interface to the netif_list, and set it as default */
    if (!xemac_add(echo_netif, &ipaddr, &netmask, &gw, mac_ethernet_address,
                   PLATFORM_EMAC_BASEADDR)) {
      xil_printf("Error adding N/W interface\n\r");
      return -1;
    }

    netif_set_default(echo_netif);

    /* specify that the network if is up */
    netif_set_up(echo_netif);

    return 0;
  }

  int init_send_connection() {
    /* Create a new UDP PCB */
    pcb = udp_new();
    if (pcb == NULL) {
      xil_printf("Error creating UDP PCB for sending\n\r");
      return -1;
    }

    /* Bind to any local address and port */
    err_t err = udp_bind(pcb, IP_ADDR_ANY, 0);
    if (err != ERR_OK) {
      xil_printf("Error binding UDP PCB for sending\n\r");
      udp_remove(pcb);
      return -1;
    }

    /* Set the remote IP address and port for the connection */
    xil_printf("Setting remote IP address and port\n\r");
    ip4_addr_set_u32(&(pcb->remote_ip), remote_addr.addr);
    pcb->remote_port = htons(remote_port);

    return 0;
  }

 public:
  NetworkInterface() {
    // Set default MAC address from configuration
    memcpy(mac_ethernet_address, NetworkConfig::MAC_ADDRESS, 6);

    echo_netif = &server_netif;
    pcb = NULL;
    remote_port = NetworkConfig::REMOTE_PORT;
    send_buffer = NULL;

    // Initialize IP addresses
    configure_ip_settings();
  }

  /**
   * Initialize the network interface with the given parameters
   *
   * @param payload_size Size of the payload buffer in bytes
   * @return 0 on success, negative value on failure
   */
  int init(int payload_size) {
    // Initialize network interface
    if (init_network_interface() != 0) {
      return -1;
    }

    // Print IP information
    xil_printf("--- FPGA board IP settings: ---\r\n");
    print_ip_settings(&ipaddr, &netmask, &gw);
    xil_printf("--- Target PC settings: --- \r\n");
    print_ip("IP: ", &remote_addr);

    // Initialize UDP for sending
    if (init_send_connection() != 0) {
      xil_printf("Error initializing UDP send connection\n\r");
      return -2;
    }

    // Allocate packet buffer with the given size
    send_buffer = pbuf_alloc(PBUF_TRANSPORT, payload_size, PBUF_REF);
    if (send_buffer == NULL) {
      xil_printf("Error allocating packet buffer\n\r");
      return -3;
    }

    return 0;
  }

  /**
   * Send data over UDP
   *
   * @param data Pointer to the data to send
   * @return 0 on success, negative value on failure
   */
  int send(void* data) {
    if (send_buffer == NULL) {
      xil_printf("Error allocating packet buffer\n\r");
      return -1;
    }

    send_buffer->payload = data;
    err_t err = udp_sendto(pcb, send_buffer, &remote_addr, remote_port);

    if (err != ERR_OK) {
      xil_printf("Error sending UDP packet: %d\n\r", err);
      return -2;
    }

    // Process any incoming packets (needed for proper network functioning)
    xemacif_input(echo_netif);

    return 0;
  }
};
