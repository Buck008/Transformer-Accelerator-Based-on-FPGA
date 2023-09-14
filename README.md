# Transformer Accelerator Based on FPGA
You can run it on pynq z1 (or any other Zynq device, since the systolic array is parameterized). The repository contains the relevant Verilog code, Vivado configuration and C/Python code for sdk/PYNQ testing. The size of the systolic array can be changed, now it is 24X24.
In the future, I might add some nonlinear hardware acceleration operators (for accelerating ViT, it's a kind of neural network based on Transformer), such as those that compute Softmax, Gelu and LayerNorm functions. I am still working on to improve the accuracy and performance of this part.

How to reproduce this project: 
1. In vivado2019.1, create a new project (note that the boardfile is pynq z1, you can download the corresponding boardfile here: https://github.com/Digilent/vivado-boards ).
2. Add all the code to the project
3. Run prj.tcl
4. Create a wrapper for the block design and set it as the top module.
5. Run the generated synthesis and implementation strategies and generate the bitstream.
