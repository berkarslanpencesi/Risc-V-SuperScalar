module core_model
#(
    parameter DMemInitFile  = "dmem.mem",
    parameter IMemInitFile  = "imem.mem",
    parameter TableFile     = "table.log",
    parameter IssueWidth    = 2,
    parameter XLEN = 32 
) (
    input  logic             clk_i,
    input  logic             rstn_i,
    input  logic  [XLEN-1:0] addr_i,
    output logic  [XLEN-1:0] data_o,
    // Change to packed arrays
    output logic  [IssueWidth-1:0]             update_o,    // [1:0]
    output logic  [IssueWidth-1:0] [XLEN-1:0]  pc_o,        // [1:0][31:0]
    output logic  [IssueWidth-1:0] [XLEN-1:0]  instr_o,     // [1:0][31:0]
    output logic  [IssueWidth-1:0] [4:0]       reg_addr_o,  // [1:0][4:0]
    output logic  [IssueWidth-1:0] [XLEN-1:0]  reg_data_o,  // [1:0][31:0]
    output logic  [IssueWidth-1:0] [XLEN-1:0]  mem_addr_o,  // [1:0][31:0]
    output logic  [IssueWidth-1:0] [XLEN-1:0]  mem_data_o,  // [1:0][31:0]
    output logic  [IssueWidth-1:0]             mem_wrt_o    // [1:0]
);

  // Reset signal conversion
  logic        rst;
  
  // Pipeline 0 - Execute stage
  logic [4:0] RdM_0, RdW_0;
  logic       RegWriteM_0, RegWriteW_0;
  logic       BranchE_0;
  logic [2:0] ForwardAE_0, ForwardBE_0;
  
  // Pipeline 0 - Decode stage
  logic [4:0] Rs1D_0, Rs2D_0;
  logic [4:0] RdE_0;
  logic [1:0] ResultSrcE_0;
  logic       StallF_0, StallD_0, FlushE_0, StallE_0;
  logic       mux1_0;
  logic       FlushD_0;
  
  // Pipeline 1 - Execute stage
  logic [2:0] ForwardAE_1, ForwardBE_1;
  
  // Pipeline 1 - Decode stage
  logic       StallF_1, StallD_1, FlushE_1;
  logic       mux1_1;
  logic       FlushD_1;
  
  // Common controllers
  logic [6:0] opcode0, opcode1;
  
  // IF stage signals
  logic [31:0] instrF_a, instrF_b, PCD0, PCPlus4D0, PCD1, PCPlus4D1;
  
  // ID stage signals - Pipeline A (instrD_a)
  logic [31:0] RD1D_0, RD2D_0, ExtimmD_0;
  logic        RegWriteD_0, JumpD_0, BranchD_0, mux2D_0, mux3D_0, mux4D_0;
  logic [1:0]  ResultSrcD_0;
  logic [2:0]  MemWriteD_0, MemReadD_0;
  logic [4:0]  AluControlD_0, RS1D_0, RS2D_0, RdD_0;
  
  // ID stage signals - Pipeline B (instrD_b)
  logic [31:0] RD1D_1, RD2D_1, ExtimmD_1, instrD_a, instrD_b;
  logic        RegWriteD_1, JumpD_1, BranchD_1, mux2D_1, mux3D_1, mux4D_1;
  logic [1:0]  ResultSrcD_1;
  logic [2:0]  MemWriteD_1, MemReadD_1;
  logic [4:0]  AluControlD_1, RS1D_1, RS2D_1, RdD_1;
  
  // ID/EX stage signals - Pipeline A
  logic [31:0] RD1E_0, RD2E_0, ExTimmE_0;
  logic        RegWriteE_0, JumpE_0, mux2E_0, mux3E_0, mux4E_0;
  logic [2:0]  MemWriteE_0, MemReadE_0;
  logic [4:0]  AluControlE_0, RS1E_0, RS2E_0;
  logic [31:0] alu_out_0, PCTargetE_0, PCTargetE_1;
  logic [31:0] ResultW_0, alu_outM_0;
  
  // ID/EX stage signals - Pipeline B
  logic [31:0] RD1E_1, RD2E_1, ExTimmE_1;
  logic        RegWriteE_1, JumpE_1, BranchE_1, mux2E_1, mux3E_1, mux4E_1;
  logic [1:0]  ResultSrcE_1;
  logic [2:0]  MemWriteE_1, MemReadE_1;
  logic [4:0]  AluControlE_1, RS1E_1, RS2E_1, RdE_1;
  
  // Execute stage signals
  logic [31:0] WriteDataE_1, WriteDataE_0, alu_out_1;
  logic        mux1E_1, mux1E_0;
  
  // EX/MEM stage signals
  logic [31:0] alu_outM_1, WriteDataM_1, PcPlus4M_1, WriteDataM_0;
  logic        RegWriteM_1;
  logic [1:0]  ResultSrcM_0, ResultSrcM_1;
  logic [2:0]  MemWriteM_1, MemReadM_1, MemWriteM_0, MemReadM_0;
  logic [4:0]  RdM_1;
  
  // Memory stage signals
  logic [31:0] ReadDataM_1;
  
  // MEM/WB stage signals
  logic [31:0] AluResultW_0, ReadDataW_1, PCPlus4W_0, PCPlus4W_1;
  logic        RegWriteW_1;
  logic [1:0]  ResultSrcW_0, ResultSrcW_1;
  logic [4:0]  RdW_1;
  
  // Write-back stage signals
  logic [31:0] ResultW_1;
  
  // Hazard unit signals
  logic        StallF, FlushM_0, FlushM_1;
  
  // Additional wires found in instantiations
  logic [31:0] PCE0, PCPlus4E0, PCE1, PCPlus4E1;
  logic [31:0] PcPlus4M_0, AluResultW_1;
  logic [31:0] data_o_1;
  logic [31:0] PCF_0, PCPlus4F_0, PCF_1, PCPlus4F_1;
  
  // Reset signal conversion (active-low to active-high)
  assign rst = ~rstn_i;

  // IF_top instantiation (Fetch stage)
  IF_Top InstructionFetch ( 
    .clk(clk_i),.rst(rst),
    .mux1_a(mux1_0),//A dan gelen branch veya jump
    .mux1_b(mux1_1),     //b den gelen ..
    .PctargetE_a(PCTargetE_0),      
    .PctargetE_b(PCTargetE_1),  
    //burda degiþim var 
    .StallF(StallF),
    
    .PCF_0(PCF_0), .PCPlus4F_0(PCPlus4F_0),.PCF_1(PCF_1), .PCPlus4F_1(PCPlus4F_1),
    .instrF_a(instrF_a),
    .instrF_b(instrF_b)
  );
  assign StallF= StallF_0 || StallF_1;
 
  // if_id instantiation (Fetch/Decode pipeline register)
  if_id PIPE_IF_ID (
    .clk(clk_i),.rst(rst),
    .StallD_0(StallD_0), .StallD_1(StallD_1), .FlushD_0(FlushD_0), .FlushD_1(FlushD_1),
    .PCF_0(PCF_0), .PCPlus4F_0(PCPlus4F_0),.PCF_1(PCF_1), .PCPlus4F_1(PCPlus4F_1),
    .instrF_a(instrF_a), .instrF_b(instrF_b),
    
    .PCD_0(PCD0),    .PCPlus4D_0(PCPlus4D0), .PCD_1(PCD1),    .PCPlus4D_1(PCPlus4D1),
     .instrD_a(instrD_a), .instrD_b(instrD_b) 
     );

