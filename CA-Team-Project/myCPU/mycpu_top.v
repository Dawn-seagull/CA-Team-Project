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
    .br_bus         (br_bus         ),//���շ�ָ֧���ź�
    // output to ID stage
    .fs_to_ds_valid (fs_to_ds_valid ),
    .fs_to_ds_bus   (fs_to_ds_bus   ),//��IF�׶δ���ID�׶ε�����
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
    .fs_to_ds_bus   (fs_to_ds_bus   ),//��IF�׶ν��ܵ�����
    // output to EXE stage
    .ds_to_es_valid (ds_to_es_valid ),
    .ds_to_es_bus   (ds_to_es_bus   ),//��ID�׶δ���EXE�׶ε�����
    // branch bus 
    .br_bus         (br_bus         ),//���ݷ�ָ֧���ź�
    // rf bus
    .rf_bus         (rf_bus   ),      //���ռĴ�������ź�
    //��������
    .in_es_valid   (in_es_valid   ),  //����EXE�׶ε�valid�ź�
    .in_ms_valid   (in_ms_valid   ),  //����MEM�׶ε�valid�ź�
    //��������ǰ��
    .ms_to_ws_bus   (ms_to_ws_bus   ),//������MEM�׶δ���WB�׶ε�����
    .es_to_ms_bus   (es_to_ms_bus   ) //������EXE�׶δ���MEM�׶ε�����
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
    .ds_to_es_bus   (ds_to_es_bus   ),//����ID�׶δ���EXE�׶ε�����
    // output to MEM stage
    .es_to_ms_valid (es_to_ms_valid ),
    .es_to_ms_bus   (es_to_ms_bus   ),//������EXE�׶δ���MEM�׶ε�����
    // data sram interface
    .data_sram_en   (data_sram_en   ),
    .data_sram_we   (data_sram_we  ),
    .data_sram_addr (data_sram_addr ),
    .data_sram_wdata(data_sram_wdata),
    //hazard
    .in_es_valid    (in_es_valid    )//����EXE�׶ε�valid�ź�
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
    .es_to_ms_bus   (es_to_ms_bus   ),//����EXE�׶δ���MEM�׶ε�����
    // output to WB stage
    .ms_to_ws_valid (ms_to_ws_valid ),
    .ms_to_ws_bus   (ms_to_ws_bus   ),//������MEM�׶δ���WB�׶ε�����
    //from data-sram
    .data_sram_rdata(data_sram_rdata),
     //hazard
    .in_ms_valid    (in_ms_valid    )//����MEM�׶ε�valid�ź�
);
// WB stage
WB_stage WB_stage(
    .clk            (clk            ),
    .reset          (~resetn        ),
    // allowin
    .ws_allowin     (ws_allowin     ),
    // input from MEM stage
    .ms_to_ws_valid (ms_to_ws_valid ),
    .ms_to_ws_bus   (ms_to_ws_bus   ),//����MEM�׶δ���WB�׶ε�����
    // rf_bus
    .rf_bus         (rf_bus   ),        //���ݼĴ�������ź�
    // trace debug interface
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_we   (debug_wb_rf_we  ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
);

endmodule