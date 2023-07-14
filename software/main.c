// DEFINE STATEMENTS TO INCREASE SPEED
#undef LWIP_TCP
#undef LWIP_DHCP
// #undef CHECKSUM_CHECK_UDP
// #undef LWIP_CHECKSUM_ON_COPY
// #undef CHECKSUM_GEN_UDP

#include <stdio.h>

#include "xparameters.h"

#include "netif/xadapter.h"

#include "platform.h"
#include "platform_config.h"
#if defined(__arm__) || defined(__aarch64__)
#include "xil_printf.h"
#endif

#include "xgpio.h"

#include "lwip/udp.h"
#include "xil_cache.h"
#include "includes.h"

#include "sleep.h"

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
u16_t RemotePort = 8;
struct ip4_addr RemoteAddr;
struct udp_pcb send_pcb;

void print_ip(char *msg, struct ip4_addr *ip)
{
	print(msg);
	xil_printf("%d.%d.%d.%d\n\r", ip4_addr1(ip), ip4_addr2(ip),
			   ip4_addr3(ip), ip4_addr4(ip));
}

void print_ip_settings(struct ip4_addr *ip, struct ip4_addr *mask, struct ip4_addr *gw)
{

	print_ip("Board IP: ", ip);
	print_ip("Netmask : ", mask);
	print_ip("Gateway : ", gw);
}

void print_app_header()
{
	xil_printf("\n\r\n\r------lwIP UDP GetCentroid Application------\n\r");
	xil_printf("UDP packets sent to port 7 will be processed\n\r");
}

int main()
{
	struct ip4_addr ipaddr, netmask, gw /*, Remotenetmask, Remotegw*/;
	struct pbuf *psnd;
	struct pbuf *psnd_sep;
	err_t udpsenderr;
	int status = 0;

	/* the mac address of the board. this should be unique per board */
	unsigned char mac_ethernet_address[] =
		{0x00, 0x0a, 0x35, 0x00, 0x01, 0x10};

	/* Use the same structure for the server and the echo server */
	echo_netif = &server_netif;
	init_platform();

	/* initialize IP addresses to be used */
	IP4_ADDR(&ipaddr, 192, 168, 88, 253);
	IP4_ADDR(&netmask, 255, 255, 255, 0);
	IP4_ADDR(&gw, 10, 0, 0, 1);

	IP4_ADDR(&RemoteAddr, 192, 168, 88, 254);
	// IP4_ADDR(&Remotenetmask, 255, 255, 255,  0);
	// IP4_ADDR(&Remotegw,      10, 0,   0,  1);

	print_app_header();

	/* Initialize the lwip for UDP */
	lwip_init();

	/* Add network interface to the netif_list, and set it as default */
	if (!xemac_add(echo_netif, &ipaddr, &netmask,
				   &gw, mac_ethernet_address,
				   PLATFORM_EMAC_BASEADDR))
	{
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
	if (status != 0)
	{
		xil_printf("Error in start_application() with code: %d\n\r", status);
	}

	int pkg_no = 0;
	int vals_idx = 0;

	XGpio xgpio_in1;

	int32_t val;
	uint8_t counter, prev_counter;
	int vals[10];

	XGpio_Initialize(&xgpio_in1, XPAR_AXI_GPIO_0_DEVICE_ID);
	XGpio_SetDataDirection(&xgpio_in1, 1, 1);

	/* receive and process packets */

	// chatgpt suggestion:
	err_t err;
	struct udp_pcb *pcb;

	/* Create a new UDP PCB */
	pcb = udp_new();
	if (pcb == NULL)
	{
		xil_printf("Error creating UDP PCB\n\r");
		return -1;
	}

	/* Bind the PCB to a local port */
	err = udp_bind(pcb, IP_ADDR_ANY, 0);
	if (err != ERR_OK)
	{
		xil_printf("Error binding UDP PCB\n\r");
		udp_remove(pcb);
		return -1;
	}

	/* Set the remote IP address and port */
	ip4_addr_set_u32(&pcb->remote_ip, RemoteAddr.addr);
	pcb->remote_port = htons(RemotePort);

	/* Save the PCB to the global variable */
	send_pcb = *pcb;

	

	while (1)
	{

		// Get the current value via xgpio
		val = XGpio_DiscreteRead(&xgpio_in1, 1);

		// the 8 MSB are a counter, the other 24 bits are the value
		counter = val >> 24;
		// val = val & 0x00FFFFFF;

		// if the counter is exactly 1 higher than the previous counter, we have a new value, and we perform the processing.
		// Otherwise, wait 10 us and try again
		// TODO use interrupts for this
		if (counter == prev_counter + 1)
		{

			// store value in vector
			vals[vals_idx] = val;

			/* Receive packets */
			// Deleting this somehow makes the sending stop working
			xemacif_input(echo_netif);

			// if vals is full, send a package
			if (vals_idx == 9)
			{
				// print the package number
				// xil_printf("Package %d\n\r", pkg_no);

				// set the payload to the vals array
				psnd = pbuf_alloc(PBUF_TRANSPORT, 10 * sizeof(int), PBUF_REF);
				psnd->payload = &vals;

				// send the package
				udpsenderr = udp_sendto(&send_pcb, psnd, &RemoteAddr, RemotePort);
				pbuf_free(psnd);

				// reset the vals_idx
				vals_idx = 0;

				// increase the package number
				pkg_no++;

				// print every 64k readings
				if (pkg_no % 6400 == 0)
				{
					xil_printf("*");
				}
			}
			else
			{
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
