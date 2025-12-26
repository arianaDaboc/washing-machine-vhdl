# washing-machine-vhdl
This project implements a digital washing machine controller using VHDL. The system is designed as a Finite State Machine that controls the different stages of a washing cycle based on user inputs and timing conditions.

Project Purpose.
The primary goal of this project is to showcase the practical application of Finite State Machines in managing complex state transitions for real world hardware. It serves as a comprehensive demonstration of hardware modeling using VHDL and digital system design specifically optimized for FPGA deployment.

Technologies Used.
The system is built using the VHDL hardware description language following a strict Finite State Machine design methodology. All development and synthesis are performed using the Xilinx Vivado toolset for deployment on an FPGA target platform.

System Features.
The controller utilizes robust FSM based logic to handle user inputs such as start and reset alongside specific mode selections. The design generates dedicated control signals for the water inlet and the drum motor as well as the drain pump. It features automatic transitions between all washing stages and includes a global reset functionality to return the system to the idle state at any time.

Washing Cycle States.
The system begins in the Idle state waiting for a start signal before moving into the Fill stage where water enters the drum. Once full the system enters the Wash state to rotate the drum followed by the Rinse cycle with clean water. The process continues to the Spin stage for high speed water removal and concludes at the Done state when the cycle is complete.