ID DECODER (
    
    // 2 adet wire ekleyeceðiz hattýn aktif olduðunu gösteren bir wire ve lseq, lseq iki instructionda memory eriþmeye çal
    .opcode0(opcode0), .opcode1(opcode1),
    .instrD_0(instrD_a), .instrD_1(instrD_b),
    
    .ResultW_0(ResultW_0), .ResultW_1(ResultW_1), .RegWriteW_0(RegWriteW_0), .RegWriteW_1(RegWriteW_1),
    .RdW_0(RdW_0), .RdW_1(RdW_1), .clk(clk_i), .rst(rst),

    .RD1D_0(RD1D_0), .RD2D_0(RD2D_0), .ExtimmD_0(ExtimmD_0), .RegWriteD_0(RegWriteD_0),
    .ResultSrcD_0(ResultSrcD_0), .MemWriteD_0(MemWriteD_0), .MemReadD_0(MemReadD_0),
    .JumpD_0(JumpD_0), .BranchD_0(BranchD_0), .AluControlD_0(AluControlD_0),
    .mux2D_0(mux2D_0), .mux3D_0(mux3D_0), .mux4D_0(mux4D_0),
    .RS1D_0(RS1D_0), .RS2D_0(RS2D_0), .RdD_0(RdD_0),

    .RD1D_1(RD1D_1), .RD2D_1(RD2D_1), .ExtimmD_1(ExtimmD_1), .RegWriteD_1(RegWriteD_1),
    .ResultSrcD_1(ResultSrcD_1), .MemWriteD_1(MemWriteD_1), .MemReadD_1(MemReadD_1),
    .JumpD_1(JumpD_1), .BranchD_1(BranchD_1), .AluControlD_1(AluControlD_1),
    .mux2D_1(mux2D_1), .mux3D_1(mux3D_1), .mux4D_1(mux4D_1),
    .RS1D_1(RS1D_1), .RS2D_1(RS2D_1), .RdD_1(RdD_1)

);

    // ID/EX Pipeline Register
