`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// mat_mul.v
//
// Uppsala University
// Yuan Yao <yuan.yao@it.uu.se>
// For the course 1DT109 Accelerating System with Programmable Logic Components
//
//////////////////////////////////////////////////////////////////////////////////


module mat_mul #
    (
        parameter integer DIM_LOG = 2,     /* matrix dimension in log2; e.g. A[8][8] has the DIM of 8, DIM_LOG of 3, and SIZE of 64; change this as desired;
                                              you will need to set this parameter in the testbench and the ARM software in the SDK. */
        parameter integer DIM = 2**DIM_LOG,
        parameter integer SIZE = DIM*DIM,
        parameter integer SIZE_LOG = 2*DIM_LOG,
        parameter integer DATA_WIDTH = 32
    )
    (
        // Clock and Reset shared with the AXI-Lite Slave Port
        input wire  s00_axi_aclk,
        input wire  s00_axi_aresetn,
        
        // AXI-Stream Slave
        output wire  s00_axis_tready,
        input  wire  [DATA_WIDTH-1 : 0] s00_axis_tdata,
        input  wire  s00_axis_tlast,
        input  wire  s00_axis_tvalid,
        
        // AXI-Stream Master
        output wire  m00_axis_tvalid,
        output wire  [DATA_WIDTH-1 : 0] m00_axis_tdata,
        output wire  [(DATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
        output wire  m00_axis_tlast,
        input  wire  m00_axis_tready,
        
        // Matrix-select and Start signals coming from the AXI-Lite Slave Port
        input wire sel,
        input wire start
    );

//TODO
    wire en_A;
    wire en_B;
    wire en_R;
    wire rw_A;
    wire rw_B;
    wire rw_R;
    wire [SIZE_LOG-1 : 0]addr_A;
    wire [SIZE_LOG-1 : 0]addr_B;
    wire [SIZE_LOG-1 : 0]addr_R;
    wire [DATA_WIDTH-1:0]data_A;
    wire [DATA_WIDTH-1:0]data_B;
    wire [DATA_WIDTH-1:0]data_R;
    wire clear;
    reg clear_delay;
    
    assign clear = en_R & (addr_A % DIM == 0);
    
    always @(posedge s00_axi_aclk or negedge s00_axi_aresetn) begin
        if (!s00_axi_aresetn)
            clear_delay <= 0;
        else
            clear_delay <= clear;
    end
    

    bram # (
    .DIM_LOG(DIM_LOG),
    .DATA_WIDTH(DATA_WIDTH)
    ) bramA (
    .s00_axi_aclk(s00_axi_aclk),
    .s00_axi_aresetn(s00_axi_aresetn),  
    .en(en_A),
    .rw(rw_A),
    .addr(addr_A),
    .data_in(s00_axis_tdata),
    .data_out(data_A)
    );
    
    bram # (
    .DIM_LOG(DIM_LOG),
    .DATA_WIDTH(DATA_WIDTH)
    ) bramB (
    .s00_axi_aclk(s00_axi_aclk),
    .s00_axi_aresetn(s00_axi_aresetn),  
    .en(en_B),
    .rw(rw_B),
    .addr(addr_B),
    .data_in(s00_axis_tdata),
    .data_out(data_B)
    );
    
    bram # (
    .DIM_LOG(DIM_LOG),
    .DATA_WIDTH(DATA_WIDTH)
    ) bramR (
    .s00_axi_aclk(s00_axi_aclk),
    .s00_axi_aresetn(s00_axi_aresetn),  
    .en(en_R),
    .rw(rw_R),
    .addr(addr_R),
    .data_in(data_R),
    .data_out(m00_axis_tdata)
    );
    
    MAC # (
    .DIM_LOG(DIM_LOG),
    .DATA_WIDTH(DATA_WIDTH)
    ) mac0 (
    .s00_axi_aclk(s00_axi_aclk),
    .s00_axi_aresetn(s00_axi_aresetn),
    .clear(clear_delay),
    .data_A(data_A),
    .data_B(data_B),
    .data_R(data_R)
    );
    
    AGU # (
    .DIM_LOG(DIM_LOG),
    .DATA_WIDTH(DATA_WIDTH)
    ) agu0 (
    .s00_axi_aclk(s00_axi_aclk),
    .s00_axi_aresetn(s00_axi_aresetn),
    .s00_axis_tready(s00_axis_tready),
    .s00_axis_tlast(s00_axis_tlast),
    .s00_axis_tvalid(s00_axis_tvalid),
    .m00_axis_tvalid(m00_axis_tvalid),
    .m00_axis_tlast(m00_axis_tlast),
    .m00_axis_tready(m00_axis_tready),
    .sel(sel),
    .start(start),
    .en_A(en_A),
    .en_B(en_B),
    .en_R(en_R),
    .rw_A(rw_A),
    .rw_B(rw_B),
    .rw_R(rw_R),
    .addr_A(addr_A),
    .addr_B(addr_B),
    .addr_R(addr_R)
    );
       
endmodule

module bram #
(
    parameter integer DIM_LOG = 1,
    parameter integer DIM = 2**DIM_LOG,
    parameter integer SIZE = DIM*DIM,
    parameter integer SIZE_LOG = 2*DIM_LOG,
    parameter integer DATA_WIDTH = 32
)
(
    input wire s00_axi_aclk,
    input wire s00_axi_aresetn,  
    input wire en,
    input wire rw,
    input wire [SIZE_LOG-1 : 0] addr,
    input wire [DATA_WIDTH-1 : 0] data_in,
    output reg [DATA_WIDTH-1 : 0] data_out
);

//TODO
    reg [DATA_WIDTH-1:0] memory [0:SIZE-1];
    
    always @(posedge s00_axi_aclk) begin
        if (en)
            if (rw)
                memory[addr] <= data_in;
            else
                data_out <= memory[addr];
    end 

endmodule

module MAC #
(
    parameter integer DIM_LOG = 1,
    parameter integer DIM = 2**DIM_LOG,
    parameter integer SIZE = DIM*DIM,
    parameter integer SIZE_LOG = 2*DIM_LOG,
    parameter integer DATA_WIDTH = 32
)
(
    input wire s00_axi_aclk,
    input wire s00_axi_aresetn,
    input wire clear, 
    input wire [DATA_WIDTH-1 : 0] data_A,
    input wire [DATA_WIDTH-1 : 0] data_B,
    output wire [DATA_WIDTH-1 : 0] data_R
);
    
    reg [DATA_WIDTH-1:0]data = 0;
//TODO
    always @(posedge s00_axi_aclk, negedge s00_axi_aresetn) begin
        if (!s00_axi_aresetn)
            data <= 0;
        else
            if (clear) begin
                data <= data_A * data_B;
            end else begin
                data <= data + (data_A * data_B);
            end 
    end
    
    assign data_R = data;

endmodule

module AGU #
(
    parameter integer DIM_LOG = 1,
    parameter integer DIM = 2**DIM_LOG,
    parameter integer SIZE = DIM*DIM,
    parameter integer SIZE_LOG = 2*DIM_LOG,
    parameter integer DATA_WIDTH = 32
)
(
    input wire  s00_axi_aclk,
    input wire  s00_axi_aresetn,
    
    // AXI-Stream Slave
    output reg  s00_axis_tready,
    input wire  s00_axis_tlast,
    input wire  s00_axis_tvalid,
        
    // AXI-Stream Master
    output reg  m00_axis_tvalid,
    output reg  m00_axis_tlast,
    input wire  m00_axis_tready,
    
    input wire sel,
    input wire start,
    
    output reg en_A,
    output reg en_B,
    output reg en_R,
    output reg rw_A,
    output reg rw_B,
    output reg rw_R,
    output reg [SIZE_LOG-1 : 0] addr_A,
    output reg [SIZE_LOG-1 : 0] addr_B,
    output reg [SIZE_LOG-1 : 0] addr_R
);

//TODO
    localparam
        S_IDLE = 4'b0000,
        S_LOAD_A = 4'b0001,
        S_LOAD_B = 4'b0010,
        S_CALCULATE = 4'b0100,
        S_OUTPUT = 4'b1000;        
    
    reg [3:0]current_state;
    reg [3:0]next_state;
    reg [DIM_LOG-1:0]row;
    reg [DIM_LOG-1:0]col;
    reg [DIM_LOG-1:0]temp;
    reg [1:0]matrix_filled;
    reg calcul_finish;
    
    reg [1:0]rw_R_temp;
    reg addr_R_temp;
    reg tvalid_temp;
    reg tlast_temp;
    
    //next state block (combinational)
    always @(*) begin
        next_state = current_state;
        
        case(current_state)
        S_IDLE: begin            
            if (start && matrix_filled == 2'b11) begin
                next_state = S_CALCULATE;
            end else begin
                if (s00_axis_tvalid) begin
                    if (matrix_filled != 2'b11) begin
                        next_state = sel ? S_LOAD_B : S_LOAD_A;
                    end
                end
            end
        end
        S_LOAD_A: begin
            if (s00_axis_tvalid && s00_axis_tready && s00_axis_tlast) begin
                next_state = S_IDLE;
            end
        end
        S_LOAD_B: begin
            if (s00_axis_tvalid && s00_axis_tready && s00_axis_tlast) begin
                next_state = S_IDLE;
            end
        end
        S_CALCULATE: begin
            if (addr_R == SIZE - 1 && rw_R) begin
                next_state = S_OUTPUT;
            end
        end
        S_OUTPUT: begin
            if (!m00_axis_tready) begin
                next_state = S_IDLE;
            end
        end
        default:
            next_state = S_IDLE;
        endcase
    end
    
    //current state block (sequential)
    always @(posedge s00_axi_aclk, negedge s00_axi_aresetn) begin
        if (!s00_axi_aresetn) begin
            current_state <= 1'b0;
            s00_axis_tready <= 1'b0;
            m00_axis_tvalid <= 1'b0;
            m00_axis_tlast <= 1'b0;
            en_A <= 1'b0;
            en_B <= 1'b0;
            en_R <= 1'b0;
            rw_A <= 1'b0;
            rw_B <= 1'b0;
            rw_R_temp <= 2'b00;
            rw_R <= 1'b0;
            addr_A <= 'b0;
            addr_B <= 'b0;
            addr_R_temp <= 'b0;
            addr_R <= 'b0;
            matrix_filled <= 2'b00;
            calcul_finish <= 0;
            tvalid_temp <= 0;
            tlast_temp <= 0;
        end else begin
            current_state <= next_state;
            s00_axis_tready <= (current_state == S_LOAD_A) || (current_state == S_LOAD_B);
            
            case(current_state)
            S_IDLE: begin
                m00_axis_tvalid <= 1'b0;
                m00_axis_tlast <= 1'b0;
                row <= 0;
                col <= 0;
                temp <= 0;
                en_A <= 1'b0;
                rw_A <= 1'b0;
                en_B <= 1'b0;
                rw_B <= 1'b0;
            end
            S_LOAD_A: begin
                if (s00_axis_tvalid) begin                    
                    addr_A <= {row, temp};
                    
                    en_A <= 1'b1;
                    rw_A <= 1'b1;
                    
                    if (temp == DIM - 1) begin
                        temp <= 0;
                        
                        if (row == DIM - 1) begin
                            row <= 0;
                            
                            if (s00_axis_tvalid && s00_axis_tready && s00_axis_tlast) begin
                                matrix_filled <= matrix_filled | 2'b01;
                            end
                        end else begin
                            row <= row + 1;
                        end
                    end else begin
                        temp <= temp + 1;
                    end
                end else begin
                    en_A <= 1'b0;
                    rw_A <= 1'b0;
                end
            end                
            S_LOAD_B: begin
                if (s00_axis_tvalid) begin                    
                    addr_B <= {row, temp};
                    
                    en_B <= 1'b1;
                    rw_B <= 1'b1;
                    
                    if (temp == DIM - 1) begin
                        temp <= 0;
                        
                        if (row == DIM - 1) begin
                            row <= 0;
                            
                            if (s00_axis_tvalid && s00_axis_tready && s00_axis_tlast)
                                matrix_filled <= matrix_filled | 2'b10;
                        end else begin
                            row <= row + 1;
                        end
                    end else begin
                        temp <= temp + 1;
                    end
                end else begin
                    en_B <= 1'b0;
                    rw_B <= 1'b0;
                end
            end
            S_CALCULATE: begin
                en_A <= 1;
                en_B <= 1;
                en_R <= 1;
                rw_R_temp <= {rw_R_temp[0], (temp == DIM - 1)};
                rw_R <= rw_R_temp[1];
                
                addr_A <= {row, temp};
                addr_B <= {temp, col};
                addr_R <= rw_R ? addr_R + 1 : addr_R;
                
                if (!calcul_finish) begin
                    if (temp == DIM - 1) begin
                        temp <= 0;
                        
                        if (col == DIM - 1) begin
                            col <= 0;
                            
                            if (row == DIM - 1) begin
                                row <= 0;
                                
                                calcul_finish <= 1;
                            end else begin
                                row <= row + 1;
                            end
                        end else begin
                            col <= col + 1;
                        end
                    end else begin
                        temp <= temp + 1;
                    end
                end
            end
            S_OUTPUT: begin
                en_R <= 1;
                rw_R <= 0;
                
                tvalid_temp <= 1;
                m00_axis_tvalid <= tvalid_temp;
                
                tlast_temp <= (row == DIM - 1 && temp == DIM - 1);
                m00_axis_tlast <= tlast_temp;
                
                addr_R <= {row, temp};
                
                if (temp == DIM - 1) begin
                    temp <= 0;
                    
                    if (row == DIM - 1) begin
                        row <= 0;
                        
                    end else begin
                        row <= row + 1;
                    end
                end else begin
                    temp <= temp + 1;
                end
            end  
            endcase
        end
    end 
    
endmodule
