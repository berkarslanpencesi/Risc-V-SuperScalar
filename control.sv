`timescale 1ns / 1ps
module control (
    input  logic [31:0] instr,
    
    output logic RegWriteD,
    output logic [1:0] ResultSrcD,  // mux5
    output logic [2:0] MemWriteD,
    output logic [2:0] MemReadD,
    output logic JumpD,
    output logic BranchD,
    output logic [4:0] AluControl,
    output logic mux2D,
    output logic mux3D,
    output logic mux4D
);
    logic [3:0] AluControlD;
    logic [2:0] funct3;
    logic [11:0] imm;
    logic [6:0] opcode;
    logic newcontrol;
    assign AluControl = {newcontrol, AluControlD};
    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign imm = instr[31:20];
    always_comb begin
          
    end
        always_comb begin
        // Default assignments
        RegWriteD = 0;
        ResultSrcD = 2'b00;
        MemWriteD = 3'b000;
        MemReadD = 3'b000;
        JumpD = 0;
        BranchD = 0;
        mux2D = 0;
        mux3D = 0;
        mux4D = 0;
        AluControlD = 4'b1111;
        
        newcontrol =  (funct3==3'b001)&&(opcode==7'b0010011)&&(instr[31:25]!=7'b0);//slli
            unique case(opcode)
                7'b0000011: begin  // L - Load instructions
                    RegWriteD   = 1;
                    ResultSrcD  = 2'b01;
                    MemWriteD   = 3'b000;
                    MemReadD    = 3'b000;
                    JumpD       = 0;
                    BranchD     = 0;
                    mux2D       = 0;
                    mux3D       = 1;
                    mux4D       = 0;
                    
                    unique case(funct3)
                        3'b000: {AluControlD, MemReadD} = {4'b0011, 3'b011};  // LB
                        3'b001: {AluControlD, MemReadD} = {4'b0011, 3'b100};  // LH
                        3'b010: {AluControlD, MemReadD} = {4'b0011, 3'b101};  // LW
                        3'b100: {AluControlD, MemReadD} = {4'b0011, 3'b001};  // LBU
                        3'b101: {AluControlD, MemReadD} = {4'b0011, 3'b010};  // LHU
                        default: {AluControlD, MemReadD} = {4'bxxxx, 3'bxxx};
                    endcase
                end
                
                7'b0010011: begin  // I - Immediate format for arithmetic operations
                    RegWriteD   = 1;
                    ResultSrcD  = 2'b00;
                    MemWriteD   = 3'b000;
                    MemReadD    = 3'b000;
                    JumpD       = 0;
                    BranchD     = 0;
                    mux2D       = 0;
                    mux3D       = 1;
                    mux4D       = 0;
                    
                    unique case(funct3)
                        3'b000: AluControlD = 4'b0011;  // ADDI
                        
                        3'b001: begin 
                                unique casez (imm[11:5])
                                    7'b0000000: AluControlD = 4'b1101; // SLLI
                                    7'b0110000: begin
                                        unique case (imm[4:0])
                                            5'b00000: AluControlD = 4'b0000; // CLZ
                                            5'b00001: AluControlD = 4'b0001; // CTZ
                                            5'b00010: AluControlD = 4'b0010; // CPOP
                                            default: AluControlD = 4'b0000; // Safe default
                                        endcase
                                    end
                                    default: AluControlD = 4'b0000; // Safe default
                                endcase
                            end
//                            unique case(imm)
//                            12'b0000_000?_????:AluControlD = 4'b1101;// SLLI
//                            12'b0110_0000_0000:AluControlD = 4'b0000;//CLZ
//                            12'b0110_0000_0001:AluControlD = 4'b0001;//CTZ
//                            12'b0110_0000_0010:AluControlD = 4'b0010;//CPOP
//                            default: AluControlD = 4'bxxxx;
                           
                            
                        3'b010: AluControlD = 4'b0101;  // SLTI
                        3'b011: AluControlD = 4'b0110;  // SLTIU
                        3'b100: AluControlD = 4'b0010;  // XORI
                        3'b110: AluControlD = 4'b0001;  // ORI
                        3'b111: AluControlD = 4'b0000;  // ANDI
//                        3'b001: AluControlD = 4'b1101;  // SLLI
                        3'b101: AluControlD = instr[30] ? 4'b1100 : 4'b1011;  // SRAI : SRLI
                        default: AluControlD = 4'bxxxx;
                    endcase
                end
                
                7'b0100011: begin  // S - Store instructions
                    RegWriteD   = 0;
                    ResultSrcD  = 2'bxx;
                    MemWriteD   = 3'b000;
                    MemReadD    = 3'b000;
                    JumpD       = 0;
                    BranchD     = 0;
                    mux2D       = 0;
                    mux3D       = 1;
                    mux4D       = 0;
                    
                    unique case(funct3)
                        3'b000: {AluControlD, MemWriteD} = {4'b0011, 3'b001};  // SB
                        3'b001: {AluControlD, MemWriteD} = {4'b0011, 3'b010};  // SH
                        3'b010: {AluControlD, MemWriteD} = {4'b0011, 3'b100};  // SW
                        default: {AluControlD, MemWriteD} = {4'bxxxx, 3'bxxx};
                    endcase
                end
                
                7'b0110011: begin  // R - Register-Register format
                    RegWriteD   = 1;
                    ResultSrcD  = 2'b00;
                    MemWriteD   = 3'b000;
                    MemReadD    = 3'b000;
                    JumpD       = 0;
                    BranchD     = 0;
                    mux2D       = 0;
                    mux3D       = 0;
                    mux4D       = 0;
                    
                    unique case(funct3)
                        3'b000: AluControlD = instr[30] ? 4'b0100 : 4'b0011;  // SUB : ADD
                        3'b001: AluControlD = 4'b1101;  // SLL
                        3'b010: AluControlD = 4'b0101;  // SLT
                        3'b011: AluControlD = 4'b0110;  // SLTU
                        3'b100: AluControlD = 4'b0010;  // XOR
                        3'b101: AluControlD = instr[30] ? 4'b1100 : 4'b1011;  // SRA : SRL
                        3'b110: AluControlD = 4'b0001;  // OR
                        3'b111: AluControlD = 4'b0000;  // AND
                        default: AluControlD = 4'bxxxx;
                    endcase
                end
                
                7'b0110111: begin  // U - LUI
                    RegWriteD   = 1;
                    ResultSrcD  = 2'b00;
                    MemWriteD   = 3'b000;
                    MemReadD    = 3'b000;
                    JumpD       = 0;
                    BranchD     = 0;
                    mux2D       = 0;
                    mux3D       = 1;
                    mux4D       = 0;
                    AluControlD = 4'b1111;
                end
                
                7'b0010111: begin  // U - AUIPC
                    RegWriteD   = 1;
                    ResultSrcD  = 2'b00;
                    MemWriteD   = 3'b000;
                    MemReadD    = 3'b000;
                    JumpD       = 0;
                    BranchD     = 0;
                    mux2D       = 1;
                    mux3D       = 1;
                    mux4D       = 0;
                    AluControlD = 4'b0011;
                end
                
                7'b1100011: begin  // B - Branch instructions
                    RegWriteD   = 0;
                    ResultSrcD  = 2'b00;
                    MemWriteD   = 3'b000;
                    MemReadD    = 3'b000;
                    JumpD       = 0;
                    BranchD     = 1;
                    mux2D       = 0;
                    mux3D       = 0;
                    mux4D       = 0;
                    
                    unique case(funct3)
                        3'b000: AluControlD = 4'b1001;  // BEQ
                        3'b001: AluControlD = 4'b1010;  // BNE
                        3'b100: AluControlD = 4'b0101;  // BLT
                        3'b101: AluControlD = 4'b1000;  // BGE
                        3'b110: AluControlD = 4'b0110;  // BLTU
                        3'b111: AluControlD = 4'b0111;  // BGEU
                        default: AluControlD = 4'bxxxx;
                    endcase
                end
                
                7'b1101111: begin  // J - JAL
                    RegWriteD   = 1;
                    ResultSrcD  = 2'b10;
                    MemWriteD   = 3'b000;
                    MemReadD    = 3'b000;
                    JumpD       = 1;
                    BranchD     = 0;
                    mux2D       = 0;
                    mux3D       = 0;
                    mux4D       = 0;
                    AluControlD = 4'b1110;
                end
                
                7'b1100111: begin  // J - JALR
                    RegWriteD   = 1;
                    ResultSrcD  = 2'b01;
                    MemWriteD   = 3'b000;
                    MemReadD    = 3'b000;
                    JumpD       = 1;
                    BranchD     = 0;
                    mux2D       = 1;
                    mux3D       = 0;
                    mux4D       = 1;
                    AluControlD = 4'b1110;
                end
                
                default: begin
                    RegWriteD   = 0;
                    ResultSrcD  = 2'b00;
                    MemWriteD   = 3'b000;
                    MemReadD    = 3'b000;
                    JumpD       = 0;
                    BranchD     = 0;
                    mux2D       = 0;
                    mux3D       = 0;
                    mux4D       = 0;
                    AluControlD = 4'b1111;
                end
            endcase
        end
    endmodule
