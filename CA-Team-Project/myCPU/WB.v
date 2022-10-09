module WB_stage(
    input               clk,
    input               reset,
    // allowin
    output              ws_allowin,
    // input from ID stage
    input               ms_to_ws_valid,
    input   [69:0]      ms_to_ws_bus,//接收MEM阶段传到WB阶段的数据
    // output for reg_file
    output  [38:0]      rf_bus,//传递寄存器相关信号
    //trace debug interface
    output [31:0] debug_wb_pc     ,
    output [ 3:0] debug_wb_rf_we  ,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);

wire        ws_gr_we;
wire [31:0] ws_final_result;
wire [31:0] ws_pc;
wire [4: 0] ws_dest;

wire        ws_rf_we   ;
wire [ 4:0] ws_rf_waddr;
wire [31:0] ws_rf_wdata;

reg         ws_valid;
wire        ws_ready_go;
reg  [69:0] ms_to_ws_bus_r;

assign ws_rf_we    = ws_gr_we && ws_valid;
assign ws_rf_waddr = ws_dest;
assign ws_rf_wdata = ws_final_result;

assign ws_ready_go = 1'b1;
assign ws_allowin  = !ws_valid || ws_ready_go;
always @(posedge clk) begin
    if (reset) begin
        ws_valid <= 1'b0;
    end
    else if (ws_allowin) begin
        ws_valid <= ms_to_ws_valid;
    end
    if (ms_to_ws_valid && ws_allowin) begin
        ms_to_ws_bus_r <= ms_to_ws_bus;
    end
end

//deal with input and output
assign {ws_gr_we,ws_dest,ws_final_result,ws_pc}=ms_to_ws_bus_r;
assign rf_bus={ws_rf_we,ws_rf_waddr,ws_rf_wdata,ws_valid};

// debug info generate
assign debug_wb_pc       = ws_pc;
assign debug_wb_rf_we    = {4{ws_rf_we}};
assign debug_wb_rf_wnum  = ws_rf_waddr;
assign debug_wb_rf_wdata = ws_rf_wdata;

endmodule