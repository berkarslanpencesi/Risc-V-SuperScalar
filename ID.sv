`timescale 1ns / 1ps

module ID (
    // Instruction inputs - now handling two instructions
    input  logic [31:0] instrD_0,         // First instruction from Decode stage
    input  logic [31:0] instrD_1,         // Second instruction from Decode stage
    
    // Write-back inputs - now handling two write-back paths
    input  logic [31:0] ResultW_0,        // Result from Write-Back stage (pipeline 0)
    input  logic [31:0] ResultW_1,        // Result from Write-Back stage (pipeline 1)
    input  logic        RegWriteW_0,      // Register write enable from Write-Back stage (pipeline 0)
    input  logic        RegWriteW_1,      // Register write enable from Write-Back stage (pipeline 1)
    input  logic [4:0]  RdW_0,            // Destination register address from Write-Back stage (pipeline 0)
    input  logic [4:0]  RdW_1,            // Destination register address from Write-Back stage (pipeline 1)
    
    // Clock and reset
    input  logic        clk,rst,
    // Outputs for first instruction (pipeline 0)
    output logic [31:0] RD1D_0,           // Source register 1 data
    output logic [31:0] RD2D_0,           // Source register 2 data
    output logic [31:0] ExtimmD_0,        // Extended immediate value
    output logic        RegWriteD_0,      // Register write enable for Decode stage
    output logic [1:0]  ResultSrcD_0,     // Result source select (mux5)
    output logic [2:0]  MemWriteD_0,      // Memory write control
    output logic [2:0]  MemReadD_0,       // Memory read control
    output logic        JumpD_0,          // Jump control
    output logic        BranchD_0,        // Branch control
    output logic [4:0]  AluControlD_0,    // ALU control
    output logic        mux2D_0,          // Mux control for ALU source
    output logic        mux3D_0,          // Mux control
    output logic        mux4D_0,          // Mux control
    output logic [4:0]  RS1D_0,           // Source register 1 address
    output logic [4:0]  RS2D_0,           // Source register 2 address
    output logic [4:0]  RdD_0,            // Destination register address
    
    // Outputs for second instruction (pipeline 1)
    output logic [31:0] RD1D_1,           // Source register 1 data
    output logic [31:0] RD2D_1,           // Source register 2 data
    output logic [31:0] ExtimmD_1,        // Extended immediate value
    output logic        RegWriteD_1,      // Register write enable for Decode stage
    output logic [1:0]  ResultSrcD_1,     // Result source select (mux5)
    output logic [2:0]  MemWriteD_1,      // Memory write control
    output logic [2:0]  MemReadD_1,       // Memory read control
    output logic        JumpD_1,          // Jump control
    output logic        BranchD_1,        // Branch control
    output logic [4:0]  AluControlD_1,    // ALU control
    output logic        mux2D_1,          // Mux control for ALU source
    output logic        mux3D_1,          // Mux control
    output logic        mux4D_1,          // Mux control
    output logic [4:0]  RS1D_1,           // Source register 1 address
    output logic [4:0]  RS2D_1,           // Source register 2 address
    output logic [4:0]  RdD_1  ,           // Destination register address
    output logic [6:0] opcode0,opcode1
);

    // Internal register address signals for both pipelines
    logic [4:0] AA_0, BA_0;               // Register address signals for pipeline 0
    logic [4:0] AA_1, BA_1;               // Register address signals for pipeline 1
//    logic priority0, priority1;
    
    parameter LOAD  = 7'b0000011;
    parameter STORE = 7'b0100011;
    // Assign register addresses from instruction fields - Pipeline 0
    assign AA_0 = instrD_0[19:15];        // rs1 (source register 1)
    assign BA_0 = instrD_0[24:20];        // rs2 (source register 2)
    assign RS1D_0 = instrD_0[19:15];  // Source register 1 address
    assign RS2D_0 = instrD_0[24:20];  // Source register 2 address
    assign RdD_0 = instrD_0[11:7];    // Destination register address
    
    // Assign register addresses from instruction fields - Pipeline 1
    assign AA_1 = instrD_1[19:15];        // rs1 (source register 1)
    assign BA_1 = instrD_1[24:20];        // rs2 (source register 2)
    assign RS1D_1 = instrD_1[19:15];  // Source register 1 address
    assign RS2D_1 = instrD_1[24:20];  // Source register 2 address
    assign RdD_1 = instrD_1[11:7];    // Destination register address
    
    // Validity signals (could be extended with more complex logic)
    assign opcode0 = instrD_0[6:0];
    assign opcode1 = instrD_1[6:0];
    // Dual-port Register File with 4 read ports and 2 write ports
    register REG_inst (
        .clk(clk),
        .rst(rst),
        
        // Read ports for pipeline 0
        .rd_addr0(AA_0),              // rs1 for instruction 0
        .rd_addr1(BA_0),              // rs2 for instruction 0
        
        // Read ports for pipeline 1
        .rd_addr2(AA_1),              // rs1 for instruction 1
        .rd_addr3(BA_1),              // rs2 for instruction 1
        
        // Write ports
        .wr_addr0(RdW_0),             // Write address for pipeline 0
        .wr_addr1(RdW_1),             // Write address for pipeline 1
        .wr_din0(ResultW_0),          // Write data for pipeline 0
        .wr_din1(ResultW_1),          // Write data for pipeline 1
        .we0(RegWriteW_0),            // Write enable for pipeline 0
        .we1(RegWriteW_1),            // Write enable for pipeline 1
        
        // Read outputs - connected to  signals
        .rd_dout0(RD1D_0),        // rs1 data for instruction 0
        .rd_dout1(RD2D_0),        // rs2 data for instruction 0
        .rd_dout2(RD1D_1),        // rs1 data for instruction 1
        .rd_dout3(RD2D_1)         // rs2 data for instruction 1
    );
    
    // Immediate Decoder for Pipeline 0
    imm_decoder imminstr_0 (
        .instr(instrD_0),
        .ExtimmD(ExtimmD_0)
    );
    
    // Immediate Decoder for Pipeline 1
    imm_decoder imminstr_1 (
        .instr(instrD_1),
        .ExtimmD(ExtimmD_1)
    );
    
    // Control Unit for Pipeline 0
    control Controlinstr_0 (
        .instr(instrD_0),
        .RegWriteD(RegWriteD_0),
        .ResultSrcD(ResultSrcD_0),
        .MemWriteD(MemWriteD_0),
        .MemReadD(MemReadD_0),
        .JumpD(JumpD_0),
        .BranchD(BranchD_0),
        .AluControl(AluControlD_0),
        .mux2D(mux2D_0),
        .mux3D(mux3D_0),
        .mux4D(mux4D_0)
    );
    
    // Control Unit for Pipeline 1
    control Controlinstr_1 (
        .instr(instrD_1),
        .RegWriteD(RegWriteD_1),
        .ResultSrcD(ResultSrcD_1),
        .MemWriteD(MemWriteD_1),
        .MemReadD(MemReadD_1),
        .JumpD(JumpD_1),
        .BranchD(BranchD_1),
        .AluControl(AluControlD_1),
        .mux2D(mux2D_1),
        .mux3D(mux3D_1),
        .mux4D(mux4D_1)
    );
    
    /// ====================BURAYA ÇIKIÞI PÝPELÝNE A VERMEDEN KONTROL ÝÞÝNÝ GERÇEKLEÞTÝRMEM GEREKÝYOR.
    // 0000011 0100011
//always_comb begin
//   if ((opcode0 != LOAD && opcode0 != STORE) &&  //ikiside olursa dokunma
//        (opcode1 != LOAD && opcode1 != STORE)) begin
//            RD1D_0 = RD1D_0;
//            RD2D_0 = RD2D_0;
//            ExtimmD_0 = ExtimmD_0;
//            RegWriteD_0 = RegWriteD_0;
//            ResultSrcD_0 = ResultSrcD_0;
//            MemWriteD_0 = MemWriteD_0;
//            MemReadD_0 = MemReadD_0;
//            JumpD_0 = JumpD_0;
//            BranchD_0 = BranchD_0;
//            AluControlD_0 = AluControlD_0;
//            mux2D_0 = mux2D_0;
//            mux3D_0 = mux3D_0;
//            mux4D_0 = mux4D_0;
//            RS1D_0 = RS1D_0;
//            RS2D_0 = RS2D_0;
//            RdD_0 = RdD_0;
            
//            RD1D_1 = RD1D_1;
//            RD2D_1 = RD2D_1;
//            ExtimmD_1 = ExtimmD_1;
//            RegWriteD_1 = RegWriteD_1;
//            ResultSrcD_1 = ResultSrcD_1;
//            MemWriteD_1 = MemWriteD_1;
//            MemReadD_1 = MemReadD_1;
//            JumpD_1 = JumpD_1;
//            BranchD_1 = BranchD_1;
//            AluControlD_1 = AluControlD_1;
//            mux2D_1 = mux2D_1;
//            mux3D_1 = mux3D_1;
//            mux4D_1 = mux4D_1;
//            RS1D_1 = RS1D_1;
//            RS2D_1 = RS2D_1;
//            RdD_1 = RdD_1;
//            priority0=1'b0;
//            priority1=1'b1;
//            PCD0=PCD;
//            PCPlus4D0=PCPlus4D;
//            PCD1=PCPlus4D;
//            PCPlus4D1=PCPlus8D;
//        end
//        else if ((opcode0 == LOAD || opcode0 == STORE) &&//ters çevir
//                         (opcode1 != LOAD && opcode1 != STORE)) begin
//                         RD1D_0 = RD1D_1;
//                         RD2D_0 = RD2D_1;
//                         ExtimmD_0 = ExtimmD_1;
//                         RegWriteD_0 = RegWriteD_1;
//                         ResultSrcD_0 = ResultSrcD_1;
//                         MemWriteD_0 = MemWriteD_1;
//                         MemReadD_0 = MemReadD_1;
//                         JumpD_0 = JumpD_1;
//                         BranchD_0 = BranchD_1;
//                         AluControlD_0 = AluControlD_1;
//                         mux2D_0 = mux2D_1;
//                         mux3D_0 = mux3D_1;
//                         mux4D_0 = mux4D_1;
//                         RS1D_0 = RS1D_1;
//                         RS2D_0 = RS2D_1;
//                         RdD_0 = RdD_1;
                         
//                         RD1D_1 = RD1D_0;
//                         RD2D_1 = RD2D_0;
//                         ExtimmD_1 = ExtimmD_0;
//                         RegWriteD_1 = RegWriteD_0;
//                         ResultSrcD_1 = ResultSrcD_0;
//                         MemWriteD_1 = MemWriteD_0;
//                         MemReadD_1 = MemReadD_0;
//                         JumpD_1 = JumpD_0;
//                         BranchD_1 = BranchD_0;
//                         AluControlD_1 = AluControlD_0;
//                         mux2D_1 = mux2D_0;
//                         mux3D_1 = mux3D_0;
//                         mux4D_1 = mux4D_0;
//                         RS1D_1 = RS1D_0;
//                         RS2D_1 = RS2D_0;
//                         RdD_1 = RdD_0;                        
//                         priority0 = 1'b0;
//                         priority1 = 1'b1;
//                         priority0=1'b1;
//                         priority1=1'b0;
//                         PCD0=PCPlus4D;
//                         PCPlus4D0=PCPlus8D;
//                         PCD1=PCD;
//                         PCPlus4D1=PCPlus4D;
//                     end
//        else if ((opcode1 == LOAD || opcode1 == STORE) && //dogru gitmiþ dokunma
//                         (opcode0 != LOAD && opcode0 != STORE)) begin  
//                         RD1D_0 = RD1D_0;
//                         RD2D_0 = RD2D_0;
//                         ExtimmD_0 = ExtimmD_0;
//                         RegWriteD_0 = RegWriteD_0;
//                         ResultSrcD_0 = ResultSrcD_0;
//                         MemWriteD_0 = MemWriteD_0;
//                         MemReadD_0 = MemReadD_0;
//                         JumpD_0 = JumpD_0;
//                         BranchD_0 = BranchD_0;
//                         AluControlD_0 = AluControlD_0;
//                         mux2D_0 = mux2D_0;
//                         mux3D_0 = mux3D_0;
//                         mux4D_0 = mux4D_0;
//                         RS1D_0 = RS1D_0;
//                         RS2D_0 = RS2D_0;
//                         RdD_0 = RdD_0;
                         
//                         RD1D_1 = RD1D_1;
//                         RD2D_1 = RD2D_1;
//                         ExtimmD_1 = ExtimmD_1;
//                         RegWriteD_1 = RegWriteD_1;
//                         ResultSrcD_1 = ResultSrcD_1;
//                         MemWriteD_1 = MemWriteD_1;
//                         MemReadD_1 = MemReadD_1;
//                         JumpD_1 = JumpD_1;
//                         BranchD_1 = BranchD_1;
//                         AluControlD_1 = AluControlD_1;
//                         mux2D_1 = mux2D_1;
//                         mux3D_1 = mux3D_1;
//                         mux4D_1 = mux4D_1;
//                         RS1D_1 = RS1D_1;
//                         RS2D_1 = RS2D_1;
//                         RdD_1 = RdD_1;
//                         priority0=1'b0;
//                         priority1=1'b1;
//                         PCD0=PCD;
//                         PCPlus4D0=PCPlus4D;
//                         PCD1=PCPlus4D;
//                         PCPlus4D1=PCPlus8D;
//                     end
//        else begin  // stall at + looad sinyali çýkar bu hem memory kontrol ü yapcak hemde hazard da iþe yarayacak
//       // priority1 yani 0 tarafý ilk koþacak sonra 1 
//        RD1D_0 = RD1D_0;
//        RD2D_0 = RD2D_0;
//        ExtimmD_0 = ExtimmD_0;
//        RegWriteD_0 = RegWriteD_0;
//        ResultSrcD_0 = ResultSrcD_0;
//        MemWriteD_0 = MemWriteD_0;
//        MemReadD_0 = MemReadD_0;
//        JumpD_0 = JumpD_0;
//        BranchD_0 = BranchD_0;
//        AluControlD_0 = AluControlD_0;
//        mux2D_0 = mux2D_0;
//        mux3D_0 = mux3D_0;
//        mux4D_0 = mux4D_0;
//        RS1D_0 = RS1D_0;
//        RS2D_0 = RS2D_0;
//        RdD_0 = RdD_0;
        
//        RD1D_1 = RD1D_1;
//        RD2D_1 = RD2D_1;
//        ExtimmD_1 = ExtimmD_1;
//        RegWriteD_1 = RegWriteD_1;
//        ResultSrcD_1 = ResultSrcD_1;
//        MemWriteD_1 = MemWriteD_1;
//        MemReadD_1 = MemReadD_1;
//        JumpD_1 = JumpD_1;
//        BranchD_1 = BranchD_1;
//        AluControlD_1 = AluControlD_1;
//        mux2D_1 = mux2D_1;
//        mux3D_1 = mux3D_1;
//        mux4D_1 = mux4D_1;
//        RS1D_1 = RS1D_1;
//        RS2D_1 = RS2D_1;
//        RdD_1 = RdD_1;
//        priority0=1'b0;
//        priority1=1'b1;
//        PCD0=PCD;
//        PCPlus4D0=PCPlus4D;
//        PCD1=PCPlus4D;
//        PCPlus4D1=PCPlus8D;
//        end
//        end
endmodule
