// DEFINE STATEMENTS TO INCREASE SPEED
#undef LWIP_TCP
#undef LWIP_DHCP
// #undef CHECKSUM_CHECK_UDP
// #undef LWIP_CHECKSUM_ON_COPY
// #undef CHECKSUM_GEN_UDP

#include <stdio.h>

#include "netif/xadapter.h"
#include "platform.h"
#include "platform_config.h"
#include "xparameters.h"
#if defined(__arm__) || defined(__aarch64__)
#include "xil_printf.h"
#endif

#include "includes.h"
#include "lwip/udp.h"
#include "math.h"
#include "sleep.h"
#include "xgpio.h"
#include "xil_cache.h"
#include "xspips.h"

#define PI 3.14159265359

int start_application();

void lwip_init();

extern volatile int TcpFastTmrFlag;
extern volatile int TcpSlowTmrFlag;
/* set up netif stuctures */
static struct netif server_netif;
struct netif *echo_netif;

// Global variables for data flow
volatile u32 EthBytesReceived;

// Global Variables for Ethernet handling
u16_t RemotePort = 12345;
struct ip4_addr RemoteAddr;
struct udp_pcb send_pcb;

void print_ip(char *msg, struct ip4_addr *ip) {
  print(msg);
  xil_printf("%d.%d.%d.%d\n\r", ip4_addr1(ip), ip4_addr2(ip), ip4_addr3(ip), ip4_addr4(ip));
}

void print_ip_settings(struct ip4_addr *ip, struct ip4_addr *mask, struct ip4_addr *gw) {
  print_ip("Board IP: ", ip);
  print_ip("Netmask : ", mask);
  print_ip("Gateway : ", gw);
}

