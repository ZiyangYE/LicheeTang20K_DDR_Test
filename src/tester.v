module tester(
    clk,
    rst_n,

    app_addr,

    app_rd_valid,
    app_rd_rdy,
    app_rd_payload,
    app_wr_valid,
    app_wr_rdy,
    app_wr_payload,

    init_fin,

    txp
  );

input clk;
output reg rst_n;

output [27-1:0] app_addr;

input app_rd_valid;
output reg app_rd_rdy;
input [16-1:0] app_rd_payload;
output reg app_wr_valid;
input app_wr_rdy;
output reg [16-1:0] app_wr_payload;

input init_fin;

output txp;


//Reset Controll -------------------------------------------
reg [47:0] time_counter;//every 125s, perform a reset.

always@(posedge clk) begin
  time_counter<=time_counter+1;

  if(time_counter>48'd10_125_000_000-48'd1)begin
    rst_n<=1'b0;
    time_counter<=48'd0;
  end
  else begin
    rst_n<=1'b1;
  end
end
//Reset Controll -------------------------------------------

//Work Controll -----------------------------------------
localparam WORK_WAIT_INIT = 3'h0;
localparam WORK_DETECT_SIZE = 3'h1;
localparam WORK_FILL = 3'h2;
localparam WORK_CHECK = 3'h3;
localparam WORK_INV_FILL = 3'h4;
localparam WORK_INV_CHECK = 3'h5;

localparam WORK_CHECK_FAIL = 3'h6;
localparam WORK_FIN = 3'h7;


localparam DETECT_SIZE_WR0 = 2'h0;
localparam DETECT_SIZE_WR1 = 2'h1;
localparam DETECT_SIZE_RP0 = 2'h2;
localparam DETECT_SIZE_RP1 = 2'h3;


localparam FILL_RST = 2'h0;
localparam FILL_RNG = 2'h1;
localparam FILL_WRT = 2'h2;
localparam FILL_CMD = 2'h3;

localparam CHECK_RST = 2'h0;
localparam CHECK_CMD = 2'h1;
localparam CHECK_DAT = 2'h2;
localparam CHECK_RNG = 2'h3;

reg [2:0] work_state;
reg [1:0] detect_state;
reg [1:0] fill_state;
reg [1:0] check_state;

localparam WR_CMD = 3'h0;
localparam RD_CMD = 3'h1;

reg [7:0] work_counter;

localparam DDR_SIZE_1G = 1'b0;
localparam DDR_SIZE_2G = 1'b1;
reg ddr_size;


reg [26:0] int_app_addr;

assign app_addr = int_app_addr;

//rng part ------------------------------------------------
reg[127:0] rng;
reg[127:0] rng_inv;

reg[127:0] rng_i;
reg[127:0] rng_init_pattern;
reg[6:0] rng_cnt;
reg rng_rst;
reg rng_tick;

always@(posedge clk)begin
  rng<=rng_i;
  rng_inv<=rng_i;

  if(rng_tick)begin
    rng_i<={rng_i[126:0],rng_i[68]^rng_i[67]^rng_i[66]^rng_i[63]};
    rng_cnt<=rng_cnt+7'd1;
  end
  
  if(rng_rst)begin
    rng_i<=rng_init_pattern;
    rng_cnt<=7'd0;
  end
end
//rng part ------------------------------------------------

reg[5:0] wr_cnt;

reg [127:0] read_data;
reg [2:0] read_data_pos;

reg error_bit;

