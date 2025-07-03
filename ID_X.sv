`timescale 1ns / 1ps

module ID_X (
    input  logic        clk, rst,
    
    // Pipeline control signals
    input  logic        StallE_0,        // Stall signal for pipeline 0
    input  logic        FlushE_0,        // Flush signal for pipeline 0
    input  logic        FlushE_1,        // Flush signal for pipeline 1
    
    // Input signals from ID stage (pipeline 1)
    input  logic        RegWriteD,       // 1-bit control signal for register write
    input  logic [1:0]  ResultSrcD,     // Control signal (2 bits to select source)
    input  logic [2:0]  MemWriteD,      // 3-bit control signal for memory write
    input  logic [2:0]  MemReadD,       // 3-bit control signal for memory read
    input  logic        JumpD,          // 1-bit control signal for jump
    input  logic        BranchD,        // 1-bit control signal for branch
    input  logic [4:0]  AluControlD,    // 5-bit control signal for ALU operation
    input  logic        mux2D,          // 1-bit control signal for ALU source select
    input  logic        mux3D,          // 1-bit control signal
    input  logic        mux4D,          // 1-bit control signal
    input  logic [31:0] RD1D,           // 32-bit data from source register 1
    input  logic [31:0] RD2D,           // 32-bit data from source register 2
    input  logic [4:0]  RS1D,           // 5-bit source register 1 address
    input  logic [4:0]  RS2D,           // 5-bit source register 2 address
    input  logic [4:0]  RdD,            // 5-bit destination register address
    input  logic [31:0] ExTimmD,        // 32-bit immediate value (düzeltildi)
    
    // PC related inputs
    input  logic [31:0] PCD0,           // PC for first instruction
    input  logic [31:0] PCPlus4D0,      // PC+4 for first instruction
    input  logic [31:0] PCD1,           // PC for second instruction
    input  logic [31:0] PCPlus4D1,      // PC+4 for second instruction
    
    // Input signals from ID stage (pipeline 0)
    input  logic [31:0] RD1D_0,         // Additional RD1D port
    input  logic [31:0] RD2D_0,         // Additional RD2D port
    input  logic [31:0] ExtimmD_0,      // Additional ExtimmD port
    input  logic        RegWriteD_0,    // Additional RegWriteD port
    input  logic [1:0]  ResultSrcD_0,   // Additional ResultSrcD port
    input  logic [2:0]  MemWriteD_0,    // Additional MemWriteD port
    input  logic [2:0]  MemReadD_0,     // Additional MemReadD port
    input  logic        JumpD_0,        // Additional JumpD port
    input  logic        BranchD_0,      // Additional BranchD port
    input  logic [4:0]  AluControlD_0,  // Additional AluControlD port
    input  logic        mux2D_0,        // Additional mux2D port
    input  logic        mux3D_0,        // Additional mux3D port
    input  logic        mux4D_0,        // Additional mux4D port
    input  logic [4:0]  RS1D_0,         // Additional RS1D port
    input  logic [4:0]  RS2D_0,         // Additional RS2D port
    input  logic [4:0]  RdD_0,          // Additional RdD port
    
    // Output signals to EX stage (pipeline 1)
    output logic        RegWriteE,      // 1-bit control signal for register write enable
    output logic [1:0]  ResultSrcE,     // Control signal (2 bits to select source)
    output logic [2:0]  MemWriteE,      // 3-bit control signal for memory write
    output logic [2:0]  MemReadE,       // 3-bit control signal for memory read
    output logic        JumpE,          // 1-bit control signal for jump
    output logic        BranchE,        // 1-bit control signal for branch
    output logic [4:0]  AluControlE,    // 5-bit control signal for ALU operation
    output logic        mux2E,          // 1-bit control signal for ALU source select
    output logic        mux3E,          // 1-bit control signal
    output logic        mux4E,          // 1-bit control signal
    output logic [31:0] RD1E,           // 32-bit data from source register 1
    output logic [31:0] RD2E,           // 32-bit data from source register 2
    output logic [4:0]  RS1E,           // 5-bit source register 1 address
    output logic [4:0]  RS2E,           // 5-bit source register 2 address
    output logic [4:0]  RdE,            // 5-bit destination register address
    output logic [31:0] ExTimmE,        // 32-bit immediate value
    
    // Output signals to EX stage (pipeline 0)
    output logic        RegWriteE_0,    // 1-bit control signal for register write enable
    output logic [1:0]  ResultSrcE_0,   // Control signal (2 bits to select source)
    output logic [2:0]  MemWriteE_0,    // 3-bit control signal for memory write
    output logic [2:0]  MemReadE_0,     // 3-bit control signal for memory read
    output logic        JumpE_0,        // 1-bit control signal for jump
    output logic        BranchE_0,      // 1-bit control signal for branch
    output logic [4:0]  AluControlE_0,  // 5-bit control signal for ALU operation
    output logic        mux2E_0,        // 1-bit control signal for ALU source select
    output logic        mux3E_0,        // 1-bit control signal
    output logic        mux4E_0,        // 1-bit control signal
    output logic [31:0] RD1E_0,         // 32-bit data from source register 1
    output logic [31:0] RD2E_0,         // 32-bit data from source register 2
    output logic [4:0]  RS1E_0,         // 5-bit source register 1 address
    output logic [4:0]  RS2E_0,         // 5-bit source register 2 address
    output logic [4:0]  RdE_0,          // 5-bit destination register address
    output logic [31:0] ExTimmE_0,      // 32-bit immediate value
    
    // PC related outputs
    output logic [31:0] PCE0,           // PC for first instruction
    output logic [31:0] PCPlus4E0,      // PC+4 for first instruction
    output logic [31:0] PCE1,           // PC for second instruction
    output logic [31:0] PCPlus4E1       // PC+4 for second instruction
);

// Pipeline 0 (main pipeline)
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset all outputs to default values
        RegWriteE_0   <= 1'b0;
        ResultSrcE_0  <= 2'b00;
        MemWriteE_0   <= 3'b000;
        MemReadE_0    <= 3'b000;
        JumpE_0       <= 1'b0;
        BranchE_0     <= 1'b0;
        AluControlE_0 <= 5'b00000;
        mux2E_0       <= 1'b0;
        mux3E_0       <= 1'b0;
        mux4E_0       <= 1'b0;
        RD1E_0        <= 32'b0;
        RD2E_0        <= 32'b0;
        RS1E_0        <= 5'b0;
        RS2E_0        <= 5'b0;
        RdE_0         <= 5'b0;
        ExTimmE_0     <= 32'b0;
        
        PCE0          <= 32'b0;
        PCPlus4E0     <= 32'b0;
    end 
    else if (FlushE_0) begin
        // Flush pipeline 0
        RegWriteE_0   <= 1'b0;
        ResultSrcE_0  <= 2'b00;
        MemWriteE_0   <= 3'b000;
        MemReadE_0    <= 3'b000;
        JumpE_0       <= 1'b0;
        BranchE_0     <= 1'b0;
        AluControlE_0 <= 5'b00000;
        mux2E_0       <= 1'b0;
        mux3E_0       <= 1'b0;
        mux4E_0       <= 1'b0;
        RD1E_0        <= 32'b0;
        RD2E_0        <= 32'b0;
        RS1E_0        <= 5'b0;
        RS2E_0        <= 5'b0;
        RdE_0         <= 5'b0;
        ExTimmE_0     <= 32'b0;
        
        PCE0          <= 32'b0;
        PCPlus4E0     <= 32'b0;
    end 
    else if (!StallE_0) begin
        // Normal operation for pipeline 0
        RegWriteE_0   <= RegWriteD_0;
        ResultSrcE_0  <= ResultSrcD_0;
        MemWriteE_0   <= MemWriteD_0;
        MemReadE_0    <= MemReadD_0;
        JumpE_0       <= JumpD_0;
        BranchE_0     <= BranchD_0;
        AluControlE_0 <= AluControlD_0;
        mux2E_0       <= mux2D_0;
        mux3E_0       <= mux3D_0;
        mux4E_0       <= mux4D_0;
        RD1E_0        <= RD1D_0;
        RD2E_0        <= RD2D_0;
        RS1E_0        <= RS1D_0;
        RS2E_0        <= RS2D_0;
        RdE_0         <= RdD_0;
        ExTimmE_0     <= ExtimmD_0;
        
        PCE0          <= PCD0;
        PCPlus4E0     <= PCPlus4D0;
    end
end

// Pipeline 1 (secondary pipeline)
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset all outputs to default values
        RegWriteE   <= 1'b0;
        ResultSrcE  <= 2'b00;
        MemWriteE   <= 3'b000;
        MemReadE    <= 3'b000;
        JumpE       <= 1'b0;
        BranchE     <= 1'b0;
        AluControlE <= 5'b00000;
        mux2E       <= 1'b0;
        mux3E       <= 1'b0;
        mux4E       <= 1'b0;
        RD1E        <= 32'b0;
        RD2E        <= 32'b0;
        RS1E        <= 5'b0;
        RS2E        <= 5'b0;
        RdE         <= 5'b0;
        ExTimmE     <= 32'b0;
        
        PCE1        <= 32'b0;
        PCPlus4E1   <= 32'b0;
    end 
    else if (FlushE_1) begin
        // Flush pipeline 1
        RegWriteE   <= 1'b0;
        ResultSrcE  <= 2'b00;
        MemWriteE   <= 3'b000;
        MemReadE    <= 3'b000;
        JumpE       <= 1'b0;
        BranchE     <= 1'b0;
        AluControlE <= 5'b00000;
        mux2E       <= 1'b0;
        mux3E       <= 1'b0;
        mux4E       <= 1'b0;
        RD1E        <= 32'b0;
        RD2E        <= 32'b0;
        RS1E        <= 5'b0;
        RS2E        <= 5'b0;
        RdE         <= 5'b0;
        ExTimmE     <= 32'b0;
        
        PCE1        <= 32'b0;
        PCPlus4E1   <= 32'b0;
    end 
    else begin
        // Normal operation for pipeline 1
        RegWriteE   <= RegWriteD;
        ResultSrcE  <= ResultSrcD;
        MemWriteE   <= MemWriteD;
        MemReadE    <= MemReadD;
        JumpE       <= JumpD;
        BranchE     <= BranchD;
        AluControlE <= AluControlD;
        mux2E       <= mux2D;
        mux3E       <= mux3D;
        mux4E       <= mux4D;
        RD1E        <= RD1D;
        RD2E        <= RD2D;
        RS1E        <= RS1D;
        RS2E        <= RS2D;
        RdE         <= RdD;
        ExTimmE     <= ExTimmD;
        
        PCE1        <= PCD1;
        PCPlus4E1   <= PCPlus4D1;
    end
end

endmodule
