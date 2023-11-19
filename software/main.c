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
#include "sleep.h"
#include "xgpio.h"
#include "xspips.h"
#include "xil_cache.h"
#include "math.h"

#define PI 3.14159265359

/* defined by each RAW mode application */
void print_app_header();
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

void print_app_header() {
  xil_printf("\n\r\n\r------lwIP UDP GetCentroid Application------\n\r");
  xil_printf("UDP packets sent to port 7 will be processed\n\r");
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

  IP4_ADDR(&RemoteAddr, 192, 168, 88, 251); // IP address of PC. Use `hostname -I` to find it.
  // IP4_ADDR(&Remotenetmask, 255, 255, 155,  0);
  // IP4_ADDR(&Remotegw,      10, 0,   0,  1);

  print_app_header();

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

  int pkg_no = 0;
  int vals_idx = 0;

  XGpio xgpio_in0, xgpio_in1, xgpio_in2, xgpio_in3, xgpio_in4;

  xil_printf("Initializing payload container\n\r");
  int payload_size = 10 * 5; // 10 packages of 5 ints
  int payload[payload_size];

  xil_printf("Initializing GPIO\n\r");
  XGpio_Initialize(&xgpio_in0, XPAR_AXI_GPIO_0_DEVICE_ID);
  XGpio_SetDataDirection(&xgpio_in0, 1, 1);

  XGpio_Initialize(&xgpio_in1, XPAR_AXI_GPIO_1_DEVICE_ID);
  XGpio_SetDataDirection(&xgpio_in1, 1, 1);

  XGpio_Initialize(&xgpio_in2, XPAR_AXI_GPIO_2_DEVICE_ID);
  XGpio_SetDataDirection(&xgpio_in2, 1, 1);

  XGpio_Initialize(&xgpio_in3, XPAR_AXI_GPIO_3_DEVICE_ID);
  XGpio_SetDataDirection(&xgpio_in3, 1, 1);

  XGpio_Initialize(&xgpio_in4, XPAR_AXI_GPIO_4_DEVICE_ID);
  XGpio_SetDataDirection(&xgpio_in4, 1, 1);

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

  int32_t counter, prev_counter;
  int32_t adc1_int, adc2_int, adc3_int, adc4_int;
  double adc1, adc2, adc3, adc4;

  double x1d, x2d; // corrected x and y positions

  prev_counter = 0;

  xil_printf("Starting loop\n\r");

  while (1) {
    // Get the current value of the counter
    counter = XGpio_DiscreteRead(&xgpio_in0, 1);

    // printf("%d\n\r", counter);


    // if the counter is exactly 1 higher than the previous counter, we have a new value, and we perform the processing.
    // Otherwise, wait 10 us and try again
    // TODO use interrupts for this
    if (counter == prev_counter + 1) {


      adc1_int = XGpio_DiscreteRead(&xgpio_in1, 1);
      adc2_int = XGpio_DiscreteRead(&xgpio_in2, 1);
      adc3_int = XGpio_DiscreteRead(&xgpio_in3, 1);
      adc4_int = XGpio_DiscreteRead(&xgpio_in4, 1);


      // cast to doubles
      adc1 = (double)adc1_int; // x1
      adc2 = (double)adc2_int; // i1
      adc3 = (double)adc3_int; // x2
      adc4 = (double)adc4_int; // i2

      // calculate the positions: xn = xn/in
      x1d = adc1 / adc2;
      x2d = adc3 / adc4;

      // print
       printf("%f, %f\n\r", x1d, x2d);

      // print int values
      printf("     %d, %d, %d, %d\n\r", adc1_int, adc2_int, adc3_int, adc4_int);


      // // calculate the phase using atan2
      // phase_d = -atan2(y_d, x_d);

      // // convert from rad to deg
      // phase_d = phase_d * 180. / PI;

      // // unwrap the phase
      // if (phase_d < prev_phase_d - 180) {
      //   phase_d += 360;
      // } else if (phase_d > prev_phase_d + 180) {
      //   phase_d -= 360;
      // }

      // set the previous phase to the current phase
      // prev_phase_d = phase_d;

      // convert the phase to a fixed point number, with 3 decimal places
      // phase_int = (int32_t)(phase_d * 1000);

      // print adc1_int
      // printf("%d\n\r", adc1_int);

      // print using printf
      // printf("x_int: %f, y_int: %f, phase: %f\n\r", x_d, y_d, phase_d);

      // print phase_int
      // printf("%d\n\r", phase_int);

      // store counter and phase_int in payload
      // payload[2 * vals_idx] = counter;
      // payload[2 * vals_idx + 1] = phase_int;

      // store counter and adc readings in payload
      payload[5 * vals_idx] = counter;
      payload[5 * vals_idx + 1] = adc1_int;
      payload[5 * vals_idx + 2] = adc2_int;
      payload[5 * vals_idx + 3] = adc3_int;
      payload[5 * vals_idx + 4] = adc4_int;

      /* Receive packets */
      // Deleting this somehow makes the sending stop working
      xemacif_input(echo_netif);

      // if phases is full, send a package
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

        // print every 64k readings
        if (pkg_no % 6400 == 0) {
          xil_printf("*");
        }
      } else {
        vals_idx++;
      }
    }

    // set the previous counter to the current counter
    prev_counter = counter;

    // usleep(10000);
  }

  cleanup_platform();
  return 0;
}