always@(posedge clk or negedge rst_n)begin
  
  if(rst_n==1'b0)begin
    //init counter
    work_counter<=8'd0;
    wr_cnt<=6'd0;

    //init state
    work_state<=WORK_WAIT_INIT;
    detect_state<=DETECT_SIZE_WR0;
    fill_state<=FILL_RST;
    check_state<=CHECK_RST;

    //init interface
    app_rd_rdy<=1'b0;
    app_wr_valid<=1'b0;

    //init regs
    error_bit<=1'b0;
  end else begin
    case(work_state)
      //wait init finish--------------------------------------------
      WORK_WAIT_INIT:begin
        if(init_fin==1'b1)work_state<=WORK_DETECT_SIZE;
      end

      //detect ddr size---------------------------------------------
      WORK_DETECT_SIZE:begin
        app_rd_rdy<=1'b0;
        app_wr_valid<=1'b0;

        case(detect_state)
          DETECT_SIZE_WR0:begin
            int_app_addr<=27'h000_0000;
            app_wr_payload<=16'h5A01;

            if(work_counter==8'd0)
              app_wr_valid<=1'b1;
            else
              app_wr_valid<=1'b0;

            if(app_wr_rdy==1'b1)
              work_counter<=work_counter+8'd1;

            if(work_counter==8'd7 && app_wr_rdy==1'b1)begin
              //exit
              detect_state<=DETECT_SIZE_WR1;
              work_counter<=8'd0;
            end     
          end   
          DETECT_SIZE_WR1:begin
            int_app_addr<=27'h400_0000;
            app_wr_payload<=16'h5329;

            if(work_counter==8'd0)
              app_wr_valid<=1'b1;
            else
              app_wr_valid<=1'b0;

            if(app_wr_rdy==1'b1)
              work_counter<=work_counter+8'd1;

            if(work_counter==8'd7 && app_wr_rdy==1'b1)begin
              //exit
              detect_state<=DETECT_SIZE_RP0;
              work_counter<=8'd0;
            end     
          end
          DETECT_SIZE_RP0:begin
            int_app_addr<=27'h000_0000;

            if(work_counter==8'd0)
              app_rd_rdy<=1'b1;
            else
              app_rd_rdy<=1'b0;

            if(app_rd_valid==1'b1)
              work_counter<=work_counter+8'd1;

            if(work_counter==8'd7 && app_rd_valid==1'b1)begin
              //exit
              detect_state<=DETECT_SIZE_RP1;
              work_counter<=8'd0;
            end
          end
          DETECT_SIZE_RP1:begin
              //exit
              work_state<=WORK_FILL;

              //exit if error
              if(
                app_rd_payload!=16'h5A01
              &&
                app_rd_payload!=16'h5329
              )begin
                work_state<=WORK_FIN;
                error_bit<=1'b1;
              end

              //detect size
              ddr_size<=app_rd_payload==16'h5A01 ? DDR_SIZE_2G : DDR_SIZE_1G;
          end
        endcase
      end

      //fill data----------------------------------------------------
      WORK_FILL:begin 
        //fill the data, then perform the write cmd

        rng_rst<=1'b0;
        rng_tick<=1'b0;
        rng_init_pattern<=128'h0123_4567_890A_BCDE_FEDC_BA98_7654_3210;

        app_wr_valid<=1'b0;
        
        case(fill_state)
          FILL_RST:begin
            rng_rst<=1'b1;

            int_app_addr<=27'h0;

            //exit
            fill_state<=FILL_RNG;
          end

          FILL_RNG:begin
            rng_tick<=1'b1;

            //exit
            if(rng_cnt==7'd127)begin
              fill_state<=FILL_WRT;
            end
          end

          FILL_WRT:begin
            if(wr_cnt==6'd0)begin
              app_wr_valid<=1'b1;
              app_wr_payload<=rng[(0)*16 +: 16];
            end else
              app_wr_valid<=1'b0;

            if(app_wr_rdy)begin
              wr_cnt<=wr_cnt+6'd1;
              app_wr_payload<=rng[(wr_cnt+1)*16 +: 16];

              //exit
              if(wr_cnt==6'd7)begin
                int_app_addr<=int_app_addr+27'd8;
                fill_state<=FILL_RNG;
                wr_cnt<=6'd0;

                if(ddr_size==DDR_SIZE_1G)begin
                  if({1'b0,int_app_addr}==28'h400_0000-28'd8)begin
                    work_state<=WORK_CHECK;
                    fill_state<=FILL_RST;
                  end
                end else begin
                  if({1'b0,int_app_addr}==28'h800_0000-28'd8)begin
                    work_state<=WORK_CHECK;
                    fill_state<=FILL_RST;
                  end
                end
              end
                
            end
          end
        endcase
      end

      //check data----------------------------------------------------
      WORK_CHECK:begin
        //perform the read cmd, then read the data and compare with the rng
        rng_rst<=1'b0;
        rng_tick<=1'b0;
        rng_init_pattern<=128'h0123_4567_890A_BCDE_FEDC_BA98_7654_3210;

        app_rd_rdy<=1'b0;

        case(check_state)
          CHECK_RST:begin
            rng_rst<=1'b1;

            //set adr to the prev pos, so after add 8, it will be 0
            int_app_addr<=27'h0;

            //exit
            check_state<=CHECK_DAT;
          end

          CHECK_DAT:begin
            rng_tick<=1'b1;

            if(read_data_pos==3'd0)begin
              app_rd_rdy<=1'b1;
            end else
              app_rd_rdy<=1'b0;

            if(app_rd_valid)begin
              read_data[read_data_pos*16+:16]<=app_rd_payload;

              read_data_pos<=read_data_pos+3'd1;
              if(read_data_pos==3'd7)begin
                check_state<=CHECK_RNG;
              end
            end
          end

          CHECK_RNG:begin
            rng_tick<=1'b1;

            if(rng_cnt==7'd2)begin
              if(read_data!=rng)begin
                work_state<=WORK_CHECK_FAIL;
              end

              int_app_addr<=int_app_addr+27'd8;

              //exit
              check_state<=CHECK_DAT;

              if(ddr_size==DDR_SIZE_1G)begin
                if({1'b0,int_app_addr}==28'h400_0000-28'd8)begin
                  work_state<=WORK_INV_FILL;
                  check_state<=CHECK_RST;
                end
              end
              else begin
                if({1'b0,int_app_addr}==28'h800_0000-28'd8)begin
                  work_state<=WORK_INV_FILL;
                  check_state<=CHECK_RST;
                end
              end
            end
          end
        endcase
      end

      //fill inv data----------------------------------------------------
      WORK_INV_FILL:begin 
        //fill the data, then perform the write cmd

        rng_rst<=1'b0;
        rng_tick<=1'b0;
        rng_init_pattern<=128'h0123_4567_890A_BCDE_FEDC_BA98_7654_3210;

        app_wr_valid<=1'b0;
        
        case(fill_state)
          FILL_RST:begin
            rng_rst<=1'b1;

            int_app_addr<=27'h0;

            //exit
            fill_state<=FILL_RNG;
          end

          FILL_RNG:begin
            rng_tick<=1'b1;

            //exit
            if(rng_cnt==7'd127)begin
              fill_state<=FILL_WRT;
            end
          end

          FILL_WRT:begin
            if(wr_cnt==6'd0)begin
              app_wr_valid<=1'b1;
              app_wr_payload<=rng_inv[(0)*16 +: 16];
            end else
              app_wr_valid<=1'b0;

            if(app_wr_rdy)begin
              wr_cnt<=wr_cnt+6'd1;
              app_wr_payload<=rng_inv[(wr_cnt+1)*16 +: 16];

              //exit
              if(wr_cnt==6'd7)begin
                int_app_addr<=int_app_addr+27'd8;
                fill_state<=FILL_RNG;
                wr_cnt<=6'd0;

                if(ddr_size==DDR_SIZE_1G)begin
                  if({1'b0,int_app_addr}==28'h400_0000-28'd8)begin
                    work_state<=WORK_INV_CHECK;
                    fill_state<=FILL_RST;
                  end
                end else begin
                  if({1'b0,int_app_addr}==28'h800_0000-28'd8)begin
                    work_state<=WORK_INV_CHECK;
                    fill_state<=FILL_RST;
                  end
                end
              end
                
            end
          end
        endcase
      end

      //check inv data----------------------------------------------------
      WORK_INV_CHECK:begin
        //perform the read cmd, then read the data and compare with the rng
        rng_rst<=1'b0;
        rng_tick<=1'b0;
        rng_init_pattern<=128'h0123_4567_890A_BCDE_FEDC_BA98_7654_3210;

        app_rd_rdy<=1'b0;

        case(check_state)
          CHECK_RST:begin
            rng_rst<=1'b1;

            //set adr to the prev pos, so after add 8, it will be 0
            int_app_addr<=27'h0;

            //exit
            check_state<=CHECK_DAT;
          end

          CHECK_DAT:begin
            rng_tick<=1'b1;

            if(read_data_pos==3'd0)begin
              app_rd_rdy<=1'b1;
            end else
              app_rd_rdy<=1'b0;

            if(app_rd_valid)begin
              read_data[read_data_pos*16+:16]<=app_rd_payload;

              read_data_pos<=read_data_pos+3'd1;
              if(read_data_pos==3'd7)begin
                check_state<=CHECK_RNG;
              end
            end
          end

          CHECK_RNG:begin
            rng_tick<=1'b1;

            if(rng_cnt==7'd2)begin
              if(read_data!=rng_inv)begin
                work_state<=WORK_CHECK_FAIL;
              end

              int_app_addr<=int_app_addr+27'd8;

              //exit
              check_state<=CHECK_DAT;

              if(ddr_size==DDR_SIZE_1G)begin
                if({1'b0,int_app_addr}==28'h400_0000-28'd8)begin
                  work_state<=WORK_FIN;
                  check_state<=CHECK_RST;
                end
              end
              else begin
                if({1'b0,int_app_addr}==28'h800_0000-28'd8)begin
                  work_state<=WORK_FIN;
                  check_state<=CHECK_RST;
                end
              end
            end
          end
        endcase
      end


      //check error----------------------------------------------------
      WORK_CHECK_FAIL:begin

      end
      //error-------------------------------------------------------
      WORK_FIN:begin
        
      end
    endcase

  end
end


//Work Controll -----------------------------------------


//Print Controll -------------------------------------------
`include "print.v"
defparam tx.uart_freq=115200;
defparam tx.clk_freq=80_000_000;
assign print_clk = clk;
assign txp = uart_txp;

reg[2:0] state_0;
reg[2:0] state_1;
reg[2:0] state_old;
wire[2:0] state_new = state_1;


always@(posedge clk)begin
  state_1<=state_0;
  state_0<=work_state;

  if(state_0==state_1)begin//stable value
    if(print_state==PRINT_IDLE_STATE)state_old<=state_new;

    if(state_old!=state_new)begin//state changes
      if(state_old==WORK_WAIT_INIT)`print("Init Complete\n",STR);
      
      if(state_new==WORK_FILL)
        if(ddr_size==DDR_SIZE_1G)`print("DDR Size: 1G\nBegin to Fill\n",STR);
        else `print("DDR Size: 2G\nBegin to Fill Stage 1\n",STR);
      
      if(state_new==WORK_CHECK)`print("Fill Stage 1 Finished\nBegin to Check Stage 1\n",STR);

      if(state_new==WORK_INV_FILL)`print("Check Stage 1 Finished without Mismatch\nBegin to Fill Stage 2\n",STR);

      if(state_new==WORK_INV_CHECK)`print("Fill Stage 2 Finished\nBegin to Check Stage 2\n",STR);

      if(state_new==WORK_CHECK_FAIL)`print("Check Failed. Mismatch Occured\n",STR);

      if(state_new==WORK_FIN)begin
        if(error_bit)
          `print("Error Occured\n\n",STR);
        else
          `print("Check Stage 2 Finished without Mismatch\nTest Finished\n\n",STR);
      end      
    end
  end

  if(rst_n==1'b0)`print("Perform Reset\nAuto Reset Every 125s\n",STR);
end
//Print Controll -------------------------------------------

endmodule
