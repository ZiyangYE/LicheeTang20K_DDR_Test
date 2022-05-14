# LicheeTang20K_DDR_Test
The DDR Test Firmware for LicheeTang20K.

## Environment
GOWIN FPGA Designer V1.9.8.05 

## Output
8-bit data, 1 stop bit, no parity, 115200 baud 

## Others
Perform Reset Every 100s.  
The fill rate and the check rate is limited by the LFSR. Whose output rate is about 12MBps.  
For a 1Gbits version, each fill/check stage will consumes about 11s.  
And for a 2Gbits version, each fill/check stage will consumes about 22s.  

---

In this firmware, the DDR3 interface belongs to GOWIN. And is limited to be used in the GOWIN FPGA Designer.  
I will publish a COPYLEFT version of this firmware later, with a DDR3 interface I wrote myself __(A SUPER SIMPLE DDR INTERFACE wo Minimum Freqency Constraints)__.  
