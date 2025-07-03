`timescale 1ns / 1ps

module Hazard_unit (
    // Pipeline 0 sinyalleri
    input logic [4:0] RdD_0,
    input logic [4:0] Rs1E_0, Rs2E_0,
    input  logic [4:0] RdM_0, RdW_0,
    input  logic       RegWriteM_0, RegWriteW_0, 
    input  logic       BranchE_0,
    output logic [2:0] ForwardAE_0, ForwardBE_0,
    
    input  logic [4:0] Rs1D_0, Rs2D_0,
    input  logic [4:0] RdE_0,
    input  logic [1:0] ResultSrcE_0,ResultSrcD_1,
    
    input  logic       mux1_0,
    output logic       FlushD_0,
    
    // Pipeline 1 sinyalleri
    input logic [4:0] Rs1E_1, Rs2E_1,
    input  logic [4:0] RdM_1, RdW_1,
    input  logic       RegWriteM_1, RegWriteW_1, 
    input  logic       BranchE_1,
    output logic [2:0] ForwardAE_1, ForwardBE_1,
    
    input  logic [4:0] Rs1D_1, Rs2D_1,
    input  logic [4:0] RdE_1,
    input  logic [1:0] ResultSrcE_1,
    input  logic       mux1_1,
    output logic       StallF_0, StallD_0, FlushE_0,StallE_0,FlushM_1,FlushM_0,
    output logic       StallF_1, StallD_1, FlushE_1,
    output logic       FlushD_1,

    input logic [6:0] opcode0,opcode1
);
    parameter LOAD  = 7'b0000011;
    parameter STORE = 7'b0100011;
    logic lseq;
    logic lwStall_0, lwStall_1,branch0,branch1;
    logic newstall;

    // ForwardAE_0 logic (Pipeline 0)
    always_comb begin
        if ((Rs1E_0 == RdM_1) && (RegWriteM_1 || BranchE_1) && (Rs1E_0 != 5'b00000)) begin
               ForwardAE_0 = 3'b101;
           end 
        else if ((Rs1E_0 == RdM_0) && (RegWriteM_0 || BranchE_0) && (Rs1E_0 != 5'b00000)) begin
                       ForwardAE_0 = 3'b010;
                   end      
        else if ((Rs1E_0 == RdW_1) && (RegWriteW_1 || BranchE_1) && (Rs1E_0 != 5'b00000)) begin
               ForwardAE_0 = 3'b100;
           end
        else if ((Rs1E_0 == RdW_0) && (RegWriteW_0 || BranchE_0) && (Rs1E_0 != 5'b00000)) begin
            ForwardAE_0 = 3'b001;
        end
        else begin
            ForwardAE_0 = 3'b000;
        end
    end

    // ForwardBE_0 logic (Pipeline 0)
    always_comb begin
        if ((Rs2E_0 == RdM_1) && (RegWriteM_1 || BranchE_1) && (Rs2E_0 != 5'b00000)) begin
            ForwardBE_0 = 3'b101;
            end   
        else if ((Rs2E_0 == RdM_0) && (RegWriteM_0 || BranchE_0) && (Rs2E_0 != 5'b00000)) begin
                ForwardBE_0 = 3'b010;
            end     
        else if ((Rs2E_0 == RdW_1) && (RegWriteW_1 || BranchE_1) && (Rs2E_0 != 5'b00000)) begin
            ForwardBE_0 = 3'b100;
            end

        else if ((Rs2E_0 == RdW_0) && (RegWriteW_0 || BranchE_0) && (Rs2E_0 != 5'b00000)) begin
            ForwardBE_0 = 3'b001;
        end       
        else begin
            ForwardBE_0 = 3'b000;
        end
    end

    // ForwardAE_1 logic (Pipeline 1)
    always_comb begin
        if ((Rs1E_1 == RdM_1) && (RegWriteM_1 || BranchE_1) && (Rs1E_1 != 5'b00000)) begin
                ForwardAE_1 = 3'b101;
            end    
        else if ((Rs1E_1 == RdM_0) && (RegWriteM_0 || BranchE_0) && (Rs1E_1 != 5'b00000)) begin
                ForwardAE_1 = 3'b010;
            end
        else if ((Rs1E_1 == RdW_1) && (RegWriteW_1 || BranchE_1) && (Rs1E_1 != 5'b00000)) begin
                ForwardAE_1 = 3'b100;
            end   

        else if ((Rs1E_1 == RdW_0) && (RegWriteW_0 || BranchE_0) && (Rs1E_1 != 5'b00000)) begin
            ForwardAE_1 = 3'b001;
        end       
        else begin
            ForwardAE_1 = 3'b000;
        end
    end

    // ForwardBE_1 logic (Pipeline 1)
    always_comb begin//burda neden branch yazmýþým
        if ((Rs2E_1 == RdM_1) && (RegWriteM_1 || BranchE_1) && (Rs2E_1 != 5'b00000)) begin
                ForwardBE_1 = 3'b101;
        end    
        
        else if ((Rs2E_1 == RdM_0) && (RegWriteM_0 || BranchE_0) && (Rs2E_1 != 5'b00000)) begin
                    ForwardBE_1 = 3'b010;
        end
                
        else if ((Rs2E_1 == RdW_1) && (RegWriteW_1 || BranchE_1) && (Rs2E_1 != 5'b00000)) begin
                   ForwardBE_1 = 3'b100;
        end
        
        
        else if ((Rs2E_1 == RdW_0) && (RegWriteW_0 || BranchE_0) && (Rs2E_1 != 5'b00000)) begin
            ForwardBE_1 = 3'b001;
        end
        else begin
            ForwardBE_1 = 3'b000;
        end
    end

    // Load-use hazard detection (Pipeline 0)
    assign lseq = (opcode0 == LOAD || opcode0 == STORE) &&  (opcode1 == LOAD || opcode1 == STORE);
    assign newstall = (((RdD_0==Rs1D_1 )&& (RdD_0!=5'b0)) || (RdD_0==Rs2D_1)&& (RdD_0!=5'b0)) && ((ResultSrcD_1== 2'b01) || (ResultSrcD_1== 2'b00)) ;// ResultSrcE 01 mi olmalý ve 0 için stallf FlushD,  1 için stallF, Stalld FlushE
    assign lwStall_0 = (((Rs1D_0 == RdE_0) || (Rs2D_0 == RdE_0)) && (ResultSrcE_0 == 2'b01)) ||
                                        ((((Rs1D_0 == RdE_1) || (Rs2D_0 == RdE_1)) && (ResultSrcE_1 == 2'b01))) ; //bu load için stall atma
    assign StallF_0  = lwStall_0 || lwStall_1 || lseq ||newstall  ;
    assign StallD_0  = lwStall_0 || lwStall_1 || lseq  ;    
    assign StallE_0 = lseq;

    assign FlushD_0  = mux1_0  || (mux1_1) || newstall ;
    assign FlushE_0  = lwStall_0 || mux1_0 || (mux1_1) ;    
    assign FlushM_0 = lseq;


    
    // Load-use hazard detection (Pipeline 1)
    assign lwStall_1 = (((Rs1D_1 == RdE_0) || (Rs2D_1 == RdE_0)) && (ResultSrcE_0 == 2'b01)) ||
                                            (((Rs1D_1 == RdE_1) || (Rs2D_1 == RdE_1)) && (ResultSrcE_1 == 2'b01)) ;
                                                                            
    assign StallF_1  = lwStall_1 || lseq ||newstall ||lwStall_0 ;
    assign StallD_1  = lwStall_1   ||newstall ||lwStall_0;
    
    assign FlushD_1  = (mux1_1)|| (mux1_0)|| lseq;
    assign FlushE_1  = lwStall_1 || mux1_1 || (mux1_0) ||newstall ;
    assign FlushM_1  =  mux1_0;


endmodule
