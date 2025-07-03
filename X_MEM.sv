`timescale 1ns / 1ps

module X_MEM (
    input  logic        clk, rst,
    
    // Pipeline control signals
    input  logic        FlushM_0,         // Flush signal for pipeline 0
    input  logic        FlushM_1,         // Flush signal for pipeline 1
    
    // Pipeline 0 signals (EX to MEM)
    input  logic        RegWriteE_0,      // Register write enable
    input  logic [1:0]  ResultSrcE_0,     // Result source select
    input  logic [2:0]  MemWriteE_0,      // Memory write control
    input  logic [2:0]  MemReadE_0,       // Memory read control
    input  logic [31:0] AluResultE_0,     // ALU result
    input  logic [4:0]  RdE_0,            // Destination register
    input  logic [31:0] PcPlus4E_0,       // PC+4 value
    input  logic [31:0] WriteDataE_0,     // Data to write to memory (eklendi)
    
    // Pipeline 0 signals (MEM stage)
    output logic        RegWriteM_0,      // Register write enable
    output logic [1:0]  ResultSrcM_0,     // Result source select
    output logic [2:0]  MemWriteM_0,      // Memory write control (eklendi)
    output logic [2:0]  MemReadM_0,       // Memory read control (eklendi)
    output logic [31:0] AluResultM_0,     // ALU result
    output logic [4:0]  RdM_0,            // Destination register
    output logic [31:0] PcPlus4M_0,       // PC+4 value
    output logic [31:0] WriteDataM_0,     // Data to write to memory (eklendi)
    
    // Pipeline 1 signals (EX to MEM)
    input  logic        RegWriteE_1,      // Register write enable
    input  logic [1:0]  ResultSrcE_1,     // Result source select
    input  logic [2:0]  MemWriteE_1,      // Memory write control
    input  logic [2:0]  MemReadE_1,       // Memory read control
    input  logic [4:0]  RdE_1,            // Destination register
    input  logic [31:0] PcPlus4E_1,       // PC+4 value
    input  logic [31:0] AluResultE_1,     // ALU result
    input  logic [31:0] WriteDataE_1,     // Data to write to memory
    
    // Pipeline 1 signals (MEM stage)
    output logic        RegWriteM_1,      // Register write enable
    output logic [1:0]  ResultSrcM_1,     // Result source select
    output logic [2:0]  MemWriteM_1,      // Memory write control
    output logic [2:0]  MemReadM_1,       // Memory read control
    output logic [4:0]  RdM_1,            // Destination register
    output logic [31:0] PcPlus4M_1,       // PC+4 value
    output logic [31:0] alu_outM_1,       // ALU result
    output logic [31:0] WriteDataM_1      // Data to write to memory
);

// Pipeline 0 registers
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset all pipeline 0 outputs
        RegWriteM_0  <= 1'b0;
        ResultSrcM_0 <= 2'b00;
        MemWriteM_0  <= 3'b000;
        MemReadM_0   <= 3'b000;
        AluResultM_0 <= 32'b0;
        RdM_0        <= 5'b0;
        PcPlus4M_0   <= 32'b0;
        WriteDataM_0 <= 32'b0;
    end 
    else if (FlushM_0) begin
        // Flush pipeline 0
        RegWriteM_0  <= 1'b0;
        ResultSrcM_0 <= 2'b00;
        MemWriteM_0  <= 3'b000;
        MemReadM_0   <= 3'b000;
        AluResultM_0 <= 32'b0;
        RdM_0        <= 5'b0;
        PcPlus4M_0   <= 32'b0;
        WriteDataM_0 <= 32'b0;
    end 
    else begin
        // Normal operation for pipeline 0
        RegWriteM_0  <= RegWriteE_0;
        ResultSrcM_0 <= ResultSrcE_0;
        MemWriteM_0  <= MemWriteE_0;
        MemReadM_0   <= MemReadE_0;
        AluResultM_0 <= AluResultE_0;
        RdM_0        <= RdE_0;
        PcPlus4M_0   <= PcPlus4E_0;
        WriteDataM_0 <= WriteDataE_0;
    end
end

// Pipeline 1 registers
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset all pipeline 1 outputs
        RegWriteM_1  <= 1'b0;
        ResultSrcM_1 <= 2'b00;
        MemWriteM_1  <= 3'b000;
        MemReadM_1   <= 3'b000;
        RdM_1        <= 5'b0;
        PcPlus4M_1   <= 32'b0;
        alu_outM_1   <= 32'b0;
        WriteDataM_1 <= 32'b0;
    end 
    else if (FlushM_1) begin
        // Flush pipeline 1
        RegWriteM_1  <= 1'b0;
        ResultSrcM_1 <= 2'b00;
        MemWriteM_1  <= 3'b000;
        MemReadM_1   <= 3'b000;
        RdM_1        <= 5'b0;
        PcPlus4M_1   <= 32'b0;
        alu_outM_1   <= 32'b0;
        WriteDataM_1 <= 32'b0;
    end 
    else begin
        // Normal operation for pipeline 1
        RegWriteM_1  <= RegWriteE_1;
        ResultSrcM_1 <= ResultSrcE_1;
        MemWriteM_1  <= MemWriteE_1;
        MemReadM_1   <= MemReadE_1;
        RdM_1        <= RdE_1;
        PcPlus4M_1   <= PcPlus4E_1;
        alu_outM_1   <= AluResultE_1;
        WriteDataM_1 <= WriteDataE_1;
    end
end

endmodule
