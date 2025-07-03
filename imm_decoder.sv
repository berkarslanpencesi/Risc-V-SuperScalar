module imm_decoder(
    input  logic [31:0] instr, 
    output logic [31:0] ExtimmD
);

    logic [6:0] opcode;
    assign opcode = instr[6:0];

    always_comb begin
        case(opcode)
            7'b0010011: ExtimmD = {{20{instr[31]}}, instr[31:20]}; // I-type
            7'b0000011: ExtimmD = {{20{instr[31]}}, instr[31:20]}; // I LOAD
            7'b1100111: ExtimmD = {{20{instr[31]}}, instr[31:20]}; // I (JALR)
            
            7'b0100011: ExtimmD = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // S-type
            
            7'b1100011: ExtimmD = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; // B-type

            7'b1101111: ExtimmD = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:25], instr[24:21], 1'b0};//JAL
            
            7'b0110111: ExtimmD = {instr[31:12], 12'b0}; // U-type
            7'b0010111: ExtimmD = {instr[31:12], 12'b0}; // U-type

            default: ExtimmD = 32'b0;
        endcase
    end
endmodule
