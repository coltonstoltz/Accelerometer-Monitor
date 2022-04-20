# Accelerometer-Monitor
Implements a FSM that will communicate via SPI protocol with Analog Devices ADXL362 accelerometer that is onboard the Nexys 4 DDR FPGA.  The FSM will initialize the accelerometer and repeatedly read the data for the X, Y, and Z axis.  The X, Y, and Z axis data is displayed on the FPGA's two segment display.  The sequence of initialization instructions are stored in the Init.txt file.  FSM was written in SystemVerilog.
