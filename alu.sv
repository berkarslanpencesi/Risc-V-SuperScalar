module alu (
    input logic [31:0] src1,
    input logic [31:0] src2,
    input logic [4:0] func,
    output logic [31:0] alu_out
);
    logic [4:0] shift_amount;
    logic [4:0] counter;

    assign shift_amount = src2[4:0]; // Shift amount for SRL, SRA, SLL

    always_comb begin
        counter = 5'b0;
        unique case (func[4])
            1'b0: begin
                unique case (func[3:0])
                    4'b0000: alu_out = src1 & src2;          // AND
                    4'b0001: alu_out = src1 | src2;          // OR
                    4'b0010: alu_out = src1 ^ src2;          // XOR
                    4'b0011: alu_out = src1 + src2;          // ADD
                    4'b0100: alu_out = src1 - src2;          // SUB
                    4'b0101: alu_out = $signed(src1) < $signed(src2) ? 32'd1 : 32'd0;  // SLT
                    4'b0110: alu_out = src1 < src2 ? 32'd1 : 32'd0;                    // BLTU
                    4'b0111: alu_out = src1 >= src2 ? 32'd1 : 32'd0;                   // BGEU
                    4'b1000: alu_out = $signed(src1) >= $signed(src2) ? 32'd1 : 32'd0; // BGE
                    4'b1001: alu_out = src1 == src2 ? 32'd1 : 32'd0;                   // BEQ
                    4'b1010: alu_out = src1 != src2 ? 32'd1 : 32'd0;                   // BNE
                    4'b1011: alu_out = src1 >> shift_amount;      // SRL
                    4'b1100: alu_out = $signed(src1) >>> shift_amount; // SRA
                    4'b1101: alu_out = src1 << shift_amount;      // SLL
                    4'b1110: alu_out = src1 + 32'd4;             // JAL
                    4'b1111: alu_out = src2;                     // Pass src2 (U)
                    default: alu_out = 32'hDEADBEEF;             // Error case
                endcase
            end
            1'b1: begin
                unique case (func[3:0])
                    4'b0000: begin // CLZ
                        counter = 0;
                        for (int i = 31; i >= 0; i--) begin
                            if (src1[i] == 1'b1) begin
                                counter = 5'(32 - i - 1); // Explicitly cast to 5 bits
                                break; // Exit loop when first 1 is found
                            end
                        end
                        alu_out = {27'b0, counter};
                    end
                    4'b0001: begin // CTZ
                        counter = 0;
                        for (int i = 0; i < 32; i++) begin
                            if (src1[i] == 1'b1) begin
                                counter = 5'(i); // Explicitly cast to 5 bits
                                break; // Exit loop when first 1 is found
                            end
                        end
                        alu_out = {27'b0, counter};
                    end
                    4'b0010: begin // CPOP
                        counter = 0;
                        for (int i = 0; i < 32; i++) begin
                            if (src1[i] == 1'b1) begin
                                counter = counter + 1; // Counter is 5 bits, no overflow expected
                            end
                        end
                        alu_out = {27'b0, counter};
                    end
                    default: alu_out = 32'hDEADBEEF;
                endcase
            end
            default: alu_out = 32'hDEADBEEF;
        endcase
    end
endmodule
