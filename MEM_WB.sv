`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.08.2024 18:41:10
// Design Name: 
// Module Name: MEM_WB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module MEM_WB (
    input  logic        clk, rst,
    
    // Input signals from MEM stage - Core 0
    input  logic        RegWriteM_0,
    input  logic [1:0]  ResultSrcM_0,
    input  logic [31:0] AluResultM_0,
    input  logic [4:0]  RdM_0,
    input  logic [31:0] PCPlus4M_0,
    
    // Output signals to WB stage - Core 0
    output logic        RegWriteW_0,
    output logic [1:0]  ResultSrcW_0,
    output logic [31:0] AluResultW_0,
    output logic [4:0]  RdW_0,
    output logic [31:0] PCPlus4W_0,
    
    // Input signals from MEM stage - Core 1
    input  logic        RegWriteM,
    input  logic [1:0]  ResultSrcM,
    input  logic [31:0] AluResultM,
    input  logic [31:0] ReadDataM,
    input  logic [4:0]  RdM,
    input  logic [31:0] PCPlus4M,
    
    // Output signals to WB stage - Core 1
    output logic        RegWriteW,
    output logic [1:0]  ResultSrcW,
    output logic [31:0] AluResultW,
    output logic [31:0] ReadDataW,
    output logic [4:0]  RdW,
    output logic [31:0] PCPlus4W
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all outputs - Core 0
            RegWriteW_0  <= 1'b0;
            ResultSrcW_0 <= 2'b00;
            AluResultW_0 <= 32'b0;
            RdW_0        <= 5'b0;
            PCPlus4W_0   <= 32'b0;
            
            // Reset all outputs - Core 1
            RegWriteW  <= 1'b0;
            ResultSrcW <= 2'b00;
            AluResultW <= 32'b0;
            ReadDataW  <= 32'b0;
            RdW        <= 5'b0;
            PCPlus4W   <= 32'b0;
        end else begin
            // Pass values from MEM stage to WB stage - Core 0
            RegWriteW_0  <= RegWriteM_0;
            ResultSrcW_0 <= ResultSrcM_0;
            AluResultW_0 <= AluResultM_0;
            RdW_0        <= RdM_0;
            PCPlus4W_0   <= PCPlus4M_0;
            
            // Pass values from MEM stage to WB stage - Core 1
            RegWriteW  <= RegWriteM;
            ResultSrcW <= ResultSrcM;
            AluResultW <= AluResultM;
            ReadDataW  <= ReadDataM;
            RdW        <= RdM;
            PCPlus4W   <= PCPlus4M;
        end
    end
endmodule
