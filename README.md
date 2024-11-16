# MIPS Pipeline Processor

This repository contains a VHDL implementation of a MIPS processor with a pipelined architecture. The design focuses on simulating the functionality and performance of a MIPS processor using a testbench and Xcelium for simulations.

## Features

- **Pipeline Architecture**: Implements a 5-stage pipelined MIPS processor.
- **Testbench Included**: Provides a comprehensive testbench for verifying the processor's behavior.
- **Automated Simulation**: Includes a `Makefile` to streamline simulations with Xcelium.

## File Structure

- `MIPS_pipeline.vhd`: The main VHDL file containing the MIPS pipeline implementation.
- `MIPS_pipeline_tb.vhd`: Testbench for simulating and verifying the MIPS pipeline processor.
- `Makefile`: Automates simulation using the `make run` command.
- `docs/`: Contains supporting files like screenshots of the waveform window and signal setup:
  - `waveform_img.jpg`: Demonstrates opening the waveform window.
  - `signals_img.jpg`: Shows the signal configuration file.

## How to Run

1. Navigate to the testbench directory:
    ```bash
    cd MIPS/tb
    ```
2. Run the simulation using the provided `Makefile`:
    ```bash
    make run
    ```
3. Open the **Waveform Window** in Xcelium:
   - Refer to `docs/waveform_img.jpg` for guidance.
4. Load the signal configuration file (`signals.svwf`):
   - Refer to `docs/signals_img.jpg` for details.

## Requirements

- **Tools**: Xcelium (for simulation), Make (to use the Makefile).
- **VHDL Standard**: The code adheres to [specify standard, e.g., IEEE 1076-2008].

## Project Details

- **Pipeline Stages**:
  - Instruction Fetch (IF)
  - Instruction Decode (ID)
  - Execute (EX)
  - Memory Access (MEM)
  - Write Back (WB)
- **Testbench Overview**:
  - Simulates various instructions and scenarios to validate the pipelined processor.
  - Outputs results for functional verification.

## Contributions

Contributions are welcome! If you'd like to enhance the pipeline, optimize the implementation, or add new features, feel free to fork the repository and submit a pull request.

## License


## Acknowledgments

Special thanks to:
- **Professor Mateus Beck Rutzig** for guidance.