ID_X PIPE_ID_X ( // BURASI SIKINTILI 
        .clk(clk_i), .rst(rst), 
        
        //buraya eklenti yapýldý
//        .FlushE(FlushE),
        .StallE_0(StallE_0), .FlushE_0(FlushE_0),
        .FlushE_1(FlushE_1),        
        .RegWriteD(RegWriteD_1), .ResultSrcD(ResultSrcD_1), .MemWriteD(MemWriteD_1), .MemReadD(MemReadD_1),
        .JumpD(JumpD_1), .BranchD(BranchD_1), .AluControlD(AluControlD_1), .mux2D(mux2D_1), .mux3D(mux3D_1),
        .mux4D(mux4D_1), .RD1D(RD1D_1), .RD2D(RD2D_1), .RS1D(RS1D_1), .RS2D(RS2D_1), .RdD(RdD_1),
        .ExTimmD(ExtimmD_1), .PCD0(PCD0), .PCPlus4D0(PCPlus4D0), .PCD1(PCD1), .PCPlus4D1(PCPlus4D1),
    
        .RD1D_0(RD1D_0), .RD2D_0(RD2D_0), .ExtimmD_0(ExtimmD_0), .RegWriteD_0(RegWriteD_0),
        .ResultSrcD_0(ResultSrcD_0), .MemWriteD_0(MemWriteD_0), .MemReadD_0(MemReadD_0),
        .JumpD_0(JumpD_0), .BranchD_0(BranchD_0), .AluControlD_0(AluControlD_0), .mux2D_0(mux2D_0),
        .mux3D_0(mux3D_0), .mux4D_0(mux4D_0), .RS1D_0(RS1D_0), .RS2D_0(RS2D_0), .RdD_0(RdD_0),
        
        .RegWriteE(RegWriteE_1), .ResultSrcE(ResultSrcE_1), .MemWriteE(MemWriteE_1), .MemReadE(MemReadE_1),
        .JumpE(JumpE_1), .BranchE(BranchE_1), .AluControlE(AluControlE_1), .mux2E(mux2E_1), .mux3E(mux3E_1),
        .mux4E(mux4E_1), .RD1E(RD1E_1), .RD2E(RD2E_1), .RS1E(RS1E_1), .RS2E(RS2E_1), .RdE(RdE_1), .ExTimmE(ExTimmE_1),
        
        .RegWriteE_0(RegWriteE_0), .ResultSrcE_0(ResultSrcE_0), .MemWriteE_0(MemWriteE_0),
        .MemReadE_0(MemReadE_0), .JumpE_0(JumpE_0), .BranchE_0(BranchE_0), .AluControlE_0(AluControlE_0),
        .mux2E_0(mux2E_0), .mux3E_0(mux3E_0), .mux4E_0(mux4E_0), .RD1E_0(RD1E_0), .RD2E_0(RD2E_0),
        .RS1E_0(RS1E_0), .RS2E_0(RS2E_0), .RdE_0(RdE_0), .ExTimmE_0(ExTimmE_0),
        .PCE0(PCE0), .PCPlus4E0(PCPlus4E0), .PCE1(PCE1), .PCPlus4E1(PCPlus4E1)
    );

  // X instantiation (Execute stage)
  //=====================================
  X #(
    .Size(32)
  ) u_x (
    .JumpE(JumpE_1),
    .BranchE(BranchE_1),
    .AluControlE(AluControlE_1),
    .mux2E(mux2E_1),
    .mux3E(mux3E_1),
    .mux4E(mux4E_1),
    .RD1E(RD1E_1),
    .RD2E(RD2E_1),
    .PCE(PCE1),//?? bunu doðrula
    .RS1E(RS1E_1),
    .RS2E(RS2E_1),
    .ExTimmE(ExTimmE_1),
    .ForwardAE(ForwardAE_1),
    .ForwardBE(ForwardBE_1),
    .ResultW_1(ResultW_1),
    
    .ResultW_0(ResultW_0),
    .ALUResultM_0(alu_outM_0),
    
    .ALUResultM_1(alu_outM_1),
    
    .mux1E(mux1_1),
    .WriteDataE(WriteDataE_1),
    .alu_out(alu_out_1),
    .PCTargetE(PCTargetE_1)
  );
  
    X #(
      .Size(32)
    ) SuperX (
      .JumpE(JumpE_0),
      .BranchE(BranchE_0),
      .AluControlE(AluControlE_0),
      .mux2E(mux2E_0),
      .mux3E(mux3E_0),
      .mux4E(mux4E_0),
      .RD1E(RD1E_0),
      .RD2E(RD2E_0),
      .PCE(PCE0),// HERKES KENDI PCCINDE GITMELI
      .RS1E(RS1E_0),
      .RS2E(RS2E_0),
      .ExTimmE(ExTimmE_0),
      .ForwardAE(ForwardAE_0),
      .ForwardBE(ForwardBE_0),
      .ResultW_0(ResultW_0),
      .ALUResultM_0(alu_outM_0),
      
      .ResultW_1(ResultW_1),
      .ALUResultM_1(alu_outM_1),
      
      
      .WriteDataE(WriteDataE_0),
      .mux1E(mux1_0),//bu lazým
      .alu_out(alu_out_0),//bide bu
      .PCTargetE(PCTargetE_0)
    );
    
    //=================================
  // X_Mem instantiation (Execute/Memory pipeline register)
  X_MEM PIPE_X_MEM ( //BÝDE BU HATALI 2 PÝPELÝNE
    .clk(clk_i),
    .rst(rst),
    .FlushM_0(FlushM_0),
    .FlushM_1(FlushM_1),
    
    .RegWriteE_0(RegWriteE_0),
    .ResultSrcE_0(ResultSrcE_0),
    .MemWriteE_0(MemWriteE_0),
    .MemReadE_0(MemReadE_0),
    .AluResultE_0(alu_out_0),
    .RdE_0(RdE_0),
    .PcPlus4E_0(PCPlus4E0),
    .WriteDataE_0(WriteDataE_0),
    
    .RegWriteM_0(RegWriteM_0),
    .ResultSrcM_0(ResultSrcM_0),
    .MemWriteM_0(MemWriteM_0),
    .MemReadM_0(MemReadM_0),
    .AluResultM_0(alu_outM_0),
    .RdM_0(RdM_0),
    .PcPlus4M_0(PcPlus4M_0),
    .WriteDataM_0(WriteDataM_0),
    
    .RegWriteE_1(RegWriteE_1),
    .ResultSrcE_1(ResultSrcE_1),
    .MemWriteE_1(MemWriteE_1),
    .MemReadE_1(MemReadE_1),
    .RdE_1(RdE_1),
    .PcPlus4E_1(PCPlus4E1),
    .AluResultE_1(alu_out_1),
    .WriteDataE_1(WriteDataE_1),
    
    .RegWriteM_1(RegWriteM_1),
    .ResultSrcM_1(ResultSrcM_1),
    .MemWriteM_1(MemWriteM_1),
    .MemReadM_1(MemReadM_1),
    .RdM_1(RdM_1),
    .PcPlus4M_1(PcPlus4M_1),
    .alu_outM_1(alu_outM_1),
    .WriteDataM_1(WriteDataM_1)
  );

  // Mem instantiation (Memory stage)