int main() {
  struct ip4_addr ipaddr, netmask, gw /*, Remotenetmask, Remotegw*/;
  struct pbuf *psnd;
  struct pbuf *psnd_sep;
  err_t udpsenderr;
  int status = 0;

  /* the mac address of the board. this should be unique per board */
  unsigned char mac_ethernet_address[] = {0x00, 0x0a, 0x35, 0x00, 0x01, 0x10};

  /* Use the same structure for the server and the echo server */
  echo_netif = &server_netif;
  init_platform();

  /* initialize IP addresses to be used */
  IP4_ADDR(&ipaddr, 192, 168, 88, 253);
  IP4_ADDR(&netmask, 255, 255, 255, 0);
  IP4_ADDR(&gw, 10, 0, 0, 1);

  IP4_ADDR(&RemoteAddr, 192, 168, 88, 246);  // IP address of PC. Use `hostname -I` to find it.
  // IP4_ADDR(&Remotenetmask, 255, 255, 155,  0);
  // IP4_ADDR(&Remotegw,      10, 0,   0,  1);

  /* Initialize the lwip for UDP */
  lwip_init();

  /* Add network interface to the netif_list, and set it as default */
  if (!xemac_add(echo_netif, &ipaddr, &netmask, &gw, mac_ethernet_address, PLATFORM_EMAC_BASEADDR)) {
    xil_printf("Error adding N/W interface\n\r");
    return -1;
  }
  netif_set_default(echo_netif);

  /* now enable interrupts */
  platform_enable_interrupts();

  /* specify that the network if is up */
  netif_set_up(echo_netif);

  xil_printf("--- FPGA board IP settings: ---\r\n");
  print_ip_settings(&ipaddr, &netmask, &gw);
  xil_printf("--- Target PC settings: --- \r\n");
  print_ip("IP: ", &RemoteAddr);

  /* start the application (web server, rxtest, txtest, etc..) */
  status = start_application();
  if (status != 0) {
    xil_printf("Error in start_application() with code: %d\n\r", status);
  }

  // structure of data to be sent to PC:
  // (excluding overhead)

  // C0: 128 kHz sampling rate x 10 channels x 32 bits = 40.96 Mbit/s
  // these are the raw measurements, for debugging

  // C1: 8 kHz sampling rate x 1 channels x 32 bit = 256 kbit/s
  // OPD measurement

  // C2: 1 kHz x 8 ch x 32 bits = 256 kbit/s
  // shear: x1, y1, x2, y2
  // pointing: alpha1, beta1, alpha2, beta2


  // test data:
  // C0: 128 kHz sampling rate x 2 channel x 32 bits
  // + 1 x 32 bit counter
  // = 3 channels


  xil_printf("Initializing payload containers\n\r");
  // max payload size: 1500 bytes = 12000 bits = 375 int (32 bits each)
  const int num_channels = 3;
  const int num_timepoints = 10;
  int payload_size = num_channels * num_timepoints;
  int payload[payload_size];
  int pkg_no = 0;
  int vals_idx = 0;


  // current AXI GPIO setup:
  // gpio0 -> sync
  // gpio1 -> (OPD_x, OPD_y)

  



  // activate the GPIOs, two channels each, data direction: read
  xil_printf("Initializing GPIO\n\r");
  const int num_xgpio_instances = 10;
  XGpio xgpio_in[num_xgpio_instances];

  for (int i = 0; i < num_xgpio_instances; i++) {
      XGpio_Initialize(&xgpio_in[i], XPAR_AXI_GPIO_0_DEVICE_ID + i); // works in practice
      XGpio_SetDataDirection(&xgpio_in[i], 1, 1); // (instance pointer, channel, direction mask)
      XGpio_SetDataDirection(&xgpio_in[i], 2, 1);
  }

  /* receive and process packets */

  // chatgpt suggestion:
  xil_printf("Performing pcb stuff\n\r");
  err_t err;
  struct udp_pcb *pcb;

  /* Create a new UDP PCB */
  pcb = udp_new();
  if (pcb == NULL) {
    xil_printf("Error creating UDP PCB\n\r");
    return -1;
  }

  /* Bind the PCB to a local port */
  err = udp_bind(pcb, IP_ADDR_ANY, 0);
  if (err != ERR_OK) {
    xil_printf("Error binding UDP PCB\n\r");
    udp_remove(pcb);
    return -1;
  }

  /* Set the remote IP address and port */
  xil_printf("Setting remote IP address and port\n\r");
  ip4_addr_set_u32(&pcb->remote_ip, RemoteAddr.addr);
  pcb->remote_port = htons(RemotePort);

  /* Save the PCB to the global variable */
  send_pcb = *pcb;

  // counters
  int32_t count_pos, prev_count_pos, count_opd, prev_count_opd, phase_int;

  // fpga signals
  int32_t x1_int, i1_int, x2_int, i2_int, x_opd_int, y_opd_int;

  // derived values
  double x1, i1, x2, i2, x_opd, y_opd, phase_d, prev_phase_d;

  double x1d, x2d;           // corrected x and y positions
  int32_t x1d_int, x2d_int;  // corrected x and y positions

  prev_count_pos = 0;
  prev_count_opd = 0;

  xil_printf("Starting loop\n\r");

  while (1) {
    // Get the current value of the count_pos
    count_opd = XGpio_DiscreteRead(&xgpio_in[0], 1);

    // printf("%d\n\r", count_opd);

    // x_opd_int = XGpio_DiscreteRead(&xgpio_in1, 1);
    // printf("%d\n\r", x_opd_int);


    // if the count_pos is exactly 1 higher than the previous count_pos, we have a new value, and we perform the
    // processing. Otherwise, wait 10 us and try again
    // TODO use interrupts for this

    // calculate position and send
    if (count_opd == prev_count_opd + 1) {
      // if (1) {
      // x1_int = XGpio_DiscreteRead(&xgpio_in[1], 1);
      // i1_int = XGpio_DiscreteRead(&xgpio_in[2], 1);
      // x2_int = XGpio_DiscreteRead(&xgpio_in[3], 1);
      // i2_int = XGpio_DiscreteRead(&xgpio_in[4], 1);
      x_opd_int = XGpio_DiscreteRead(&xgpio_in[1], 1);
      y_opd_int = XGpio_DiscreteRead(&xgpio_in[1], 2);

      // print raw values
      // printf("     %d, %d, %d, %d, %d, %d\n\r", x1_int, i1_int, x2_int, i2_int, x_opd_int, y_opd_int);

      // cast to doubles
      // x1 = (double)x1_int;  // x1
      // i1 = (double)i1_int;  // i1
      // x2 = (double)x2_int;  // x2
      // i2 = (double)i2_int;  // i2
      x_opd = (double)x_opd_int;
      y_opd = (double)y_opd_int;

      // calculate the positions: xn = xn/in
      // x1d = x1; /// i1;
      // x2d = x2; // / i2;

      // calculate the phase using atan2
      phase_d = -atan2(y_opd, x_opd);

      // convert from rad to deg
      phase_d = phase_d * 180. / PI;

      // unwrap the phase
      if (phase_d < prev_phase_d - 180) {
        phase_d += 360;
      } else if (phase_d > prev_phase_d + 180) {
        phase_d -= 360;
      }

      // set the previous phase to the current phase
      prev_phase_d = phase_d;

      // printf("%d\n\r", x1_int);

      // printf("x_int: %f, y_int: %f, phase: %f\n\r", x_d, y_d, phase_d);
      // printf("phase: %f\n\r", phase_d);


      // printf("%d\n\r", phase_int);

      // convert to nm
      phase_d = phase_d * 1550 / 360;

      // convert pos to um
      // x1d = x1d;// * 1.11e3;
      // x2d = x2d;// * 1.11e3;

      // print floats
      // printf("%f, %f, %f\n\r", x1d, x2d, phase_d);

      // convert to fixed point for sending
      // i1_int = (int32_t)(i1 * 1000); //
      // i2_int = (int32_t)(i2 * 1000); //
      // x1d_int = (int32_t)(x1d * 1000); // nm
      // x2d_int = (int32_t)(x2d * 1000); // nm
      phase_int = (int32_t)(phase_d * 1000);  // pm

      // store count_pos and phase_int in payload
      // payload[2 * vals_idx] = count_pos;
      // payload[2 * vals_idx + 1] = phase_int;

      // store count_pos and adc readings in payload
      payload[num_channels * vals_idx] = count_opd;
      payload[num_channels * vals_idx + 1] = x_opd_int;
      payload[num_channels * vals_idx + 2] = y_opd_int;

      /* Receive packets */
      // Deleting this somehow makes the sending stop working
      xemacif_input(echo_netif);

      // if payload is full, send it
      if (vals_idx == 9) {
        // print the package number
        // xil_printf("Package %d\n\r", pkg_no);

        // set the payload to the phases array
        psnd = pbuf_alloc(PBUF_TRANSPORT, payload_size * sizeof(int), PBUF_REF);
        psnd->payload = &payload;

        // send the package
        udpsenderr = udp_sendto(&send_pcb, psnd, &RemoteAddr, RemotePort);
        pbuf_free(psnd);

        // reset the vals_idx
        vals_idx = 0;

        // increase the package number
        pkg_no++;

        // print "*" every 128k readings (= 1s)
        if (pkg_no % 12800 == 0) {
          xil_printf("*");
        }
      } else {
        vals_idx++;
      }
    }

    // set the previous counter to the current counter
    prev_count_opd = count_opd;

    // usleep(10000);
  }

  cleanup_platform();
  return 0;
}
