module MEM_stage(
    input               clk,
    input               reset,
    // allowin
    input               ws_allowin,
    output              ms_allowin,
    // input from ID stage
    input               es_to_ms_valid,
    input   [70:0]      es_to_ms_bus,
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

wire [31:0] ms_alu_result;

reg         ms_valid;
wire        ms_ready_go;
reg  [70:0] es_to_ms_bus_r;

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
assign {ms_res_from_mem,ms_gr_we,ms_dest,ms_alu_result,ms_pc}=es_to_ms_bus_r;
assign ms_to_ws_bus={ms_gr_we,ms_dest,ms_final_result,ms_pc};


assign mem_result   = data_sram_rdata;
assign ms_final_result = ms_res_from_mem ? mem_result : ms_alu_result;




endmodule