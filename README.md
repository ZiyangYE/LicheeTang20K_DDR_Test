# LicheeTang20K_DDR_Test
The DDR Test Firmware for LicheeTang20K.

## Environment
GOWIN FPGA Designer V1.9.8.05 

## Output
8-bit data, 1 stop bit, no parity, 115200 baud 

## Frequency
The DDR interface is designed to run at 80MHz (DDR-40).
But due to the limitation of the PLL, it actually runs at 81MHz.

## Others
Perform Reset Every 125s.  
The fill rate and the check rate is limited by the LFSR. Whose output rate is about 10MBps.  
For a 1Gbits version, each fill/check stage will consumes about 15s.  
And for a 2Gbits version, each fill/check stage will consumes about 29s.  

## Example Output
Perform Reset
Auto Reset Every 125s
Init Complete
DDR Size: 1G
Begin to Fill
Fill Stage 1 Finished
Begin to Check Stage 1
Check Stage 1 Finished without Mismatch
Begin to Fill Stage 2
Fill Stage 2 Finished
Begin to Check Stage 2
Check Stage 2 Finished without Mismatch
Test Finished

---

In this firmware, the DDR3 interface is open sourced under than BSD3 license without the Copyright Gowin IPs.  
This project can also be compiled with some open source compiliers.

The Gowin DDR3 IP is much faster than this.

This DDR Interface runs at DDR-40.  
The write rate is about 240Mbits/s.  
The read rate is about 300Mbits/s.  

The Gowin DDR3 IP runs at X.  
The maxium write rate is about (when using 64 bursts).  
The maxium read rate is about (when using 64 bursts).

This DDR Interface consumes 147 Regs and 216 LUTs.  
Gowin DDR3 IP consumes
