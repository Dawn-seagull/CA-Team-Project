module EXE_stage(
    input               clk,
    input               reset,
    // allowin
    input               ms_allowin,
    output              es_allowin,
    // input from ID stage
    input               ds_to_es_valid,
    input   [164:0]     ds_to_es_bus,//接收ID阶段传到EXE阶段的数�?
    // output for MEM stage
    output              es_to_ms_valid,
    output  [75:0]      es_to_ms_bus,//传�?�由EXE阶段传到MEM阶段的数�?
    // data sram interface
    output wire         data_sram_en,//数据RAM读使能信�?
    output wire [3:0]   data_sram_we,//数据RAM写使能信�?
    output wire [31:0]  data_sram_addr,//数据RAM读地�?
    output wire [31:0]  data_sram_wdata,//数据RAM写地�?
    // hazard
    output              in_es_valid
);

wire [11:0] es_alu_op;
wire        es_src1_is_es_pc;
wire        es_src2_is_es_imm;
wire        es_gr_we;
wire        es_res_from_mem;
wire        es_mem_we;
wire [31:0] es_pc;
wire [4: 0] es_dest;
wire [31:0] es_rj_value;
wire [31:0] es_rkd_value;
wire [31:0] es_imm;
wire [31:0] es_final_result;
wire [63:0] signed_prod;
wire [63:0] unsigned_prod;
wire [6:0]  exe_div_or_mul;

wire [4:0] ld_type;
wire [2:0] st_type;
wire [3:0] final_mem_we;
wire inst_st_b;
wire inst_st_h;

wire [31:0] alu_src1   ;
wire [31:0] alu_src2   ;
wire [31:0] es_alu_result ;
wire [31:0] st_data;
reg [164:0] ds_to_es_bus_r;

reg        s_axis_divisor_tvalid;
wire       s_axis_divisor_tready;
wire [31:0] s_axis_divisor_tdata;
reg        s_axis_dividend_tvalid;
wire       s_axis_dividend_tready;
wire [31:0] s_axis_dividend_tdata;
wire       m_axis_dout_tvalid;
wire [63:0] m_axis_dout_tdata;

reg        us_axis_divisor_tvalid;
wire       us_axis_divisor_tready;
wire [31:0] us_axis_divisor_tdata;
reg        us_axis_dividend_tvalid;
wire       us_axis_dividend_tready;
wire [31:0] us_axis_dividend_tdata;
wire       um_axis_dout_tvalid;
wire [63:0] um_axis_dout_tdata;  

assign alu_src1 = es_src1_is_es_pc  ? es_pc[31:0] : es_rj_value;
assign alu_src2 = es_src2_is_es_imm ? es_imm : es_rkd_value;

assign unsigned_prod    = alu_src1 * alu_src2;
assign signed_prod      = $signed(alu_src1) * $signed(alu_src2);

alu u_alu(
    .alu_op     (es_alu_op    ),
    .alu_src1   (alu_src1  ),
    .alu_src2   (alu_src2  ),
    .alu_result (es_alu_result)
    );
    
mydiv mydiv(
    .aclk   (clk),
    .s_axis_divisor_tvalid  (s_axis_divisor_tvalid),
    .s_axis_divisor_tready  (s_axis_divisor_tready),
    .s_axis_divisor_tdata   (alu_src2),
    .s_axis_dividend_tvalid (s_axis_dividend_tvalid),
    .s_axis_dividend_tready (s_axis_dividend_tready),
    .s_axis_dividend_tdata  (alu_src1),
    .m_axis_dout_tvalid (m_axis_dout_tvalid),
    .m_axis_dout_tdata  (m_axis_dout_tdata)
);

mydiv_u mydiv_u(
    .aclk   (clk),
    .s_axis_divisor_tvalid  (us_axis_divisor_tvalid),
    .s_axis_divisor_tready  (us_axis_divisor_tready),
    .s_axis_divisor_tdata   (alu_src2),
    .s_axis_dividend_tvalid (us_axis_dividend_tvalid),
    .s_axis_dividend_tready (us_axis_dividend_tready),
    .s_axis_dividend_tdata  (alu_src1),
    .m_axis_dout_tvalid (um_axis_dout_tvalid),
    .m_axis_dout_tdata  (um_axis_dout_tdata)
);

