`timescale 1ns / 1ps
module mem #(
    parameter MEM_SIZE = 8192,           // Memory size in words
    parameter DMemInitFile = "dmem.mem", // Initialization file
    parameter BASE_ADDR = 32'h8000_0000  // Base address
)(
    input [31:0] addr_i,  // memory address input for reading
    input clk, rst,
    input [2:0] MemWriteM_0,MemWrite_1,
    input [2:0] MemRead_1,MemReadM_0,
    input [31:0] alu_outM_0,Address_1,
    input [31:0] Write_Data_1,WriteDataM_0,
    
    output reg [31:0] ReadDataM,
    output reg [31:0] data_o
);
   logic sel;
   logic [31:0] Write_Data;
   logic [2:0] MemRead,MemWrite;
   logic write_enable;
   
   logic [31:0] mem [0:8191];                                      
   logic [31:0] Address;
   integer i;
   initial begin
        $readmemh(DMemInitFile, mem);  // Corrected initialization file parameter
    end 
    assign Address = (sel==1) ? Address_1 : alu_outM_0;
    assign MemRead =  (sel==1) ? MemRead_1 : MemReadM_0; // bunlar deðiþcek sanýýrm bi bak
    assign MemWrite = (sel==1) ? MemWrite_1 : MemWriteM_0 ;
    assign Write_Data = (sel==1) ? Write_Data_1 : WriteDataM_0;
    assign sel=  ((|MemWrite_1) || (|MemRead_1));
    assign write_enable = (|MemWriteM_0)  ||   (|MemWrite_1); 
    logic [31:0] word_address = Address - BASE_ADDR;  // Consistent base address
        
    // Write operations
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset the entire memory to 0
            for (i = 0; i < MEM_SIZE; i = i + 1) begin
                mem[i] <= 32'b0;
            end
        end 
        else if (write_enable) begin
            case(MemWrite)
                3'b001: begin // SB (Store Byte)
                    mem[word_address[14:2]][7:0] <= Write_Data[7:0];
                end
                3'b010: begin // SH (Store Halfword)
                    mem[word_address[14:2]][15:0] <= Write_Data[15:0];
                end
                3'b100: begin // SW (Store Word)
                    mem[word_address[14:2]] <= Write_Data;
                end
                default: ; // Do nothing
            endcase
        end
    end

    // Read operations
    always @(*) begin
        ReadDataM = 32'b0; // Default value
        if (|MemRead) begin
            case(MemRead)
                3'b001: begin // LBU (Load Byte Unsigned)
                    ReadDataM = {24'b0, mem[word_address[14:2]][7:0]};
                end
                3'b010: begin // LHU (Load Halfword Unsigned)
                    ReadDataM = {16'b0, mem[word_address[14:2]][15:0]};
                end
                3'b011: begin // LB (Load Byte)
                    ReadDataM = {{24{mem[word_address[14:2]][7]}}, mem[word_address[14:2]][7:0]};
                end
                3'b100: begin // LH (Load Halfword)
                    ReadDataM = {{16{mem[word_address[14:2]][15]}}, mem[word_address[14:2]][15:0]};
                end
                3'b101: begin // LW (Load Word)
                    ReadDataM = mem[word_address[14:2]];
                end
                default: ReadDataM = 32'b0;
            endcase
        end
    end
    always @(*) begin
        data_o = mem[addr_i[14:2]];  // Simple word read
    end
endmodule
