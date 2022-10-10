module MEM_stage(
    input               clk,
    input               reset,
    // allowin
    input               ws_allowin,
    output              ms_allowin,
    // input from ID stage
    input               es_to_ms_valid,
    input   [75:0]      es_to_ms_bus,
    // output for MEM stage
    output              ms_to_ws_valid,
    output  [69:0]      ms_to_ws_bus,
    // data sram interface
    input  wire [31:0] data_sram_rdata,
    output              in_ms_valid
);

wire        ms_gr_we;
wire        ms_res_from_mem;
wire [31:0] ms_pc;
wire [4: 0] ms_dest;
wire [31:0] mem_result;
wire [31:0] ms_final_result;
wire [1 :0] byte_sel;
wire [31:0] ld_b_result;
wire [31:0] ld_h_result;
wire [31:0] ld_bu_result;
wire [31:0] ld_hu_result;
wire        insy_ld_b;
wire        inst_ld_w;
wire        inst_ld_h;
wire        inst_ld_bu;
wire        inst_ld_hu;
wire [4: 0] ld_type;

wire [31:0] ms_alu_result;

reg         ms_valid;
wire        ms_ready_go;
reg  [75:0] es_to_ms_bus_r;

assign in_ms_valid    =ms_valid;
assign ms_ready_go    = 1'b1;
assign ms_allowin     = !ms_valid || ms_ready_go && ws_allowin;
assign ms_to_ws_valid = ms_valid && ms_ready_go;
always @(posedge clk) begin
    if (reset) begin
        ms_valid <= 1'b0;
    end
    else if (ms_allowin) begin
        ms_valid <= es_to_ms_valid;
    end
    if (es_to_ms_valid && ms_allowin) begin
        es_to_ms_bus_r  <= es_to_ms_bus;
    end
end
// deal with input and output
assign {ld_type,ms_res_from_mem,ms_gr_we,ms_dest,ms_alu_result,ms_pc}=es_to_ms_bus_r;
assign ms_to_ws_bus={ms_gr_we,ms_dest,ms_final_result,ms_pc};

// load_data
assign {inst_ld_b,inst_ld_bu,inst_ld_h,inst_ld_hu,inst_ld_w}= ld_type;
assign byte_sel = ms_alu_result[1:0];

assign ld_b_result = (!byte_sel[1] && !byte_sel[0]) ? {{24{data_sram_rdata[7]}}, data_sram_rdata[7:0]} :
                     (!byte_sel[1] &&  byte_sel[0]) ? {{24{data_sram_rdata[15]}}, data_sram_rdata[15:8]} :
                     ( byte_sel[1] && !byte_sel[0]) ? {{24{data_sram_rdata[23]}}, data_sram_rdata[23:16]} :
                     ( byte_sel[1] &&  byte_sel[0]) ? {{24{data_sram_rdata[31]}}, data_sram_rdata[31:24]} : 0;
assign ld_bu_result = (!byte_sel[1] && !byte_sel[0]) ? {{24'b0}, data_sram_rdata[7:0]} :
                      (!byte_sel[1] &&  byte_sel[0]) ? {{24'b0}, data_sram_rdata[15:8]} :
                      ( byte_sel[1] && !byte_sel[0]) ? {{24'b0}, data_sram_rdata[23:16]} :
                      ( byte_sel[1] &&  byte_sel[0]) ? {{24'b0}, data_sram_rdata[31:24]} : 0;
assign ld_h_result = (!byte_sel[1] && !byte_sel[0]) ? {{16{data_sram_rdata[15]}}, data_sram_rdata[15:0]} :
                     ( byte_sel[1] && !byte_sel[0]) ? {{16{data_sram_rdata[31]}}, data_sram_rdata[31:16]}: 0;
assign ld_hu_result =(!byte_sel[1] && !byte_sel[0]) ? {{16'b0}, data_sram_rdata[15:0]} : 
                     ( byte_sel[1] && !byte_sel[0]) ? {{16'b0}, data_sram_rdata[31:16]} : 0;

assign mem_result   =   inst_ld_b   ? ld_b_result : 
                        inst_ld_bu  ? ld_bu_result:
                        inst_ld_h   ? ld_h_result :
                        inst_ld_hu  ? ld_hu_result: data_sram_rdata;

assign ms_final_result = ms_res_from_mem ? mem_result : ms_alu_result;




endmodule