mem #(
      .MEM_SIZE(8192),
      .DMemInitFile(DMemInitFile),
      .BASE_ADDR(32'h8000_0000)
  ) u_mem (
      .addr_i(addr_i),           // Connected to addr_i
      .clk(clk_i),
      .rst(rst),
      
      .MemWriteM_0(MemWriteM_0),
      .MemReadM_0(MemReadM_0),
      .alu_outM_0(alu_outM_0),
      .WriteDataM_0(WriteDataM_0),
      
      .MemWrite_1(MemWriteM_1),
      .MemRead_1(MemReadM_1),
      .Address_1(alu_outM_1),
      .Write_Data_1(WriteDataM_1),
      
      .ReadDataM(ReadDataM_1),
      .data_o(data_o_1)            // Connected to data_o
  );

  // MEM_WB instantiation (Memory/Write-Back pipeline register)
  MEM_WB PIPE_MEM_WB (
    .clk(clk_i),
    .rst(rst),
    
    .RegWriteM_0(RegWriteM_0),//we
    .ResultSrcM_0(ResultSrcM_0),
    .AluResultM_0(alu_outM_0),
    .RdM_0(RdM_0),
    .PCPlus4M_0(PcPlus4M_0),
    
    .RegWriteW_0(RegWriteW_0),
    .ResultSrcW_0(ResultSrcW_0),
    .AluResultW_0(AluResultW_0),
    .RdW_0(RdW_0),
    .PCPlus4W_0(PCPlus4W_0),
    
    
    .RegWriteM(RegWriteM_1),
    .ResultSrcM(ResultSrcM_1),
    .AluResultM(alu_outM_1),
    .ReadDataM(ReadDataM_1),
    .RdM(RdM_1),
    .PCPlus4M(PcPlus4M_1),
    
    .RegWriteW(RegWriteW_1),
    .ResultSrcW(ResultSrcW_1),
    .AluResultW(AluResultW_1),
    .ReadDataW(ReadDataW_1),
    .RdW(RdW_1),
    .PCPlus4W(PCPlus4W_1)
  );

  // WB instantiation (Write-Back stage)
  assign ResultW_0 = (ResultSrcW_0 == 2'b00) ? AluResultW_0 :
                    (ResultSrcW_0 == 2'b01) ? ReadDataW_1 :// Eðer burasý geldiyse memorye eriþmeye çalýþýyor 
                    (ResultSrcW_0 == 2'b10) ? PCPlus4W_0 :
                    32'b0;

  assign ResultW_1 = (ResultSrcW_1 == 2'b00) ? AluResultW_1 :
                    (ResultSrcW_1 == 2'b01) ? ReadDataW_1 :
                    (ResultSrcW_1 == 2'b10) ? PCPlus4W_1 :
                    32'b0;
  
//====================================buraya kadar

Hazard_unit hazard_unit_inst (
    
    .RdD_0(RdD_0),
    
    .opcode0(opcode0),//bunu decoderdan alcaz
    .opcode1(opcode1),
    .Rs1E_0(RS1E_0),
    .Rs2E_0(RS2E_0),
    .RdM_0(RdM_0),
    .RdW_0(RdW_0),
    .RegWriteM_0(RegWriteM_0),
    .RegWriteW_0(RegWriteW_0),
    .BranchE_0(BranchE_0),
    .Rs1D_0(RS1D_0),
    .Rs2D_0(RS2D_0),
    .RdE_0(RdE_0),
    .ResultSrcE_0(ResultSrcE_0),
    .mux1_0(mux1_0),
    .ResultSrcD_1(ResultSrcD_1),

    // Pipeline 1
    .Rs1E_1(RS1E_1),
    .Rs2E_1(RS2E_1),
    .RdM_1(RdM_1),
    .RdW_1(RdW_1),
    .RegWriteM_1(RegWriteM_1),
    .RegWriteW_1(RegWriteW_1),
    .BranchE_1(BranchE_1),
    .Rs1D_1(RS1D_1),
    .Rs2D_1(RS2D_1),
    .RdE_1(RdE_1),
    .ResultSrcE_1(ResultSrcE_1),
    .mux1_1(mux1_1),


    // === OUTPUTS ===
    // Pipeline 0
    .ForwardAE_0(ForwardAE_0),
    .ForwardBE_0(ForwardBE_0),
    .StallF_0(StallF_0),
    .StallD_0(StallD_0), //bu ok
    .FlushE_0(FlushE_0),
    .StallE_0(StallE_0),
    .FlushD_0(FlushD_0), // bu ok
    .FlushM_0(FlushM_0),

    // Pipeline 1
    .ForwardAE_1(ForwardAE_1),
    .ForwardBE_1(ForwardBE_1),
    .StallF_1(StallF_1),
    .StallD_1(StallD_1),
    .FlushE_1(FlushE_1),
    .FlushD_1(FlushD_1),
    .FlushM_1(FlushM_1)
);


  assign update_o[0]    = (|PCPlus4W_0) && (|instrD_a);           // Register write indicates instruction retirement for pipeline A
  assign pc_o[0]        = PCPlus4W_0-4;       // PC of retired instruction for pipeline A (PCPlus4 - 4 = actual PC)
  assign instr_o[0]     = instrF_a;                // Would need to store instruction through pipeline A
  assign reg_addr_o[0]  = |RegWriteW_0==1 ? RdW_0 : 5'b0;                // Retired register address for pipeline A
  assign reg_data_o[0]  = |RegWriteW_0==1 ? ResultW_0 :32'b0 ;            // Retired register data for pipeline A
  assign mem_addr_o[0]  = alu_outM_0;                // Pipeline A doesn't access memory in this design
  assign mem_data_o[0]  = WriteDataM_1;                // Pipeline A doesn't write memory in this design
  assign mem_wrt_o[0]   = |MemWriteM_1;                 // Pipeline A doesn't write memory

  // Pipeline B (index 1) - Second instruction  
  assign update_o[1]    = (|PCPlus4W_1) && (|instrD_b);           // Register write indicates instruction retirement for pipeline B
  assign pc_o[1]        = PCPlus4W_1-4;       // PC of retired instruction for pipeline B
  assign instr_o[1]     = instrF_b;                // Would need to store instruction through pipeline B
  assign reg_addr_o[1]  = |RegWriteW_0==1 ? RdW_1 :5'b0 ;                // Retired register address for pipeline B
  assign reg_data_o[1]  = |RegWriteW_0==1 ? ResultW_1 :32'b0 ;            // Retired register data for pipeline B
  assign mem_addr_o[1]  = alu_outM_1;           // Memory address from Memory stage (pipeline B handles memory)
  assign mem_data_o[1]  = WriteDataM_1;         // Memory data from Memory stage
  assign mem_wrt_o[1]   = |MemWriteM_1;         // Memory write enable (non-zero MemWriteM indicates write)

  // Connect data_o output
  assign data_o = data_o_1;

endmodule