assign es_final_result   = (exe_div_or_mul[6]) ? signed_prod[31:0]
                    : (exe_div_or_mul[5]) ? signed_prod[63:32]
                    : (exe_div_or_mul[4]) ? unsigned_prod[63:32]
                    : (exe_div_or_mul[3]) ? m_axis_dout_tdata[63:32]
                    : (exe_div_or_mul[2]) ? m_axis_dout_tdata[31:0]
                    : (exe_div_or_mul[1]) ? um_axis_dout_tdata[63:32]
                    : (exe_div_or_mul[0]) ? um_axis_dout_tdata[31:0]
                    : es_alu_result;

reg     es_valid;
wire    es_ready_go;

assign in_es_valid    =es_valid;
assign es_ready_go    = (exe_div_or_mul[3] | exe_div_or_mul[2]) ? m_axis_dout_tvalid
                      : (exe_div_or_mul[1] | exe_div_or_mul[0]) ? um_axis_dout_tvalid
                      : 1'b1;
assign es_allowin     = !es_valid || es_ready_go && ms_allowin;
assign es_to_ms_valid =  es_valid && es_ready_go;

always @(posedge clk) begin
    if (reset) begin
        es_valid <= 1'b0;
    end
    else if (es_allowin) begin
        es_valid <= ds_to_es_valid;
    end
    if (ds_to_es_valid && es_allowin) begin
        ds_to_es_bus_r <= ds_to_es_bus;
    end
end

reg last;
always @(posedge clk) begin
    if (reset) begin
        s_axis_divisor_tvalid <= 1'b0;
        s_axis_dividend_tvalid <= 1'b0;
        us_axis_divisor_tvalid <= 1'b0;
        us_axis_dividend_tvalid <= 1'b0;
        last <= 1'b0;
    end
    else if(s_axis_divisor_tready & s_axis_dividend_tready )begin //s_axis_divisor_tready & s_axis_dividend_tready
        s_axis_divisor_tvalid <= 1'b0;
        s_axis_dividend_tvalid <= 1'b0;
    end
    else if(us_axis_divisor_tready & us_axis_dividend_tready  )begin //s_axis_divisor_tready & s_axis_dividend_tready
        us_axis_divisor_tvalid <= 1'b0;
        us_axis_dividend_tvalid <= 1'b0;
    end    
    else if ((exe_div_or_mul[3] | exe_div_or_mul[2]) & ~last) begin
        s_axis_divisor_tvalid <= 1'b1;
        s_axis_dividend_tvalid <= 1'b1;
        last <= 1'b1;
    end
    else if ((exe_div_or_mul[1] | exe_div_or_mul[0]) & ~last) begin
        us_axis_divisor_tvalid <= 1'b1;
        us_axis_dividend_tvalid <= 1'b1;
        last <= 1'b1;
    end
    if(m_axis_dout_tvalid)
    last <= 1'b0;
    else if(um_axis_dout_tvalid)
    last <= 1'b0;
   
end
//store_data
assign {inst_st_b,inst_st_h,inst_st_w}= st_type;
assign st_data = inst_st_b ? {4{es_rkd_value[ 7:0]}} :
                 inst_st_h ? {2{es_rkd_value[15:0]}} :
                             es_rkd_value[31:0];

assign final_mem_we = inst_st_w ?  4'b1111 : 
                      inst_st_h ? (4'b0011 << es_alu_result[1:0]) :
                      inst_st_b ? (4'b0001 << es_alu_result[1:0]) : 4'b0000;


// deal with input and output
assign {st_type,ld_type,exe_div_or_mul,es_alu_op,es_src1_is_es_pc,es_pc,es_rj_value,es_src2_is_es_imm,es_imm,es_rkd_value,es_gr_we,es_dest,es_res_from_mem,es_mem_we}=ds_to_es_bus_r;
assign es_to_ms_bus = {ld_type,es_res_from_mem,es_gr_we,es_dest,es_final_result,es_pc};

assign data_sram_we    = (es_mem_we && es_valid)? final_mem_we : 4'h0;
assign data_sram_en    = 1'h1;
assign data_sram_addr  = es_alu_result;
assign data_sram_wdata = st_data;


endmodule