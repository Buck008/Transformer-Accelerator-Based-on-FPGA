# FPGA-Based Weight-Fixed Systolic Array for Matrix Multiplication
You can run it on pynq z1. The repository contains the relevant verilog code, vivado configuration and C code for sdk testing.
In the future, I might add some nonlinear hardware acceleration operators, such as those that compute softmax and gelu functions. I am still working on to improve this part.

How to reproduce this project: 
1. In vivado2019.1, create a new project (note that the boardfile is pynq z1, you can download the corresponding boardfile here: https://github.com/Digilent/vivado-boards ).
2. Add all the code to the project
3. Run prj.tcl
4. Create a wrapper for the block design and set it as the top module.
5. Run the generated synthesis and implementation strategies and generate the bitstream.
