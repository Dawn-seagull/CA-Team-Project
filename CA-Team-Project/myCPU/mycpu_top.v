module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_en,
    output wire [3:0]  inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_en,
    output wire [3:0]  data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

wire         ds_allowin;
wire         es_allowin;
wire         ms_allowin;
wire         ws_allowin;
wire         fs_to_ds_valid;
wire         ds_to_es_valid;
wire         es_to_ms_valid;
wire         ms_to_ws_valid;
wire [63:0]  fs_to_ds_bus;
wire [156:0] ds_to_es_bus;
wire [70:0]  es_to_ms_bus;
wire [69:0]  ms_to_ws_bus;
wire [38:0] rf_bus;
wire [33:0] br_bus;
wire         in_es_valid;
wire         in_ms_valid;

// IF stage
IF_stage IF_stage(
    .clk            (clk            ),
    .reset          (~resetn          ),
    // allowin from ID stage
    .ds_allowin     (ds_allowin     ),
    // branch bus
    .br_bus         (br_bus         ),//接收分支指令信号
    // output to ID stage
    .fs_to_ds_valid (fs_to_ds_valid ),
    .fs_to_ds_bus   (fs_to_ds_bus   ),//由IF阶段传到ID阶段的数据
    // inst sram interface
    .inst_sram_en   (inst_sram_en   ),
    .inst_sram_we   (inst_sram_we  ),
    .inst_sram_addr (inst_sram_addr ),
    .inst_sram_wdata(inst_sram_wdata),
    .inst_sram_rdata(inst_sram_rdata)
);
// ID stage
ID_stage ID_stage(
    .clk            (clk            ),
    .reset          (~resetn          ),
    // allowin
    .es_allowin     (es_allowin     ),
    .ds_allowin     (ds_allowin     ),
    // input from IF stage
    .fs_to_ds_valid (fs_to_ds_valid ),
    .fs_to_ds_bus   (fs_to_ds_bus   ),//由IF阶段接受的数据
    // output to EXE stage
    .ds_to_es_valid (ds_to_es_valid ),
    .ds_to_es_bus   (ds_to_es_bus   ),//由ID阶段传到EXE阶段的数据
    // branch bus 
    .br_bus         (br_bus         ),//传递分支指令信号
    // rf bus
    .rf_bus         (rf_bus   ),      //接收寄存器相关信号
    //用于阻塞
    .in_es_valid   (in_es_valid   ),  //接收EXE阶段的valid信号
    .in_ms_valid   (in_ms_valid   ),  //接收MEM阶段的valid信号
    //用于数据前递
    .ms_to_ws_bus   (ms_to_ws_bus   ),//接收由MEM阶段传到WB阶段的数据
    .es_to_ms_bus   (es_to_ms_bus   ) //接收由EXE阶段传到MEM阶段的数据
);
// EXE stage
EXE_stage EXE_stage(
    .clk            (clk            ),
    .reset          (~resetn          ),
    // allowin
    .ms_allowin     (ms_allowin     ),
    .es_allowin     (es_allowin     ),
    // input from ID stage
    .ds_to_es_valid (ds_to_es_valid ),
    .ds_to_es_bus   (ds_to_es_bus   ),//接收ID阶段传到EXE阶段的数据
    // output to MEM stage
    .es_to_ms_valid (es_to_ms_valid ),
    .es_to_ms_bus   (es_to_ms_bus   ),//传递由EXE阶段传到MEM阶段的数据
    // data sram interface
    .data_sram_en   (data_sram_en   ),
    .data_sram_we   (data_sram_we  ),
    .data_sram_addr (data_sram_addr ),
    .data_sram_wdata(data_sram_wdata),
    //hazard
    .in_es_valid    (in_es_valid    )//发送EXE阶段的valid信号
);
// MEM stage
MEM_stage MEM_stage(
    .clk            (clk            ),
    .reset          (~resetn          ),
    // allowin
    .ws_allowin     (ws_allowin     ),
    .ms_allowin     (ms_allowin     ),
    // input from EXE stage
    .es_to_ms_valid (es_to_ms_valid ),
    .es_to_ms_bus   (es_to_ms_bus   ),//接收EXE阶段传到MEM阶段的数据
    // output to WB stage
    .ms_to_ws_valid (ms_to_ws_valid ),
    .ms_to_ws_bus   (ms_to_ws_bus   ),//传递由MEM阶段传到WB阶段的数据
    //from data-sram
    .data_sram_rdata(data_sram_rdata),
     //hazard
    .in_ms_valid    (in_ms_valid    )//发送MEM阶段的valid信号
);
// WB stage
WB_stage WB_stage(
    .clk            (clk            ),
    .reset          (~resetn        ),
    // allowin
    .ws_allowin     (ws_allowin     ),
    // input from MEM stage
    .ms_to_ws_valid (ms_to_ws_valid ),
    .ms_to_ws_bus   (ms_to_ws_bus   ),//接收MEM阶段传到WB阶段的数据
    // rf_bus
    .rf_bus         (rf_bus   ),        //传递寄存器相关信号
    // trace debug interface
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_we   (debug_wb_rf_we  ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
);

endmodule