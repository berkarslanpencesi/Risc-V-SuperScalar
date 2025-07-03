`timescale 1ns / 1ps

module IF_Top #(
    parameter MEM_SIZE = 2048
    
)(
    input  logic        clk, rst,
    input  logic        mux1_a, mux1_b,
    input  logic [31:0] PctargetE_a, PctargetE_b,
    input  logic        StallF,
    output logic [31:0] PCF_0, PCPlus4F_0, PCF_1, PCPlus4F_1,
    output logic [31:0] instrF_a, instrF_b
);
    
    logic [31:0] PC_next;
    logic [31:0] inst_memory [0:MEM_SIZE-1];
    
    initial $readmemh("imem.mem", inst_memory);
    
    // PC source selection (prioritize datapath A)
    assign PC_next = mux1_a ? PctargetE_a : 
                    mux1_b ? PctargetE_b : PCPlus4F_1;
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            PCF_0      <= 32'h8000_0000;
            PCPlus4F_0 <= 32'h8000_0004;
            PCF_1      <= 32'h8000_0004;
            PCPlus4F_1 <= 32'h8000_0008;
        end else if ((!StallF)&&(PCF_0<32'H80002001) ) begin
            PCF_0      <= PC_next;
            PCPlus4F_0 <= PC_next + 32'd4;
            PCF_1      <= PC_next + 32'd4;
            PCPlus4F_1 <= PC_next + 32'd8;
        end
    end
    
    // Fetch two instructions simultaneously
    assign instrF_a = PCF_0<32'H80002001 ? inst_memory[PCF_0[12:2]] : 32'b0;
    assign instrF_b = PCF_1<32'H80002001 ? inst_memory[PCF_1[12:2]] : 32'b0;
    
endmodule
