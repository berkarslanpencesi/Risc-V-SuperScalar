module if_id (
    input  logic        clk,              // Clock signal
    input  logic        rst,              // Reset signal
    input  logic        StallD_1,StallD_0,           // Control signal to stall the pipeline
    input  logic        FlushD_1,FlushD_0,           // Control signal to flush the pipeline
    
    input  logic [31:0] PCF_0,              // Program counter input
    input  logic [31:0] PCPlus4F_0,         // Program counter + 4 input
    input  logic [31:0] PCF_1,              // Program counter input
    input  logic [31:0] PCPlus4F_1,         // Program counter + 4 input
    input  logic [31:0] instrF_a,         // Instruction A input
    input  logic [31:0] instrF_b,         // Instruction B input
   
    output logic [31:0] PCD_0,              // Program counter output
                        PCPlus4D_0,         // Program counter + 4 output
                        PCD_1,
                        PCPlus4D_1,        // Program counter + 8 output
    output logic [31:0] instrD_a,         // Instruction A output
                        instrD_b          // Instruction B output
);

    // Sequential logic for the IF/ID register
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all outputs
            PCD_0        <= 32'b0;
            PCPlus4D_0   <= 32'b0;
            instrD_a   <= 32'b0;
        end else if (FlushD_0) begin
            // Clear outputs on flush
            PCD_0        <= 32'b0;
            PCPlus4D_0   <= 32'b0;
            instrD_a   <= 32'h13;
        end else if (!StallD_0) begin
            // Update outputs if not stalled
            PCD_0        <= PCF_0;
            PCPlus4D_0   <= PCPlus4F_0;
            instrD_a   <= instrF_a;
        end
        // Else (stall), hold the current values
    end
    always_ff @(posedge clk or posedge rst) begin
            if (rst) begin
                // Reset all outputs
                PCD_1       <= 32'b0;
                PCPlus4D_1   <= 32'b0;
                instrD_b   <= 32'b0;
            end else if (FlushD_1) begin
                // Clear outputs on flush
                PCD_1       <= 32'b0;
                PCPlus4D_1   <= 32'b0;
                instrD_b   <= 32'h13;
            end else if (!StallD_1) begin
                // Update outputs if not stalled
                PCD_1        <= PCF_1;
                PCPlus4D_1   <= PCPlus4F_1;
                instrD_b   <= instrF_b;
            end
            // Else (stall), hold the current values
        end

endmodule
