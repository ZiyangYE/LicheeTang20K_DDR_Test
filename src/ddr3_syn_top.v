`timescale 1ps /1ps

module ddr3_syn_top(
  clk,

  ddr_addr,
  ddr_bank,
  ddr_cs,
  ddr_ras,
  ddr_cas,
  ddr_we,
  ddr_ck,
  ddr_ck_n,
  ddr_cke,
  ddr_odt,
  ddr_reset_n,
  ddr_dm,
  ddr_dq,
  ddr_dqs,
  ddr_dqs_n,

  uart_txp
);

input                       clk;

output [14-1:0]             ddr_addr;       //ROW_WIDTH=14
output [3-1:0]              ddr_bank;       //BANK_WIDTH=3
output                      ddr_cs;
output                      ddr_ras;
output                      ddr_cas;
output                      ddr_we;
output                      ddr_ck;
output                      ddr_ck_n;
output                      ddr_cke;
output                      ddr_odt;
output                      ddr_reset_n;
output [2-1:0]              ddr_dm;         //DM_WIDTH=2
inout [16-1:0]              ddr_dq;         //DQ_WIDTH=16
inout [2-1:0]               ddr_dqs;        //DQS_WIDTH=2
inout [2-1:0]               ddr_dqs_n;      //DQS_WIDTH=2

output                      uart_txp;

wire clk80;
wire clk80_n;

wire rst_n;

wire [27-1:0]             app_addr;        //ADDR_WIDTH=27

wire                      app_rd_valid;
wire                      app_rd_rdy;
wire [16-1:0]             app_rd_payload;       //DATA_WIDTH=16

wire                      app_wr_valid;
wire                      app_wr_rdy;
wire [16-1:0]             app_wr_payload;       //DATA_WIDTH=16

wire                      init_fin;

tester test(
  .clk(clk80),
  .rst_n(rst_n),

  .app_addr(app_addr),

  .app_rd_valid(app_rd_valid),
  .app_rd_rdy(app_rd_rdy),
  .app_rd_payload(app_rd_payload),

  .app_wr_valid(app_wr_valid),
  .app_wr_rdy(app_wr_rdy),
  .app_wr_payload(app_wr_payload),

  .init_fin(init_fin),

  .txp(uart_txp)
);

Gowin_rPLL pll(
  .clkout(clk80), //output clk 80MHz
  .clkoutp(clk80_n), //output inverted clk 80MHz
  .clkin(clk) //input clk
);

slowDDR3 DDR(
  .phyIO_address(ddr_addr),
  .phyIO_bank(ddr_bank),
  .phyIO_cs(ddr_cs),
  .phyIO_cas(ddr_cas),
  .phyIO_ras(ddr_ras),
  .phyIO_we(ddr_we),
  .phyIO_clk_p(ddr_ck),
  .phyIO_clk_n(ddr_ck_n),
  .phyIO_cke(ddr_cke),
  .phyIO_odt(ddr_odt),
  .phyIO_rst_n(ddr_reset_n),
  .phyIO_dm(ddr_dm),
  .phyIO_dq(ddr_dq),
  .phyIO_dqs_p(ddr_dqs),
  .phyIO_dqs_n(ddr_dqs_n),

  .sysIO_dataRd_valid(app_rd_valid),
  .sysIO_dataRd_ready(app_rd_rdy),
  .sysIO_dataRd_payload(app_rd_payload),
  .sysIO_dataWr_valid(app_wr_valid),
  .sysIO_dataWr_ready(app_wr_rdy),
  .sysIO_dataWr_payload(app_wr_payload),
  .sysIO_address(app_addr),

  .sysIO_initFin(init_fin),
  .inv_clk(clk80_n),
  .clk(clk80),
  .resetn(rst_n)
);


endmodule







