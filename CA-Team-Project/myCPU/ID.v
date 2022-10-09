module ID_stage(
    input           clk,
    input           reset,
    // allowin
    input           es_allowin,
    output          ds_allowin,
    // input from IF stage
    input           fs_to_ds_valid,
    input   [63:0]  fs_to_ds_bus,//由IF阶段接受的数�?
    // output to EXE stage
    output          ds_to_es_valid,
    output  [156:0] ds_to_es_bus,//由ID阶段传到EXE阶段的数�?
    // branch bus
    output  [33:0]  br_bus,     //传�?�分支指令信�?
    // input from WB stage for reg_file
    input   [38:0]  rf_bus,     //接收寄存器相关信�?
    input           in_ms_valid,//接收MEM阶段的valid信号
    input           in_es_valid,//接收EXE阶段的valid信号
    input   [69:0]  ms_to_ws_bus,//接收由MEM阶段传到WB阶段的数�?
    input   [70:0]  es_to_ms_bus //接收由EXE阶段传到MEM阶段的数�?
);

reg         ds_valid;
wire        ds_ready_go;
reg  [63:0] fs_to_ds_bus_r;

wire [31:0] ds_pc;
wire [31:0] ds_inst;

wire        br_taken;
wire        br_taken_cancle;
wire [31:0] br_target;

wire [11:0] ds_alu_op;
wire        ds_src1_is_pc;
wire        ds_src2_is_ds_imm;
wire        ds_res_from_mem;
wire        dst_is_r1;
wire        ds_gr_we;
wire        ds_mem_we;
wire        src_reg_is_rd;
wire [4: 0] ds_dest;
wire [31:0] ds_rj_value;
wire [31:0] ds_rkd_value;
wire [31:0] ds_imm;
wire [31:0] br_offs;
wire [31:0] jirl_offs;

wire [ 5:0] op_31_26;
wire [ 3:0] op_25_22;
wire [ 1:0] op_21_20;
wire [ 4:0] op_19_15;
wire [ 4:0] rd;
wire [ 4:0] rj;
wire [ 4:0] rk;
wire [11:0] i12;
wire [19:0] i20;
wire [15:0] i16;
wire [25:0] i26;

wire [63:0] op_31_26_d;
wire [15:0] op_25_22_d;
wire [ 3:0] op_21_20_d;
wire [31:0] op_19_15_d;

wire        inst_add_w;
wire        inst_sub_w;
wire        inst_slt;
wire        inst_sltu;
wire        inst_nor;
wire        inst_and;
wire        inst_or;
wire        inst_xor;
wire        inst_slli_w;
wire        inst_srli_w;
wire        inst_srai_w;
wire        inst_addi_w;
wire        inst_ld_w;
wire        inst_st_w;
wire        inst_jirl;
wire        inst_b;
wire        inst_bl;
wire        inst_beq;
wire        inst_bne;
wire        inst_lu12i_w;
wire        inst_slti;
wire        inst_sltui;
wire        inst_andi;
wire        inst_ori;
wire        inst_xori;
wire        inst_sll_w;
wire        inst_srl_w;
wire        inst_sra_w;
wire        inst_pcaddu12i;
wire        inst_mul_w;
wire        inst_mulh_w;
wire        inst_mulh_wu;
wire        inst_div_w;
wire        inst_mod_w;
wire        inst_div_wu;
wire        inst_mod_wu;

wire        need_ui5;
wire        need_si12;
wire        need_si16;
wire        need_si20;
wire        need_si26;
wire        src2_is_4;
wire        need_ui12;

wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;
wire        ds_rf_we   ;
wire [ 4:0] ds_rf_waddr;
wire [31:0] ds_rf_wdata;

wire        src1_hazard;
wire        src2_hazard;
wire        either_hazard;
wire        both_src;
wire        src_rj;
wire        src_rd;
wire        hazard;
wire        es_gr_we;
wire        ms_gr_we;
wire        es_valid;
wire        ms_valid;
wire        ws_valid;
wire        es_res_from_mem;
wire [ 4:0] es_dest;
wire [ 4:0] ms_dest;
wire [31:0] es_alu_result;
wire [31:0] ms_alu_result;
 
assign op_31_26  = ds_inst[31:26];
assign op_25_22  = ds_inst[25:22];
assign op_21_20  = ds_inst[21:20];
assign op_19_15  = ds_inst[19:15];

assign rd   = ds_inst[ 4: 0];
assign rj   = ds_inst[ 9: 5];
assign rk   = ds_inst[14:10];

assign i12  = ds_inst[21:10];
assign i20  = ds_inst[24: 5];
assign i16  = ds_inst[25:10];
assign i26  = {ds_inst[ 9: 0], ds_inst[25:10]};

decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];
assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
assign inst_jirl   = op_31_26_d[6'h13];
assign inst_b      = op_31_26_d[6'h14];
assign inst_bl     = op_31_26_d[6'h15];
assign inst_beq    = op_31_26_d[6'h16];
assign inst_bne    = op_31_26_d[6'h17];
assign inst_lu12i_w= op_31_26_d[6'h05] & ~ds_inst[25];
assign inst_slti   = op_31_26_d[6'h00] & op_25_22_d[4'h8];
assign inst_sltui  = op_31_26_d[6'h00] & op_25_22_d[4'h9];
assign inst_andi   = op_31_26_d[6'h00] & op_25_22_d[4'hd];
assign inst_ori    = op_31_26_d[6'h00] & op_25_22_d[4'he];
assign inst_xori   = op_31_26_d[6'h00] & op_25_22_d[4'hf];
assign inst_sll_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0e];
assign inst_srl_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0f];
assign inst_sra_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];
assign inst_pcaddu12i = op_31_26_d[6'h07] & ~ds_inst[25];
assign inst_mul_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h18];
assign inst_mulh_w = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h19];
assign inst_mulh_wu = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h1a];
assign inst_div_w  = op_31_26_d[6'h00] & op_25_22_d[5'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h00];
assign inst_mod_w  = op_31_26_d[6'h00] & op_25_22_d[5'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h01];
assign inst_div_wu = op_31_26_d[6'h00] & op_25_22_d[5'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h02];
assign inst_mod_wu = op_31_26_d[6'h00] & op_25_22_d[5'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h03];

assign ds_alu_op[ 0] = inst_add_w | inst_addi_w | inst_ld_w | inst_st_w
                    | inst_jirl | inst_bl | inst_pcaddu12i;
assign ds_alu_op[ 1] = inst_sub_w;
assign ds_alu_op[ 2] = inst_slt | inst_slti;
assign ds_alu_op[ 3] = inst_sltu | inst_sltui;
assign ds_alu_op[ 4] = inst_and | inst_andi;
assign ds_alu_op[ 5] = inst_nor;
assign ds_alu_op[ 6] = inst_or | inst_ori;
assign ds_alu_op[ 7] = inst_xor | inst_xori;
assign ds_alu_op[ 8] = inst_slli_w | inst_sll_w;
assign ds_alu_op[ 9] = inst_srli_w | inst_srl_w;
assign ds_alu_op[10] = inst_srai_w | inst_sra_w;
assign ds_alu_op[11] = inst_lu12i_w;

assign need_ui5   =  inst_slli_w | inst_srli_w | inst_srai_w;
assign need_si12  =  inst_addi_w | inst_ld_w | inst_st_w | inst_slti | inst_sltui;
assign need_si16  =  inst_jirl | inst_beq | inst_bne;
assign need_si20  =  inst_lu12i_w | inst_pcaddu12i;
assign need_si26  =  inst_b | inst_bl;
assign src2_is_4  =  inst_jirl | inst_bl;
assign need_ui12  =  inst_andi | inst_ori | inst_xori;

assign ds_imm = src2_is_4 ? 32'h4                      :
             need_si20 ? {i20[19:0], 12'b0}         :
             need_ui12 ? {20'b0, i12[11:0]}         :
/*need_ui5 || need_si12*/{{20{i12[11]}}, i12[11:0]} ;

assign br_offs = need_si26 ? {{4{i26[25]}}, i26[25:0], 2'b0} : 
                             {{14{i16[15]}}, i16[15:0], 2'b0} ;

assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

assign src_reg_is_rd = inst_beq | inst_bne | inst_st_w ; 

assign ds_src1_is_pc    = inst_jirl | inst_bl | inst_pcaddu12i;

assign ds_src2_is_ds_imm   = inst_slli_w |
                       inst_srli_w |
                       inst_srai_w |
                       inst_addi_w |
                       inst_ld_w   |
                       inst_st_w   |
                       inst_lu12i_w|
                       inst_jirl   |
                       inst_bl     |
                       inst_pcaddu12i|
                       inst_slti   |
                       inst_sltui  |
                       inst_andi   |
                       inst_ori    |
                       inst_xori;

wire [6:0] div_or_mul;
assign div_or_mul    = {inst_mul_w, 
                        inst_mulh_w, 
                        inst_mulh_wu,
                        inst_div_w,
                        inst_mod_w,
                        inst_div_wu,
                        inst_mod_wu};

assign ds_res_from_mem  = inst_ld_w;
assign dst_is_r1     = inst_bl;
assign ds_gr_we         = ~inst_st_w & ~inst_beq & ~inst_bne & ~inst_b;
assign ds_mem_we        = inst_st_w;
assign ds_dest          = dst_is_r1 ? 5'd1 : rd;

assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd :rk;
regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (ds_rf_we    ),
    .waddr  (ds_rf_waddr ),
    .wdata  (ds_rf_wdata )
    );

//assign ds_rj_value  = rf_rdata1;
//assign ds_rkd_value = rf_rdata2;

assign rj_eq_rd = (ds_rj_value == ds_rkd_value);
assign br_taken = (   inst_beq  &&  rj_eq_rd
                   || inst_bne  && !rj_eq_rd
                   || inst_jirl
                   || inst_bl
                   || inst_b
                  ) && ds_valid;
assign br_target = (inst_beq || inst_bne || inst_bl || inst_b) ? (ds_pc + br_offs) :
                                                   /*inst_jirl*/ (ds_rj_value + jirl_offs);
// deal with input and output
assign br_bus                    = {br_taken_cancle,br_taken,br_target};
assign br_taken_cancle           =br_taken && ds_ready_go;
assign {ds_inst,ds_pc}           = fs_to_ds_bus_r;

assign {ds_rf_we,ds_rf_waddr,ds_rf_wdata,ws_valid} = rf_bus;
assign ds_to_es_bus              = {div_or_mul,ds_alu_op,ds_src1_is_pc,ds_pc,ds_rj_value,
ds_src2_is_ds_imm,ds_imm,ds_rkd_value,ds_gr_we,ds_dest,ds_res_from_mem,ds_mem_we};

assign ds_ready_go       = !(hazard && es_res_from_mem && es_valid);//即译码级的指令真相关�?
                                                                    //当前位于执行级的 ld.w 指令
assign ds_allowin      = !ds_valid || ds_ready_go && es_allowin;
assign ds_to_es_valid   = ds_valid && ds_ready_go;
always @(posedge clk) begin
    if (reset) begin
        ds_valid <=1'b0;
    end
    else if(br_taken_cancle) begin
        ds_valid <=1'b0;
    end
    else if (ds_allowin) begin
        ds_valid <= fs_to_ds_valid;
    end
end

always @(posedge clk) begin
    if (fs_to_ds_valid && ds_allowin) begin
        fs_to_ds_bus_r <= fs_to_ds_bus;
    end
end
//hazard
assign ms_valid = in_ms_valid;
assign es_valid = in_es_valid;

assign {es_res_from_mem,es_gr_we,es_dest,es_alu_result} = es_to_ms_bus[70:32];
assign {ms_gr_we,ms_dest,ms_alu_result} = ms_to_ws_bus[69:32];

assign src1_hazard = (rf_raddr1 == 5'b0) ? 1'b0:
                     (rf_raddr1 == es_dest && es_gr_we && es_valid) ? 1'b1:
                     (rf_raddr1 == ms_dest && ms_gr_we && ms_valid) ? 1'b1:
                     (rf_raddr1 == ds_rf_waddr && ds_rf_we && ws_valid) ? 1'b1 : 1'b0;
assign src2_hazard = (rf_raddr2 == 5'b0) ? 1'b0:
                     (rf_raddr2 == es_dest && es_gr_we && es_valid) ? 1'b1:
                     (rf_raddr2 == ms_dest && ms_gr_we && ms_valid) ? 1'b1:
                     (rf_raddr2 == ds_rf_waddr && ds_rf_we && ws_valid) ? 1'b1 : 1'b0;

assign either_hazard = src1_hazard || src2_hazard;
assign both_src = inst_add_w || inst_sub_w || inst_slt || inst_nor || inst_and || inst_or || inst_xor || inst_beq || inst_bne || inst_sltu;
assign src_rj = inst_slli_w || inst_srli_w || inst_srai_w || inst_addi_w || inst_jirl ;
assign src_rd = inst_st_w;

assign hazard      = (both_src && either_hazard) ? 1'b1:
                     (src_rj     && src1_hazard) ?   1'b1: 
                     (src_rd     && src2_hazard) ?   1'b1: 1'b0;

//data forward
assign ds_rj_value  = (rf_raddr1 == es_dest && es_gr_we && !es_res_from_mem && es_valid)? es_alu_result :
                      (rf_raddr1 == ms_dest && ms_gr_we && ms_valid)? ms_alu_result:
                      (rf_raddr1 == ds_rf_waddr && ds_rf_we && ws_valid) ? ds_rf_wdata : rf_rdata1;

assign ds_rkd_value = (rf_raddr2 == es_dest && es_gr_we && !es_res_from_mem && es_valid)? es_alu_result :
                      (rf_raddr2 == ms_dest && ms_gr_we && ms_valid)? ms_alu_result:
                      (rf_raddr2 == ds_rf_waddr && ds_rf_we && ws_valid) ? ds_rf_wdata : rf_rdata2;


endmodule

