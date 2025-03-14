#pragma once

#include <xil_types.h>

#include "lwip/ip4_addr.h"  // Include for ip4_addr struct

namespace NetworkConfig {
// Default MAC address for the FPGA board
const unsigned char MAC_ADDRESS[6] = {0x00, 0x0a, 0x35, 0x00, 0x01, 0x10};

// FPGA IP configuration - pre-defined as ip4_addr structures
const ip4_addr FPGA_IP_ADDR = {PP_HTONL(LWIP_MAKEU32(192, 168, 88, 253))};
const ip4_addr FPGA_NETMASK = {PP_HTONL(LWIP_MAKEU32(255, 255, 255, 0))};
const ip4_addr FPGA_GATEWAY = {PP_HTONL(LWIP_MAKEU32(10, 0, 0, 1))};

// Remote host (PC) configuration
const ip4_addr REMOTE_IP_ADDR = {PP_HTONL(LWIP_MAKEU32(192, 168, 88, 243))};
const u16_t REMOTE_PORT = 12345;
}  // namespace NetworkConfig
