module register (
    input logic clk, rst,
    input logic [4:0] rd_addr0, rd_addr1,
    input logic [4:0] rd_addr2, rd_addr3,
    input logic [4:0] wr_addr0, wr_addr1,
    input logic [31:0] wr_din0, wr_din1,
    input logic we0,we1,
    output logic [31:0] rd_dout0, rd_dout1, rd_dout2,rd_dout3
//    input integer LogFile
);

    logic [31:0] mem [0:31];
    
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) mem[i] <= 32'b0;       
        end else begin
            if ((we0 && (wr_addr0 != 5'h0))  && !(we1 && (wr_addr1 == wr_addr0))) begin
                mem[wr_addr0] <= wr_din0;   
            end
            if (we1 && (wr_addr1 != 5'h0)) begin
                mem[wr_addr1] <= wr_din1;
            end
        end
    end
    
    assign rd_dout0 = (rd_addr0 == 5'h0) ? 32'b0 : (we1 && (rd_addr0 == wr_addr1)) ? wr_din1 :
                                            (we0 && (rd_addr0 == wr_addr0)) ? wr_din0 : mem[rd_addr0];
    
    assign rd_dout1 = (rd_addr1 == 5'h0) ? 32'b0 : (we1 && (rd_addr1 == wr_addr1)) ? wr_din1 :
                                            (we0 && (rd_addr1 == wr_addr0)) ? wr_din0 : mem[rd_addr1];
    
    assign rd_dout2 = (rd_addr2 == 5'h0) ? 32'b0 : (we1 && (rd_addr2 == wr_addr1)) ? wr_din1 :
                                            (we0 && (rd_addr2 == wr_addr0)) ? wr_din0 : mem[rd_addr2];
    
    assign rd_dout3 = (rd_addr3 == 5'h0) ? 32'b0 : (we1 && (rd_addr3 == wr_addr1)) ? wr_din1 :
                                            (we0 && (rd_addr3 == wr_addr0)) ? wr_din0 : mem[rd_addr3];   
//       assign rd_dout0 = (rd_addr0 == 5'h0) ? 32'b0 : mem[rd_addr0];       
//       assign rd_dout1 = (rd_addr1 == 5'h0) ? 32'b0 : mem[rd_addr1];       
//       assign rd_dout2 = (rd_addr2 == 5'h0) ? 32'b0 : mem[rd_addr2];       
//       assign rd_dout3 = (rd_addr3 == 5'h0) ? 32'b0 : mem[rd_addr3];       
endmodule
