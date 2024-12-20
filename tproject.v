
module hms_cnt(
    output reg [5:0] o_hms_cnt,
    output reg       o_max_hit,
    input      [5:0] i_max_cnt,
    input            i_direct,
    input            i_clk,
    input            i_rstn
);
    always @(posedge i_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            if(!i_direct) begin
                o_hms_cnt <= 6'd0;
                o_max_hit <= 1'b0;
            end else begin
                o_hms_cnt <= 6'd0;
                o_max_hit <= 1'b0;
            end
        end else begin
            if(!i_direct) begin
               if(o_hms_cnt >= i_max_cnt) begin
                   o_hms_cnt <= 6'd0;
                   o_max_hit <= 1'b1;
               end else begin
                   o_hms_cnt <= o_hms_cnt + 1;
                   o_max_hit <= 1'b0;
               end
            end else begin
                if(o_hms_cnt == 0) begin
                    o_hms_cnt <= i_max_cnt;
                    o_max_hit <= 1'b1;
                end else begin
                    o_hms_cnt <= o_hms_cnt - 1;
                    o_max_hit <= 1'b0;
                end
            end
        end
    end
endmodule

module dec_to_seg(
    output reg [6:0] o_seg,
    input      [3:0] i_num
);

    always @(*) begin
        case(i_num) 
            4'b0000: o_seg = 7'b1111110;
            4'b0001: o_seg = 7'b0110000;
            4'b0010: o_seg = 7'b1101101;
            4'b0011: o_seg = 7'b1111001;
            4'b0100: o_seg = 7'b0110011;
            4'b0101: o_seg = 7'b1011011;
            4'b0110: o_seg = 7'b1011111;
            4'b0111: o_seg = 7'b1110000;
            4'b1000: o_seg = 7'b1111111;
            4'b1001: o_seg = 7'b1110011;
        endcase
    end
endmodule

module cnt_param #(
    parameter RANGE = 50
)(
    output reg [$clog2(RANGE)-1:0] o_cnt,
    input                        i_clk,
    input                       i_rstn,
    input                     i_direct
);

    always @(posedge i_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            if(!i_direct) begin
                o_cnt <= {$clog2(RANGE){1'b1}};
            end else begin
                o_cnt <= RANGE;
            end
        end else begin
            if(!i_direct) begin
                if(o_cnt == RANGE-1) begin
                    o_cnt <= 0;
                end else begin
                    o_cnt <= o_cnt + 1;
                end
            end else begin
                if(o_cnt == 0) begin
                    o_cnt <= RANGE-1;
                end else begin
                    o_cnt <= o_cnt - 1;
                end
            end
        end
    end

endmodule

module nco(
    output reg   o_clk,
    input [31:0] i_num,
    input        i_clk,
    input        i_rstn
);

    reg [31:0] cnt;
    always @(posedge i_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            cnt <= {32{1'b1}};
            o_clk <= 0;
        end else begin
            if(cnt >= i_num/2 -1) begin
                cnt <= 0;
                o_clk <= ~o_clk;
            end else begin
                cnt <= cnt + 1;
                o_clk <= o_clk;
            end
        end
    end
endmodule

module num_split #(
    parameter RANGE = 60
)(
    output [3:0] o_digit_l,
    output [3:0] o_digit_r,
    input [$clog2(RANGE)-1:0] i_num
);

    assign o_digit_l = i_num/10;
    assign o_digit_r = i_num%10;

endmodule

module led_ctrl #(
    parameter NCO_NUM_SPEED = 50
)(
    output reg [6:0] o_seg,
    output reg       o_seg_dp,
    output reg [5:0] o_seg_enb,
    input      [6*7-1:0] i_six_seg,
    input      [5:0]     i_six_seg_dp,
    input                i_mode,
    input                i_position,
    input                i_clk,
    input                i_rstn
);

    wire        clk_disp_speed;
    nco u_nco(
        .o_clk (clk_disp_speed),
        .i_num (NCO_NUM_SPEED),
        .i_clk (i_clk),
        .i_rstn (i_rstn));

    wire [2:0]  cnt_seg_enb;
    cnt_param #(
        .RANGE (6))
    u_cnt_param(
        .o_cnt (cnt_seg_enb),
        .i_direct (1'b0),
        .i_clk (clk_disp_speed),
        .i_rstn (i_rstn));


    always @(*) begin
        case(cnt_seg_enb) 
            3'd0: {o_seg_enb, o_seg, o_seg_dp} = {6'b111110, i_six_seg[0*7+6:0*7], i_six_seg_dp[0]};
            3'd1: {o_seg_enb, o_seg, o_seg_dp} = {6'b111101, i_six_seg[1*7+6:1*7], i_six_seg_dp[1]};
            3'd2: {o_seg_enb, o_seg, o_seg_dp} = {6'b111011, i_six_seg[2*7+6:2*7], i_six_seg_dp[2]};
            3'd3: {o_seg_enb, o_seg, o_seg_dp} = {6'b110111, i_six_seg[3*7+6:3*7], i_six_seg_dp[3]};
            3'd4: {o_seg_enb, o_seg, o_seg_dp} = {6'b101111, i_six_seg[4*7+6:4*7], i_six_seg_dp[4]};
            3'd5: {o_seg_enb, o_seg, o_seg_dp} = {6'b011111, i_six_seg[5*7+6:5*7], i_six_seg_dp[5]};
            default: {o_seg_enb, o_seg, o_seg_dp} = {6'b000000, 7'b1111111, 1'b1};
        endcase
    end

endmodule

module blink(
    output reg [41:0] o_seg_blk,

    input       [6:0] i_seg_l_s,
    input       [6:0] i_seg_r_s,
    input       [6:0] i_seg_l_m,

    input       [6:0] i_seg_r_m,
    input       [6:0] i_seg_l_h,
    input       [6:0] i_seg_r_h,

    input       [1:0] i_mode_b,
    input       [1:0] i_position_b,
    input             i_state_b,

    input             i_clk,
    input             i_rstn    
);
    wire          clk_blink;
    nco u_nco_clk_slow(
        .o_clk (clk_blink),
        .i_num (40000000),
        .i_clk (i_clk       ),
        .i_rstn (i_rstn     ));

    wire cnt_blink;
    cnt_param #(
        .RANGE (200000000))
    u_cnt_param_blk(
        .o_cnt (cnt_blink),
        .i_clk (clk_blink),
        .i_rstn (i_rstn),
        .i_direct (1'b0));


    always @(*) begin
        if(i_mode_b >= 1 && i_mode_b <= 2) begin
            case(i_position_b)
                2'b00: begin
                    if( (cnt_blink % 2) == 0) begin
                        o_seg_blk = {i_seg_l_h, i_seg_r_h, i_seg_l_m, i_seg_r_m, i_seg_l_s, i_seg_r_s};
                    end else begin
                        o_seg_blk = {i_seg_l_h, i_seg_r_h, i_seg_l_m, i_seg_r_m, 7'b0000000, 7'b0000000};
                    end
                end
                2'b01: begin
                    if( (cnt_blink % 2) == 0) begin
                        o_seg_blk = {i_seg_l_h, i_seg_r_h, i_seg_l_m, i_seg_r_m, i_seg_l_s, i_seg_r_s};
                    end else begin
                        o_seg_blk = {i_seg_l_h, i_seg_r_h, 7'b0000000, 7'b0000000, i_seg_l_s, i_seg_r_s};
                    end
                end
                2'b10: begin
                    if( (cnt_blink % 2) == 0) begin
                        o_seg_blk = {i_seg_l_h, i_seg_r_h, i_seg_l_m, i_seg_r_m, i_seg_l_s, i_seg_r_s};
                    end else begin
                        o_seg_blk = {7'b0000000, 7'b0000000, i_seg_l_m, i_seg_r_m, i_seg_l_s, i_seg_r_s};
                    end
                end
            endcase
        end else if(i_mode_b == 3) begin
            if(i_state_b == 0) begin
                case(i_position_b)
                2'b00: begin
                    if( (cnt_blink % 2) == 0) begin
                        o_seg_blk = {i_seg_l_h, i_seg_r_h, i_seg_l_m, i_seg_r_m, i_seg_l_s, i_seg_r_s};
                    end else begin
                        o_seg_blk = {i_seg_l_h, i_seg_r_h, i_seg_l_m, i_seg_r_m, 7'b0000000, 7'b0000000};
                    end
                end
                2'b01: begin
                    if( (cnt_blink % 2) == 0) begin
                        o_seg_blk = {i_seg_l_h, i_seg_r_h, i_seg_l_m, i_seg_r_m, i_seg_l_s, i_seg_r_s};
                    end else begin
                        o_seg_blk = {i_seg_l_h, i_seg_r_h, 7'b0000000, 7'b0000000, i_seg_l_s, i_seg_r_s};
                    end
                end
                2'b10: begin
                    if( (cnt_blink % 2) == 0) begin
                        o_seg_blk = {i_seg_l_h, i_seg_r_h, i_seg_l_m, i_seg_r_m, i_seg_l_s, i_seg_r_s};
                    end else begin
                        o_seg_blk = {7'b0000000, 7'b0000000, i_seg_l_m, i_seg_r_m, i_seg_l_s, i_seg_r_s};
                    end
                end
                endcase
            end else begin
                o_seg_blk = {i_seg_l_h, i_seg_r_h, i_seg_l_m, i_seg_r_m, i_seg_l_s, i_seg_r_s};
            end
        end else begin
            o_seg_blk = {i_seg_l_h, i_seg_r_h, i_seg_l_m, i_seg_r_m, i_seg_l_s, i_seg_r_s};
        end
        end
endmodule


module switch_debounce(
    output       o_sw,

    input        i_sw,

    input        i_clk,
    input        i_rstn
);

    localparam NCO_DEBOUNCE = 1000000;
    
    wire          clk_debounce;
    nco u_nco_clk_slow(
        .o_clk (clk_debounce),
        .i_num (NCO_DEBOUNCE),
        .i_clk (i_clk       ),
        .i_rstn (i_rstn     ));

    reg       dly_sw0;
    reg       dly_sw1;
    always @(posedge clk_debounce) begin
        dly_sw0 <= i_sw;
        dly_sw1 <= dly_sw0;
    end

    assign o_sw = dly_sw0 | ~dly_sw1;

endmodule

module timer(

    output reg [5:0] o_hms_cnt_sec,
    output reg [5:0] o_hms_cnt_min,
    output reg [5:0] o_hms_cnt_hour,

    output reg       o_max_hit_sec,
    output reg       o_max_hit_min,

    input            i_reset,

    input [5:0]      i_hms_cnt_sec,
    input [5:0]      i_hms_cnt_min,
    input [5:0]      i_hms_cnt_hour,

    input            i_max_hit_sec,
    input            i_max_hit_min,

    input            i_clk,
    input            i_rstn
);
    always @(*) begin

        if(!i_reset) begin

            if(i_hms_cnt_hour == 6'd0) begin

                o_hms_cnt_sec = i_hms_cnt_sec;
                o_hms_cnt_min = i_hms_cnt_min;
                o_hms_cnt_hour = 6'd0;

                o_max_hit_min = 1'b0;
                o_max_hit_sec = i_max_hit_sec;

            end else if((i_hms_cnt_hour == 6'd0) && (i_hms_cnt_min == 6'd0)) begin

                o_hms_cnt_sec = i_hms_cnt_sec;
                o_hms_cnt_min = 6'd0;
                o_hms_cnt_hour = 6'd0;

                o_max_hit_min = 1'b0;
                o_max_hit_sec = 1'b0;

            end else if((i_hms_cnt_hour == 6'd0) && (i_hms_cnt_min == 6'd0) && (i_hms_cnt_sec == 6'd0)) begin

                o_hms_cnt_sec = 6'd0;
                o_hms_cnt_min = 6'd0;
                o_hms_cnt_hour = 6'd0;

                o_max_hit_min = 1'b0;
                o_max_hit_sec = 1'b0;


            end else begin

                o_hms_cnt_sec = i_hms_cnt_sec;
                o_hms_cnt_min = i_hms_cnt_min;
                o_hms_cnt_hour = i_hms_cnt_hour;

                o_max_hit_min = i_max_hit_min;
                o_max_hit_sec = i_max_hit_sec;

            end
        end else begin

            o_hms_cnt_sec = 6'd0;
            o_hms_cnt_min = 6'd0;
            o_hms_cnt_hour = 6'd0;

        end
    end

endmodule

module hourminsec_tp(
    output reg       o_alarm,

    output reg [5:0] o_sec,
    output reg [5:0] o_min,
    output reg [5:0] o_hour,

/*    output     [3:0] o_sec_alm_l,
    output     [3:0] o_sec_alm_r,

    output     [3:0] o_min_alm_l,
    output     [3:0] o_min_alm_r,

    output     [3:0] o_hour_alm_l,
    output     [3:0] o_hour_alm_r,
*/
    output reg [5:0] sec_alm_lcd,
    output reg [5:0] min_alm_lcd,
    output reg [5:0] hour_alm_lcd,

    output           o_sec_max_hit,
    output           o_min_max_hit,

    output           o_sec_max_hit_tim,
    output           o_min_max_hit_tim,

    output      reg  o_state_tim,

    input      [1:0] i_mode,
    input            i_reset,
    input            i_alarm_en,

    input            i_sec_cnt_clk,
    input            i_min_cnt_clk,
    input            i_hour_cnt_clk,

    input            i_sec_alm_clk,
    input            i_min_alm_clk,
    input            i_hour_alm_clk,

    input            i_sec_tim_clk,
    input            i_min_tim_clk,
    input            i_hour_tim_clk,

    input            i_direct_clk,
    input            i_direct_alm,
    input            i_direct_tim,

    input            i_clk,
    input            i_rstn

  );

    localparam MODE_CLOCK = 2'b00;
    localparam MODE_SETUP = 2'b01;
    localparam MODE_ALARM = 2'b10;
    localparam MODE_TIMER = 2'b11;

    localparam POS_SEC = 2'b00;
    localparam POS_MIN = 2'b01;
    localparam POS_HOUR = 2'b10;

    wire [5:0] sec_cnt;
    wire [5:0] min_cnt;
    wire [5:0] hour_cnt;

    wire [5:0] sec_alm;
    wire [5:0] min_alm;
    wire [5:0] hour_alm;

    wire [5:0] sec_tim0;
    wire [5:0] min_tim0;
    wire [5:0] hour_tim0;

    hms_cnt u_hms_cnt_sec(
        .o_hms_cnt (sec_cnt       ),
        .o_max_hit (o_sec_max_hit ),
        .i_max_cnt (6'd59         ),
        .i_direct  (i_direct_clk  ),
        .i_clk     (i_sec_cnt_clk ),
        .i_rstn    (i_rstn        ));
         
    hms_cnt u_hms_cnt_min(
        .o_hms_cnt (min_cnt       ),
        .o_max_hit (o_min_max_hit ),
        .i_max_cnt (6'd59         ),
        .i_direct  (i_direct_clk  ),
        .i_clk     (i_min_cnt_clk ),
        .i_rstn    (i_rstn        ));
    
    hms_cnt u_hmc_cnt_hour(
        .o_hms_cnt (hour_cnt      ),
        .o_max_hit (              ),
        .i_max_cnt (6'd23         ),
        .i_direct  (i_direct_clk  ),
        .i_clk     (i_hour_cnt_clk),
        .i_rstn    (i_rstn        ));

    hms_cnt u_hms_alm_sec(
        .o_hms_cnt (sec_alm       ),
        .o_max_hit (              ),
        .i_max_cnt (6'd59         ),
        .i_direct  (i_direct_alm  ),
        .i_clk     (i_sec_alm_clk ),
        .i_rstn    (i_rstn        ));

    hms_cnt u_hms_alm_min(
        .o_hms_cnt (min_alm       ),
        .o_max_hit (              ),
        .i_max_cnt (6'd59         ),
        .i_direct  (i_direct_alm  ),
        .i_clk     (i_min_alm_clk ),
        .i_rstn    (i_rstn        ));

    hms_cnt u_hms_alm_hour(
        .o_hms_cnt (hour_alm      ),
        .o_max_hit (              ),
        .i_max_cnt (6'd23         ),
        .i_direct  (i_direct_alm  ),
        .i_clk     (i_hour_alm_clk),
        .i_rstn    (i_rstn        ));
 
    wire max_hit_sec_tim;
    hms_cnt u_hms_tim_sec(
        .o_hms_cnt (sec_tim0        ),
        .o_max_hit (max_hit_sec_tim ),
        .i_max_cnt (6'd59           ),
        .i_direct  (i_direct_tim    ),
        .i_clk     (i_sec_tim_clk   ),
        .i_rstn    (i_rstn          ));
         
    wire max_hit_min_tim;
    hms_cnt u_hms_tim_min(
        .o_hms_cnt (min_tim0        ),
        .o_max_hit (max_hit_min_tim ),
        .i_max_cnt (6'd59           ),
        .i_direct  (i_direct_tim    ),
        .i_clk     (i_min_tim_clk   ),
        .i_rstn    (i_rstn          ));

    hms_cnt u_hms_tim_hour(
        .o_hms_cnt (hour_tim0       ),
        .o_max_hit (                ),
        .i_max_cnt (6'd23           ),
        .i_direct  (i_direct_tim    ),
        .i_clk     (i_hour_tim_clk  ),
        .i_rstn    (i_rstn          ));

    wire [5:0] sec_tim;
    wire [5:0] min_tim;
    wire [5:0] hour_tim;

    timer u_timer(
        .o_hms_cnt_sec  (sec_tim          ),
        .o_hms_cnt_min  (min_tim          ),
        .o_hms_cnt_hour (hour_tim         ),

        .o_max_hit_sec  (o_sec_max_hit_tim),
        .o_max_hit_min  (o_min_max_hit_tim),


        .i_hms_cnt_sec  (sec_tim0         ),
        .i_hms_cnt_min  (min_tim0         ),
        .i_hms_cnt_hour (hour_tim0        ),

        .i_max_hit_sec  (max_hit_sec_tim  ),
        .i_max_hit_min  (max_hit_min_tim  ),

        .i_reset        (i_reset          ),

        .i_clk          (i_clk            ),
        .i_rstn         (i_rstn           ));

    always @(*) begin
        if((sec_tim == 6'd0) && (min_tim == 6'd0) && (hour_tim == 6'd0)) begin
            o_state_tim = 1'b0;
        end else begin
            o_state_tim = 1'b1;
        end
    end

    always @(*) begin

        case(i_mode)

            MODE_CLOCK: begin

                o_sec = sec_cnt;
                o_min = min_cnt;
                o_hour = hour_cnt;

            end

            MODE_SETUP: begin

                o_sec = sec_cnt;
                o_min = min_cnt;
                o_hour = hour_cnt;

            end

            MODE_ALARM: begin

                o_sec = sec_alm;
                o_min = min_alm;
                o_hour = hour_alm;

            end

            MODE_TIMER: begin

                o_sec = sec_tim;
                o_min = min_tim;
                o_hour = hour_tim;

            end

        endcase
    end

    always @(*) begin
        sec_alm_lcd = sec_alm;
        min_alm_lcd = min_alm;
        hour_alm_lcd = hour_alm;
    end
    
    
    


    always @(posedge i_clk or negedge i_rstn) begin

        if(!i_rstn) begin

             o_alarm <= 0;

        end else begin

              if( (sec_cnt == sec_alm) && (min_cnt == min_alm) && (hour_cnt == hour_alm)) begin

                   o_alarm <= 1 && i_alarm_en;

              end else if( (sec_tim == 6'd0) && (min_tim == 6'd0) && (hour_tim == 6'd0)) begin

                   o_alarm <= 1 && i_alarm_en;

              end else begin

                o_alarm = o_alarm && i_alarm_en;

            end

        end
    end
	 
endmodule

module controller_tp(

       output reg [1:0] o_mode,
       output reg [1:0] o_position,

       output reg       o_state,
       output reg       o_state_en,
       output reg       o_reset,

       output reg       o_direct_clk,
       output reg       o_direct_alm,
       output reg       o_direct_tim,

       output reg       o_alarm_en,

       output reg       o_sec_cnt_clk,
       output reg       o_min_cnt_clk,
       output reg       o_hour_cnt_clk,

       output reg       o_sec_alm_clk,
       output reg       o_min_alm_clk,
       output reg       o_hour_alm_clk,

       output reg       o_sec_tim_clk,
       output reg       o_min_tim_clk,
       output reg       o_hour_tim_clk,

       input            i_sec_max_hit,
       input            i_min_max_hit,

       input            i_sec_max_hit_tim,
       input            i_min_max_hit_tim,

       input            i_state_tim,

       input            i_sw0,
       input            i_sw1,
       input            i_sw2,
       input            i_sw3,
       input            i_sw4,
       input            i_sw5,
       input            i_sw6,
       input            i_sw7,

       input            i_sw_r0,
       input            i_sw_r1,
       input            i_sw_r2,
       input            i_sw_r3,
       input            i_sw_r4,
       input            i_sw_r5,
       input            i_sw_r6,
       input            i_sw_r7,

       input            i_clk,
       input            i_rstn
    );

       localparam MODE_CLOCK = 2'b00;
       localparam MODE_SETUP = 2'b01;
       localparam MODE_ALARM = 2'b10;
       localparam MODE_TIMER = 2'b11;

       localparam POS_SEC = 2'b00;
       localparam POS_MIN = 2'b01;
       localparam POS_HOUR = 2'b10;

       localparam STA_STOP = 1'b0;
       localparam STA_START = 1'b1;

       localparam TIM_ORIG = 1'b0;
       localparam TIM_RESET = 1'b1;

       wire  i_sw_t0;
       wire  i_sw_t1;
       wire  i_sw_t2;
       wire  i_sw_t3;
       wire  i_sw_t4;
       wire  i_sw_t5;
       wire  i_sw_t6;
       wire  i_sw_t7;

       assign i_sw_t0 = i_sw0 && i_sw_r0; // remote signal && switch button
       assign i_sw_t1 = i_sw1 && i_sw_r1; 
       assign i_sw_t2 = i_sw2 && i_sw_r2;
       assign i_sw_t3 = i_sw3 && i_sw_r3;
       assign i_sw_t4 = i_sw4 && i_sw_r4;
       assign i_sw_t5 = i_sw5 && i_sw_r5;
       assign i_sw_t6 = i_sw6 && i_sw_r6;
       assign i_sw_t7 = i_sw7 && i_sw_r7;


       always @(posedge ~i_sw_t0 or negedge i_rstn) begin // mode (clock, setting, alarm, timer)
           if(!i_rstn) begin
               o_mode <= MODE_CLOCK;
           end else begin
                if(o_mode != MODE_TIMER) begin
                     o_mode <= o_mode + 1;
                end else begin
                     o_mode <= MODE_CLOCK;
                end
           end
       end

       always @(posedge ~i_sw_t1 or negedge i_rstn) begin // setting position
           if(!i_rstn) begin
                o_position <= POS_SEC;
           end else begin
                if(o_position == POS_HOUR) begin
                     o_position <= POS_SEC;
                end else begin
                     o_position <= o_position + 1;
                end
           end
       end

       always @(posedge ~i_sw_t3 or negedge i_rstn) begin // alarm on/off
            if(!i_rstn) begin
                o_alarm_en <= 0;
            end else begin
                o_alarm_en <= ~o_alarm_en;
            end
       end

       always @(posedge ~i_sw_t4 or negedge i_rstn) begin // start or stop
           if(!i_rstn) begin
                o_state_en <= STA_STOP;
           end else begin
                if(o_state_en == STA_START) begin
                     o_state_en <= STA_STOP;
                end else begin
                     o_state_en <= o_state_en + 1;
                end
           end
       end

       always @(posedge ~i_sw_t5 or negedge i_rstn) begin  // reset
           if(!i_rstn) begin
                o_reset <= TIM_ORIG;
           end else begin
                if(o_reset == TIM_RESET) begin
                     o_reset <= TIM_ORIG;
                end else begin
                     o_reset <= o_reset + 1;
                end
           end
       end

        wire clk_1hz;
        nco u_nco_clk_1hz(
             .o_clk (clk_1hz ),
             .i_num (50000000 ),
             .i_clk (i_clk ),
             .i_rstn (i_rstn )); 

        always @(*) begin

            if(!i_sw_t2) begin

                o_direct_clk = 1'b0;
                o_direct_alm = 1'b0;
                o_direct_tim = 1'b0;

            end else if(!i_sw_t6) begin

                o_direct_clk = 1'b1;
                o_direct_alm = 1'b1;
                o_direct_tim = 1'b1;

            end else begin

                o_direct_clk = 1'b0;
                o_direct_alm = 1'b0;
                o_direct_tim = 1'b1;

            end
        end

        always @(*) begin

            if(i_state_tim == 1'b0) begin

                o_state = 1'b0; 

            end else begin

                o_state = o_state_en;

            end
        end

        always @(*) begin
            case(o_mode) 

              MODE_CLOCK: begin
                case(o_state)
                    1'b0: begin

                        o_sec_cnt_clk  = clk_1hz;
                        o_min_cnt_clk  = i_sec_max_hit;
                        o_hour_cnt_clk = i_min_max_hit;

                        o_sec_alm_clk  = 1'b0;
                        o_min_alm_clk  = 1'b0;
                        o_hour_alm_clk = 1'b0;

                        o_sec_tim_clk  = 1'b0;
                        o_min_tim_clk  = 1'b0;
                        o_hour_tim_clk = 1'b0;

                    end
                    1'b1: begin

                        o_sec_cnt_clk  = clk_1hz;
                        o_min_cnt_clk  = i_sec_max_hit;
                        o_hour_cnt_clk = i_min_max_hit;

                        o_sec_alm_clk  = 1'b0;
                        o_min_alm_clk  = 1'b0;
                        o_hour_alm_clk = 1'b0;

                        o_sec_tim_clk  = clk_1hz;
                        o_min_tim_clk  = i_sec_max_hit_tim;
                        o_hour_tim_clk = i_min_max_hit_tim;
                    end
                endcase
              end

              MODE_SETUP: begin
                case(o_position)
                    POS_SEC: begin

                        case(o_state)
                            1'b0: begin

                                o_sec_cnt_clk  = ~i_sw_t2 || ~i_sw_t6;
                                o_min_cnt_clk  = 1'b0;
                                o_hour_cnt_clk = 1'b0;

                                o_sec_alm_clk  = 1'b0;
                                o_min_alm_clk  = 1'b0;
                                o_hour_alm_clk = 1'b0;

                                o_sec_tim_clk  = 1'b0;
                                o_min_tim_clk  = 1'b0;
                                o_hour_tim_clk = 1'b0;

                            end
                            1'b1: begin

                                o_sec_cnt_clk  = ~i_sw_t2 || ~i_sw_t6;
                                o_min_cnt_clk  = 1'b0;
                                o_hour_cnt_clk = 1'b0;

                                o_sec_alm_clk  = 1'b0;
                                o_min_alm_clk  = 1'b0;
                                o_hour_alm_clk = 1'b0;

                                o_sec_tim_clk  = clk_1hz;
                                o_min_tim_clk  = i_sec_max_hit_tim;
                                o_hour_tim_clk = i_min_max_hit_tim;

                            end
                        endcase
                    end

                    POS_MIN: begin
                        case(o_state)
                            1'b0: begin

                                o_sec_cnt_clk  = 1'b0;
                                o_min_cnt_clk  = ~i_sw_t2 || ~i_sw_t6;
                                o_hour_cnt_clk = 1'b0;

                                o_sec_alm_clk  = 1'b0;
                                o_min_alm_clk  = 1'b0;
                                o_hour_alm_clk = 1'b0;

                                o_sec_tim_clk  = 1'b0;
                                o_min_tim_clk  = 1'b0;
                                o_hour_tim_clk = 1'b0;
                            end
                            1'b1: begin

                                o_sec_cnt_clk  = 1'b0;
                                o_min_cnt_clk  = ~i_sw_t2 || ~i_sw_t6;
                                o_hour_cnt_clk = 1'b0;

                                o_sec_alm_clk  = 1'b0;
                                o_min_alm_clk  = 1'b0;
                                o_hour_alm_clk = 1'b0;

                                o_sec_tim_clk  = clk_1hz;
                                o_min_tim_clk  = i_sec_max_hit_tim;
                                o_hour_tim_clk = i_min_max_hit_tim;

                            end
                        endcase

                    end

                    POS_HOUR: begin
                        case(o_state)
                            1'b0: begin

                                o_sec_cnt_clk  = 1'b0;
                                o_min_cnt_clk  = 1'b0;
                                o_hour_cnt_clk = ~i_sw_t2 || ~i_sw_t6;

                                o_sec_alm_clk  = 1'b0;
                                o_min_alm_clk  = 1'b0;
                                o_hour_alm_clk = 1'b0;

                                o_sec_tim_clk  = 1'b0;
                                o_min_tim_clk  = 1'b0;
                                o_hour_tim_clk = 1'b0;

                            end
                            1'b1: begin

                                o_sec_cnt_clk  = 1'b0;
                                o_min_cnt_clk  = 1'b0;
                                o_hour_cnt_clk = ~i_sw_t2 || ~i_sw_t6;

                                o_sec_alm_clk  = 1'b0;
                                o_min_alm_clk  = 1'b0;
                                o_hour_alm_clk = 1'b0;

                                o_sec_tim_clk  = clk_1hz;
                                o_min_tim_clk  = i_sec_max_hit_tim;
                                o_hour_tim_clk = i_min_max_hit_tim;

                            end
                        endcase

                    end
                endcase
              end

              MODE_ALARM: begin
                case(o_position)

                    POS_SEC: begin
                        case(o_state)
                            1'b0: begin

                                o_sec_cnt_clk  = clk_1hz;
                                o_min_cnt_clk  = i_sec_max_hit;
                                o_hour_cnt_clk = i_min_max_hit;

                                o_sec_alm_clk  = ~i_sw_t2 || ~i_sw_t6;
                                o_min_alm_clk  = 1'b0;
                                o_hour_alm_clk = 1'b0;

                                o_sec_tim_clk  = 1'b0;
                                o_min_tim_clk  = 1'b0;
                                o_hour_tim_clk = 1'b0;

                            end
                            1'b1: begin

                                o_sec_cnt_clk  = clk_1hz;
                                o_min_cnt_clk  = i_sec_max_hit;
                                o_hour_cnt_clk = i_min_max_hit;

                                o_sec_alm_clk  = ~i_sw_t2 || ~i_sw_t6;
                                o_min_alm_clk  = 1'b0;
                                o_hour_alm_clk = 1'b0;

                                o_sec_tim_clk  = clk_1hz;
                                o_min_tim_clk  = i_sec_max_hit_tim;
                                o_hour_tim_clk = i_min_max_hit_tim;
                            end
                        endcase
                    end

                    POS_MIN: begin
                        case(o_state)
                            1'b0: begin

                                o_sec_cnt_clk  = clk_1hz;
                                o_min_cnt_clk  = i_sec_max_hit;
                                o_hour_cnt_clk = i_min_max_hit;

                                o_sec_alm_clk  = 1'b0;
                                o_min_alm_clk  = ~i_sw_t2 || ~i_sw_t6;
                                o_hour_alm_clk = 1'b0;

                                o_sec_tim_clk  = 1'b0;
                                o_min_tim_clk  = 1'b0;
                                o_hour_tim_clk = 1'b0;

                            end
                            1'b1: begin

                                o_sec_cnt_clk  = clk_1hz;
                                o_min_cnt_clk  = i_sec_max_hit;
                                o_hour_cnt_clk = i_min_max_hit;

                                o_sec_alm_clk  = 1'b0;
                                o_min_alm_clk  = ~i_sw_t2 || ~i_sw_t6;
                                o_hour_alm_clk = 1'b0;

                                o_sec_tim_clk  = clk_1hz;
                                o_min_tim_clk  = i_sec_max_hit_tim;
                                o_hour_tim_clk = i_min_max_hit_tim;

                            end
                        endcase
                    end

                    POS_HOUR: begin
                        case(o_state)
                            1'b0: begin

                                o_sec_cnt_clk  = clk_1hz;
                                o_min_cnt_clk  = i_sec_max_hit;
                                o_hour_cnt_clk = i_min_max_hit;

                                o_sec_alm_clk  = 1'b0;
                                o_min_alm_clk  = 1'b0;
                                o_hour_alm_clk = ~i_sw_t2 || ~i_sw_t6;

                                o_sec_tim_clk  = 1'b0;
                                o_min_tim_clk  = 1'b0;
                                o_hour_tim_clk = 1'b0;

                            end
                            1'b1: begin

                                o_sec_cnt_clk  = clk_1hz;
                                o_min_cnt_clk  = i_sec_max_hit;
                                o_hour_cnt_clk = i_min_max_hit;

                                o_sec_alm_clk  = 1'b0;
                                o_min_alm_clk  = 1'b0;
                                o_hour_alm_clk = ~i_sw_t2 || ~i_sw_t6;

                                o_sec_tim_clk  = clk_1hz;
                                o_min_tim_clk  = i_sec_max_hit_tim;
                                o_hour_tim_clk = i_min_max_hit_tim;

                            end
                        endcase
                    end
                endcase
              end

              MODE_TIMER: begin
                case(o_position)

                    POS_SEC: begin
                        case(o_state)
                            1'b0: begin

                                o_sec_cnt_clk  = clk_1hz;
                                o_min_cnt_clk  = i_sec_max_hit;
                                o_hour_cnt_clk = i_min_max_hit;

                                o_sec_alm_clk  = 1'b0;
                                o_min_alm_clk  = 1'b0;
                                o_hour_alm_clk = 1'b0;

                                o_sec_tim_clk  = ~i_sw_t2 || ~i_sw_t6;
                                o_min_tim_clk  = 1'b0;
                                o_hour_tim_clk = 1'b0;

                            end
                            1'b1: begin

                                o_sec_cnt_clk  = clk_1hz;
                                o_min_cnt_clk  = i_sec_max_hit;
                                o_hour_cnt_clk = i_min_max_hit;

                                o_sec_alm_clk  = 1'b0;
                                o_min_alm_clk  = 1'b0;
                                o_hour_alm_clk = 1'b0;

                                o_sec_tim_clk  = clk_1hz;
                                o_min_tim_clk  = i_sec_max_hit_tim;
                                o_hour_tim_clk = i_min_max_hit_tim;

                            end
                        endcase
                    end

                    POS_MIN: begin
                        case(o_state)
                            1'b0: begin

                                o_sec_cnt_clk  = clk_1hz;
                                o_min_cnt_clk  = i_sec_max_hit;
                                o_hour_cnt_clk = i_min_max_hit;

                                o_sec_alm_clk  = 1'b0;
                                o_min_alm_clk  = 1'b0;
                                o_hour_alm_clk = 1'b0;

                                o_sec_tim_clk  = 1'b0;
                                o_min_tim_clk  = ~i_sw_t2 || ~i_sw_t6;
                                o_hour_tim_clk = 1'b0;

                            end
                            1'b1: begin

                                o_sec_cnt_clk  = clk_1hz;
                                o_min_cnt_clk  = i_sec_max_hit;
                                o_hour_cnt_clk = i_min_max_hit;

                                o_sec_alm_clk  = 1'b0;
                                o_min_alm_clk  = 1'b0;
                                o_hour_alm_clk = 1'b0;

                                o_sec_tim_clk  = clk_1hz;
                                o_min_tim_clk  = i_sec_max_hit_tim;
                                o_hour_tim_clk = i_min_max_hit_tim;

                            end
                        endcase
                    end

                    POS_HOUR: begin
                        case(o_state)
                            1'b0: begin

                                o_sec_cnt_clk  = clk_1hz;
                                o_min_cnt_clk  = i_sec_max_hit;
                                o_hour_cnt_clk = i_min_max_hit;

                                o_sec_alm_clk  = 1'b0;
                                o_min_alm_clk  = 1'b0;
                                o_hour_alm_clk = 1'b0;

                                o_sec_tim_clk  = 1'b0;
                                o_min_tim_clk  = 1'b0;
                                o_hour_tim_clk = ~i_sw_t2 || ~i_sw_t6;

                            end
                            1'b1: begin

                                o_sec_cnt_clk  = clk_1hz;
                                o_min_cnt_clk  = i_sec_max_hit;
                                o_hour_cnt_clk = i_min_max_hit;

                                o_sec_alm_clk  = 1'b0;
                                o_min_alm_clk  = 1'b0;
                                o_hour_alm_clk = 1'b0;

                                o_sec_tim_clk  = clk_1hz;
                                o_min_tim_clk  = i_sec_max_hit_tim;
                                o_hour_tim_clk = i_min_max_hit_tim;
                                
                            end
                        endcase
                    end
                endcase
              end
            endcase
        end     
endmodule

module buzz_reset(
    output reg [4:0] o_cnt_buzz,

    input            i_alm_en_rst,
    input            i_cnt_buzz
);
    always @(*) begin
        if(!i_alm_en_rst) begin
            o_cnt_buzz = 0;
        end else begin
            o_cnt_buzz = i_cnt_buzz;
        end
    end
endmodule

module buzz(

    output   o_buzz,

    input    i_alm_en,
    input    i_buzz_en,

    input    i_clk,
    input    i_rstn
);

localparam C = 191113;
    localparam D = 170262;
    localparam E = 151686;
    localparam F = 143173;
    localparam G = 63776;
    localparam A = 56818;
    localparam B = 50619;

    wire clk_beat;
    nco u_nco_beat(
        .o_clk (clk_beat),
        .i_num (25000000),
        .i_clk (i_clk),
        .i_rstn (i_rstn));

    wire [4:0] cnt_buzz_0;
    cnt_param #(
        .RANGE (25))
    u_cnt_buzz(
        .o_cnt (cnt_buzz_0),
        .i_direct (1'b0),
        .i_clk (clk_beat),
        .i_rstn (i_rstn));

    wire [4:0] cnt_buzz;
    buzz_reset u_buzz_reset( 
        .o_cnt_buzz (cnt_buzz),
        .i_alm_en_rst (i_alm_en),
        .i_cnt_buzz (cnt_buzz_0));


    reg [31:0] buzz_freq;
    always @(*) begin
        case(cnt_buzz)
            5'd00: buzz_freq = E;
            5'd01: buzz_freq = D;
            5'd02: buzz_freq = C;
            5'd03: buzz_freq = D;
            5'd04: buzz_freq = E;
            5'd05: buzz_freq = E;
            5'd06: buzz_freq = E;
            5'd07: buzz_freq = D;
            5'd08: buzz_freq = D;
            5'd09: buzz_freq = D;
            5'd10: buzz_freq = E;
            5'd11: buzz_freq = E;
            5'd12: buzz_freq = E;
            5'd13: buzz_freq = E;
            5'd14: buzz_freq = D;
            5'd15: buzz_freq = C;
            5'd16: buzz_freq = D; 
            5'd17: buzz_freq = E;
            5'd18: buzz_freq = E; 
            5'd19: buzz_freq = E;
            5'd20: buzz_freq = D;
            5'd21: buzz_freq = D;
            5'd22: buzz_freq = E;
            5'd23: buzz_freq = D;
            5'd24: buzz_freq = C;
        endcase
    end

    wire buzz;
    nco u_nco_buzz(
        .o_clk (buzz),
        .i_num (buzz_freq),
        .i_clk (i_clk),
        .i_rstn (i_rstn));

    assign o_buzz = buzz & i_buzz_en;

endmodule

module ir_rx(

    output reg [31:0] o_data,
    output reg        o_pulse_make,

    input             i_ir_rxb,

    input             i_clk,
    input             i_rstn
);
   localparam IDLE = 2'b00;
   localparam LEADCODE = 2'b01;
   localparam DATACODE = 2'b10;
   localparam COMPLETE = 2'b11;

   // 1MHz clk
   wire clk_1M;
   nco u_nco(
    .o_clk (clk_1M),
    .i_num (50),
    .i_clk (i_clk),
    .i_rstn (i_rstn));

  // Rx bit
  wire ir_rx;
  assign ir_rx = ~ i_ir_rxb;

  reg [1:0] seq_rx;
  always @(posedge clk_1M or negedge i_rstn) begin
    if(!i_rstn) begin
        seq_rx <= 2'b00;
    end else begin
        seq_rx <= {seq_rx[0], ir_rx};
    end
  end

  // cnt (high/low)
  reg [15:0] cnt_h;
  reg [15:0] cnt_l;
  always @(posedge clk_1M or negedge i_rstn) begin
    if(!i_rstn) begin
        cnt_h <= 16'd0;
        cnt_l <= 16'd0;
    end else begin
        case(seq_rx) 
          2'b00: cnt_l <= cnt_l + 1;
          2'b01: begin
            cnt_l <= 16'd0;
            cnt_h <= 16'd0;
          end
          2'b11: cnt_h <= cnt_h + 1;
        endcase
    end
  end

  // state machine
  reg [1:0] state;
  reg [5:0] cnt32;
  always @(posedge clk_1M or negedge i_rstn) begin
    if(!i_rstn) begin
        state <= IDLE;
        cnt32 <= {6{1'b1}};
        o_pulse_make <= 1'b0; // 1'b0
    end else begin
        case(state)
          IDLE: begin
            state <= LEADCODE;
            cnt32 <= {6{1'b1}};
            o_pulse_make <= 1'b0;
          end
          LEADCODE: begin
            if(cnt_h >= 8500 && cnt_l >= 4000) begin
                state <= DATACODE;
            end else begin
                state <= LEADCODE;
            end
          end
          DATACODE: begin
            if(seq_rx == 2'b01) begin
                cnt32 <= cnt32 + 1;
            end else begin
                cnt32 <= cnt32;
            end
            if(cnt32 == 32) begin
                state <= COMPLETE;
                o_pulse_make <= 1'b1; // 1'b1
            end
          end
          COMPLETE: state <= IDLE;
        endcase
    end
  end

  // 32bit custom & data
  reg [31:0] data;
  always @(posedge clk_1M or negedge i_rstn) begin
    if(!i_rstn) begin
        data <= 0;
    end else begin
        case(state)
          DATACODE: begin
            if(cnt_l >= 1000) begin
                data[31-cnt32] <= 1;
            end else begin
                data[31-cnt32] <= 0;
            end
          end
          COMPLETE: o_data <= data;
        endcase
    end
  end
endmodule
    
module remote_controller(

    output reg        o_sw0,
    output reg        o_sw1,
    output reg        o_sw2,
    output reg        o_sw3,
    output reg        o_sw4,
    output reg        o_sw5,
    output reg        o_sw6,
    output reg        o_sw7,

    input      [31:0] i_data,
    input             i_pulse_make,

    input             i_clk,
    input             i_rstn
);
    always @(posedge i_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            o_sw0 <= 1'b1;
            o_sw1 <= 1'b1;
            o_sw2 <= 1'b1;
            o_sw3 <= 1'b1;
            o_sw4 <= 1'b1;
            o_sw5 <= 1'b1;
            o_sw6 <= 1'b1;
            o_sw7 <= 1'b1;
        end else begin
            if(i_pulse_make == 1'b1) begin
                case(i_data[23:0]) 
                    24'hFD40BF: begin
                        o_sw0 <= 1'b0;
                        o_sw1 <= 1'b1;
                        o_sw2 <= 1'b1;
                        o_sw3 <= 1'b1;
                        o_sw4 <= 1'b1;
                        o_sw5 <= 1'b1;
                        o_sw6 <= 1'b1;
                        o_sw7 <= 1'b1;
                    end
                    24'hFD10EF: begin
                        o_sw0 <= 1'b1;
                        o_sw1 <= 1'b0;
                        o_sw2 <= 1'b1;
                        o_sw3 <= 1'b1;
                        o_sw4 <= 1'b1;
                        o_sw5 <= 1'b1;
                        o_sw6 <= 1'b1;
                        o_sw7 <= 1'b1;
                    end
                    24'hFD20DF: begin
                        o_sw0 <= 1'b1;
                        o_sw1 <= 1'b1;
                        o_sw2 <= 1'b0;
                        o_sw3 <= 1'b1;
                        o_sw4 <= 1'b1;
                        o_sw5 <= 1'b1;
                        o_sw6 <= 1'b1;
                        o_sw7 <= 1'b1;
                    end
                    24'hFD00FF: begin
                        o_sw0 <= 1'b1;
                        o_sw1 <= 1'b1;
                        o_sw2 <= 1'b1;
                        o_sw3 <= 1'b0;
                        o_sw4 <= 1'b1;
                        o_sw5 <= 1'b1;
                        o_sw6 <= 1'b1;
                        o_sw7 <= 1'b1;
                    end
                    24'hFD906F: begin
                        o_sw0 <= 1'b1;
                        o_sw1 <= 1'b1;
                        o_sw2 <= 1'b1;
                        o_sw3 <= 1'b1;
                        o_sw4 <= 1'b0;
                        o_sw5 <= 1'b1;
                        o_sw6 <= 1'b1;
                        o_sw7 <= 1'b1;
                    end
                    24'hFD609F: begin
                        o_sw0 <= 1'b1;
                        o_sw1 <= 1'b1;
                        o_sw2 <= 1'b1;
                        o_sw3 <= 1'b1;
                        o_sw4 <= 1'b1;
                        o_sw5 <= 1'b0;
                        o_sw6 <= 1'b1;
                        o_sw7 <= 1'b1;
                    end
                    24'hFD30CF: begin
                        o_sw0 <= 1'b1;
                        o_sw1 <= 1'b1;
                        o_sw2 <= 1'b1;
                        o_sw3 <= 1'b1;
                        o_sw4 <= 1'b1;
                        o_sw5 <= 1'b1;
                        o_sw6 <= 1'b0;
                        o_sw7 <= 1'b1;
                    end
                    default: begin
                        o_sw0 <= 1'b1;
                        o_sw1 <= 1'b1;
                        o_sw2 <= 1'b1;
                        o_sw3 <= 1'b1;
                        o_sw4 <= 1'b1;
                        o_sw5 <= 1'b1;
                        o_sw6 <= 1'b1;
                        o_sw7 <= 1'b1;
                    end
                endcase
            end else begin
                o_sw0 <= 1'b1;
                o_sw1 <= 1'b1;
                o_sw2 <= 1'b1;
                o_sw3 <= 1'b1;
                o_sw4 <= 1'b1;
                o_sw5 <= 1'b1;
                o_sw6 <= 1'b1;
                o_sw7 <= 1'b1;
            end
        end
    end

endmodule


module text_lcd(

    output reg          o_lcd_e,
    output reg          o_lcd_rs,
    output reg          o_lcd_rw,

    inout [7:0]         io_lcd_data,

    input [2*16*8-1:0]  i_line_data,
    input               i_line_data_vaild,

    input               i_clk,
    input               i_rstn
);

    //10bit: RS & R/W & Data(8bit)
    localparam CMD_CLEAR_DISPLAY     = 10'b00_0000_0001;
    localparam CMD_RETURN_HOME       = 10'b00_0000_0010;
    localparam CMD_ENTRY_MODE_SET    = 10'b00_0000_0110;
    localparam CMD_DISP_ONOFF_CTRL   = 10'b00_0000_1100;
    localparam CMD_CURSOR_DISP_SHIFT = 10'b00_0001_1000;
    localparam CMD_FUNCTION_SET      = 10'b00_0011_1100;
    localparam CMD_READ_BUSY_FLAG    = 10'b01_zzzz_zzzz;
    localparam CMD_SET_DDRAM_ADDR1   = 10'b00_1000_0000;
    localparam CMD_SET_DDRAM_ADDR2   = 10'b00_1100_0000;
    localparam CMD_WRITE_RAM_DATA    = 2'b10;

    `ifdef DEBUG
        reg [127:0]  state;
        localparam IDLE   = "IDLE";
        localparam WAIT_INPUT = "WAIT INPUT";
        localparam BUSY_CHECK = "BUSY_CHECK";
        localparam EXCUTE_CMD = "EXCUTE_CMD";
    `else
        reg [1:0]    state;
        localparam IDLE = 0;
        localparam WAIT_INPUT = 1;
        localparam BUSY_CHECK = 2;
        localparam EXCUTE_CMD = 3;
    `endif 
    
    reg [2*16*8-1:0]   line_data;
    always @(posedge i_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            line_data <= 0;
        end else begin
            if(i_line_data_vaild) begin
                line_data <= i_line_data;
            end else begin
                line_data <= line_data;
            end
        end
    end

    wire clk_1mhz;
    nco u_nco(
        .o_clk (clk_1mhz),
        .i_num (50),
        .i_clk (i_clk),
        .i_rstn (i_rstn));

    reg   out_en;
    reg [7:0] lcd_data;
    assign       io_lcd_data = out_en? lcd_data : 8'hzz;

    reg [1:0] cnt_timing;
    reg [7:0] cnt_cmd;
    reg       busy_flag;

    always @(posedge clk_1mhz or negedge i_rstn) begin
        if(!i_rstn) begin
            cnt_timing <= 0;
        end else begin
            cnt_timing <= cnt_timing + 1;
        end 
    end

    always @(posedge clk_1mhz or negedge i_rstn) begin
        if(!i_rstn) begin
            state   <= IDLE;
            cnt_cmd <= 0;
            busy_flag <= 1;
        end else begin
            if(cnt_timing == 3) begin
                case(state)
                   IDLE: begin
                    if(i_line_data_vaild) begin
                        state <= WAIT_INPUT;
                    end else begin
                        state <= IDLE;
                    end
                   end
                   WAIT_INPUT: state <= BUSY_CHECK;
                   BUSY_CHECK: begin
                    if(busy_flag == 0) begin
                        state <= EXCUTE_CMD;
                    end else begin
                        state <= BUSY_CHECK;
                    end
                   end
                   EXCUTE_CMD: begin
                    if({o_lcd_rs, o_lcd_rw, lcd_data} == CMD_RETURN_HOME) begin
                        state <= IDLE;
                        cnt_cmd <= 0;
                    end else begin
                        state <= BUSY_CHECK;
                        cnt_cmd <= cnt_cmd + 1;
                    end
                   end
                endcase
            end else begin
                if(state == BUSY_CHECK) begin
                    busy_flag <= io_lcd_data[7];
                end
            end
        end
    end  

    always @(*) begin
        if(state == BUSY_CHECK) begin
            out_en = 0;
        end else begin
            out_en = 1;
        end
    end

    always @(*) begin
        if(cnt_timing == 1 || cnt_timing == 2) begin
            o_lcd_e = 1;
        end else begin
            o_lcd_e = 0;
        end
    end

    always @(*) begin
        case(state)
           BUSY_CHECK: begin
               {o_lcd_rs, o_lcd_rw, lcd_data} = CMD_READ_BUSY_FLAG;
           end
           EXCUTE_CMD: begin
               case(cnt_cmd)
                   00: {o_lcd_rs, o_lcd_rw, lcd_data} = CMD_CLEAR_DISPLAY;
                   01: {o_lcd_rs, o_lcd_rw, lcd_data} = CMD_FUNCTION_SET;
                   02: {o_lcd_rs, o_lcd_rw, lcd_data} = CMD_DISP_ONOFF_CTRL;
                   03: {o_lcd_rs, o_lcd_rw, lcd_data} = CMD_ENTRY_MODE_SET;
                   04: {o_lcd_rs, o_lcd_rw, lcd_data} = CMD_SET_DDRAM_ADDR1;
                   05: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-00*8)-:8]};
                   06: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-01*8)-:8]};
                   07: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-02*8)-:8]};
                   08: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-03*8)-:8]};
                   09: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-04*8)-:8]};
                   10: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-05*8)-:8]};
                   11: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-06*8)-:8]};
                   12: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-07*8)-:8]};
                   13: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-08*8)-:8]};
                   14: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-09*8)-:8]};
                   15: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-10*8)-:8]};
                   16: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-11*8)-:8]};
                   17: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-12*8)-:8]};
                   18: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-13*8)-:8]};
                   19: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-14*8)-:8]};
                   20: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-15*8)-:8]};
                   21: {o_lcd_rs, o_lcd_rw, lcd_data} = CMD_SET_DDRAM_ADDR2;
                   22: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-16*8)-:8]};
                   23: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-17*8)-:8]};
                   24: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-18*8)-:8]};
                   25: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-19*8)-:8]};
                   26: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-20*8)-:8]};
                   27: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-21*8)-:8]};
                   28: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-22*8)-:8]};
                   29: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-23*8)-:8]};
                   30: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-24*8)-:8]};
                   31: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-25*8)-:8]};
                   32: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-26*8)-:8]};
                   33: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-27*8)-:8]};
                   34: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-28*8)-:8]};
                   35: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-29*8)-:8]};
                   36: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-30*8)-:8]};
                   37: {o_lcd_rs, o_lcd_rw, lcd_data} = {CMD_WRITE_RAM_DATA, line_data[(2*16*8-1-31*8)-:8]};
                   38: {o_lcd_rs, o_lcd_rw, lcd_data} = CMD_RETURN_HOME;
               endcase
           end
        endcase
    end
endmodule
       
module top_tp(

    output [5:0] o_seg_enb,
    output       o_seg_dp,
    output [6:0] o_seg,

    output       o_lcd_e,
    output       o_lcd_rs,
    output       o_lcd_rw,

    output       o_buzz,

    inout  [7:0] io_lcd_data,

    input        i_sw0,
    input        i_sw1,
    input        i_sw2,
    input        i_sw3,
    input        i_sw4,
    input        i_sw5,
    input        i_sw6,
    input        i_sw7,

    input        i_ir_rxb,

    input        i_clk,
    input        i_rstn
);

    localparam NCO_NUM_SPEED = 100000;

    wire sec_ct;
    wire min_ct;
    wire hour_ct;

    wire alarm_en;

    wire sec_alarm;
    wire min_alarm;
    wire hour_alarm;

    wire sec_timer;
    wire min_timer;
    wire hour_timer;

    wire [2:0] direct;
    wire [1:0] mode;
    wire [1:0] position;

    wire [5:0] sec_range;
    wire [5:0] min_range;
    wire [5:0] hour_range;

    wire sw_deb0;
    wire sw_deb1;
    wire sw_deb2;
    wire sw_deb3;
    wire sw_deb4;
    wire sw_deb5;
    wire sw_deb6;
    wire sw_deb7;

    switch_debounce u_switch_debounce0(
        .o_sw   (sw_deb0),
        .i_sw   (i_sw0),
        .i_clk  (i_clk),
        .i_rstn (i_rstn));

    switch_debounce u_switch_debounce1(
        .o_sw   (sw_deb1),
        .i_sw   (i_sw1),
        .i_clk  (i_clk),
        .i_rstn (i_rstn));

    switch_debounce u_switch_debounce2(
        .o_sw   (sw_deb2),
        .i_sw   (i_sw2),
        .i_clk  (i_clk),
        .i_rstn (i_rstn));

    switch_debounce u_switch_debounce3(
        .o_sw   (sw_deb3),
        .i_sw   (i_sw3),
        .i_clk  (i_clk),
        .i_rstn (i_rstn));

    switch_debounce u_switch_debounce4(
        .o_sw   (sw_deb4),
        .i_sw   (i_sw4),
        .i_clk  (i_clk),
        .i_rstn (i_rstn));

    switch_debounce u_switch_debounce5(
        .o_sw   (sw_deb5),
        .i_sw   (i_sw5),
        .i_clk  (i_clk),
        .i_rstn (i_rstn));

    switch_debounce u_switch_debounce6(
        .o_sw   (sw_deb6),
        .i_sw   (i_sw6),
        .i_clk  (i_clk),
        .i_rstn (i_rstn));

    switch_debounce u_switch_debounce7(
        .o_sw   (sw_deb7),
        .i_sw   (i_sw7),
        .i_clk  (i_clk),
        .i_rstn (i_rstn));

    wire pulse_make;

    ir_rx u_ir_rx(
        .o_data       (o_data),

        .o_pulse_make (pulse_make),

        .i_ir_rxb     (i_ir_rxb),
        .i_clk        (i_clk),
        .i_rstn       (i_rstn));

    wire sw0;
    wire sw1;
    wire sw2;
    wire sw3;
    wire sw4;
    wire sw5;
    wire sw6;
    wire sw7;

    remote_controller u_remote_controller(
        .o_sw0        (sw0),
        .o_sw1        (sw1),
        .o_sw2        (sw2),
        .o_sw3        (sw3),
        .o_sw4        (sw4),
        .o_sw5        (sw5),
        .o_sw6        (sw6),
        .o_sw7        (sw7),

        .i_data       (o_data),

        .i_pulse_make (pulse_make),

        .i_clk        (i_clk),
        .i_rstn       (i_rstn));

    controller_tp u_controller(

        .o_mode         (mode),
        .o_position     (position),
 
        .o_state        (o_state),
        .o_state_en     (o_state_en),
        .o_reset        (reset),

        .o_direct_clk   (direct_clk),
        .o_direct_alm   (direct_alm),
        .o_direct_tim   (direct_tim),

        .o_alarm_en     (alarm_en),

        .o_sec_cnt_clk  (sec_ct),
        .o_min_cnt_clk  (min_ct),
        .o_hour_cnt_clk (hour_ct),

        .o_sec_alm_clk (sec_alarm),
        .o_min_alm_clk (min_alarm),
        .o_hour_alm_clk (hour_alarm),

        .o_sec_tim_clk  (sec_timer),
        .o_min_tim_clk  (min_timer),
        .o_hour_tim_clk (hour_timer),

        .i_sec_max_hit  (i_sec_max_hit),
        .i_min_max_hit  (i_min_max_hit),

        .i_sec_max_hit_tim (i_sec_max_hit_tim),
        .i_min_max_hit_tim (i_min_max_hit_tim),

        .i_state_tim        (o_state_tim),

        .i_sw0           (sw0),
        .i_sw1           (sw1),
        .i_sw2           (sw2),
        .i_sw3           (sw3),
        .i_sw4           (sw4),
        .i_sw5           (sw5),
        .i_sw6           (sw6),
        .i_sw7           (sw7),

        .i_sw_r0         (sw_deb0),
        .i_sw_r1         (sw_deb1),
        .i_sw_r2         (sw_deb2),
        .i_sw_r3         (sw_deb3),
        .i_sw_r4         (sw_deb4),
        .i_sw_r5         (sw_deb5),
        .i_sw_r6         (sw_deb6),
        .i_sw_r7         (sw_deb7),

        .i_clk           (i_clk),
        .i_rstn          (i_rstn));


    wire buzz_s;
    hourminsec_tp u_hourminsec(

        .o_alarm           (buzz_s),

        .o_sec             (sec_range),
        .o_min             (min_range),
        .o_hour            (hour_range),

/*        .o_sec_alm_l    (o_sec_alm_l),
        .o_sec_alm_r    (o_sec_alm_r),

        .o_min_alm_l    (o_min_alm_l),
        .o_min_alm_r    (o_min_alm_r),

        .o_hour_alm_l   (o_hour_alm_l),
        .o_hour_alm_r   (o_hour_alm_r),
*/
        .sec_alm_lcd    (sec_alm_lcd),
        .min_alm_lcd    (min_alm_lcd),
        .hour_alm_lcd   (hour_alm_lcd),

        .o_sec_max_hit     (i_sec_max_hit),
        .o_min_max_hit     (i_min_max_hit),

        .o_sec_max_hit_tim (i_sec_max_hit_tim),
        .o_min_max_hit_tim (i_min_max_hit_tim),

        .o_state_tim       (o_state_tim),

        .i_mode            (mode),
        .i_reset           (reset),
        .i_alarm_en        (alarm_en),

        .i_sec_cnt_clk     (sec_ct),
        .i_min_cnt_clk     (min_ct),
        .i_hour_cnt_clk    (hour_ct),

        .i_sec_alm_clk     (sec_alarm),
        .i_min_alm_clk     (min_alarm),
        .i_hour_alm_clk    (hour_alarm),

        .i_sec_tim_clk     (sec_timer),
        .i_min_tim_clk     (min_timer),
        .i_hour_tim_clk    (hour_timer),

        .i_direct_clk      (direct_clk),
        .i_direct_alm      (direct_alm),
        .i_direct_tim      (direct_tim),

        .i_clk             (i_clk),
        .i_rstn            (i_rstn));

    //sec
    wire [3:0] digit_l_s;
    wire [3:0] digit_r_s;

    num_split #(
        .RANGE (60))
    us_num_split(
        .o_digit_l (digit_l_s),
        .o_digit_r (digit_r_s),
        .i_num (sec_range));

    wire [6:0] seg_l_s;
    dec_to_seg u_dec_to_seg_l_s(
        .o_seg (seg_l_s),
        .i_num (digit_l_s));
    
    wire [6:0] seg_r_s;
    dec_to_seg u_dec_to_seg_r_s(
        .o_seg (seg_r_s),
        .i_num (digit_r_s));

    //min

    wire [3:0] digit_l_m;
    wire [3:0] digit_r_m;
    
    num_split #(
        .RANGE (60))
    um_num_split(
        .o_digit_l (digit_l_m),
        .o_digit_r (digit_r_m),
        .i_num (min_range));

    wire [6:0] seg_l_m;
    dec_to_seg u_dec_to_seg_l_m(
        .o_seg (seg_l_m),
        .i_num (digit_l_m));
    
    wire[6:0] seg_r_m;
    dec_to_seg u_dec_to_seg_r_m(
        .o_seg (seg_r_m),
        .i_num (digit_r_m));
    
    //hour

    wire [3:0] digit_l_h;
    wire [3:0] digit_r_h;

    num_split#(
        .RANGE (24))
    uh_num_split(
        .o_digit_l (digit_l_h),
        .o_digit_r (digit_r_h),
        .i_num (hour_range));

    wire [6:0] seg_l_h;
    dec_to_seg u_dec_to_seg_l_h(
        .o_seg (seg_l_h),
        .i_num (digit_l_h));
 
    wire [6:0] seg_r_h;
    dec_to_seg u_dec_to_seg_r_h(
        .o_seg (seg_r_h),
        .i_num (digit_r_h));

    wire [41:0] six_seg;
    blink u_blink(

        .o_seg_blk    (six_seg),

        .i_seg_l_s    (seg_l_s),
        .i_seg_r_s    (seg_r_s),

        .i_seg_l_m    (seg_l_m),
        .i_seg_r_m    (seg_r_m),

        .i_seg_l_h    (seg_l_h),
        .i_seg_r_h    (seg_r_h),

        .i_mode_b     (mode),
        .i_position_b (position),
        .i_state_b    (o_state),
        .i_clk        (i_clk),
        .i_rstn       (i_rstn));

    led_ctrl #(
        .NCO_NUM_SPEED (NCO_NUM_SPEED))
    u_led_ctrl(
        .o_seg         (o_seg),
        .o_seg_dp      (o_seg_dp),
        .o_seg_enb     (o_seg_enb),

        .i_six_seg     (six_seg),
        .i_six_seg_dp  (6'b010101),

        .i_clk         (i_clk),
        .i_rstn        (i_rstn));

    buzz u_buzz(
        .o_buzz    (o_buzz),

        .i_alm_en  (alarm_en),
        .i_buzz_en (buzz_s),

        .i_clk     (i_clk),
        .i_rstn    (i_rstn));

//alarm lcd display
    num_split #(
        .RANGE (60))
    us_num_split_alm(
        .o_digit_l (o_sec_alm_l),
        .o_digit_r (o_sec_alm_r),
        .i_num     (sec_alm_lcd    ));

    num_split #(
        .RANGE (60))
    um_num_split_alm(
        .o_digit_l (o_min_alm_l),
        .o_digit_r (o_min_alm_r),
        .i_num     (min_alm_lcd    ));

    num_split #(
        .RANGE (24))
    uh_num_split_alm(
        .o_digit_l (o_hour_alm_l),
        .o_digit_r (o_hour_alm_r),
        .i_num     (hour_alm_lcd    ));

    wire [3:0] sec_alm_l;
    wire [3:0] sec_alm_r;

    wire [3:0] min_alm_l;
    wire [3:0] min_alm_r;

    wire [3:0] hour_alm_l;
    wire [3:0] hour_alm_r;

    dec_to_asc u_dec_to_asc_sl(
        .o_asc_num (sec_alm_l),
        .i_dec_num (o_sec_alm_l)
    );

    dec_to_asc u_dec_to_asc_sr(
        .o_asc_num (sec_alm_r),
        .i_dec_num (o_sec_alm_r)
    );

    dec_to_asc u_dec_to_asc_ml(
        .o_asc_num (min_alm_l),
        .i_dec_num (o_min_alm_l)
    );

    dec_to_asc u_dec_to_asc_mr(
        .o_asc_num (min_alm_r),
        .i_dec_num (o_min_alm_r)
    );

    dec_to_asc u_dec_to_as_hl(
        .o_asc_num (hour_alm_l),
        .i_dec_num (o_hour_alm_l)
    );

    dec_to_asc u_dec_to_asc_hr(
        .o_asc_num (hour_alm_r),
        .i_dec_num (o_hour_alm_r)
    );

    reg [15:0] o_alm_en;

    always @(*) begin
        if(!alarm_en) begin
            o_alm_en = 16'h1458;
        end else begin
            o_alm_en = 16'h144F;
        end
    end

    wire [2*16*8-1:0] line_data0;
    wire [2*16*8-1:0] line_data1;
    wire [2*16*8-1:0] line_data2;
    wire [2*16*8-1:0] line_data3;

    assign line_data0 = 256'h1414141414144D4F4445141414141414141414141414434C4F434B1414141414; //MODE_CLOCK
    assign line_data1 = 256'h1414141414144D4F444514141414141414141414145345541455501414141414; //MODE_SETUP
    assign line_data2 = 176'h1414141414144D4F4445141414141414414C41524D14 + hour_alm_l + hour_alm_r + 8'h3A + min_alm_l + min_alm_r + 8'h3A + sec_alm_l + sec_alm_r + o_alm_en; //MODE_ALARM
    assign line_data3 = 256'h1414141414144D4F444514141414141414141414141454494D45521414141414; //MODE_TIMER

    reg [2*16*8-1:0] line_data;
    reg              line_data_vaild;
    always @(*) begin
        case(mode)
           2'b00: begin
            line_data <= line_data0;
            line_data_vaild <= 1;
           end
           2'b01: begin
            line_data <= line_data1;
            line_data_vaild <= 1;
           end
           2'b10: begin
            line_data <= line_data2;
            line_data_vaild <= 1;
           end
           2'b11: begin
            line_data <= line_data3;
            line_data_vaild <= 1;
           end
        endcase
    end

    text_lcd u_text_lcd(

        .o_lcd_e           (o_lcd_e),
        .o_lcd_rs          (o_lcd_rs),
        .o_lcd_rw          (o_lcd_rw),

        .io_lcd_data       (io_lcd_data),

        .i_line_data       (line_data),
        .i_line_data_vaild (line_data_vaild),

        .i_clk             (i_clk),
        .i_rstn            (i_rstn));

endmodule


module dec_to_asc(
    output reg [7:0] o_asc_num,

    input      [3:0]  i_dec_num
);
    always @(*) begin
        case(i_dec_num)
           4'd0: o_asc_num = 8'h30;
           4'd1: o_asc_num = 8'h31;
           4'd2: o_asc_num = 8'h32;
           4'd3: o_asc_num = 8'h33;
           4'd4: o_asc_num = 8'h34;
           4'd5: o_asc_num = 8'h35;
           4'd6: o_asc_num = 8'h36;
           4'd7: o_asc_num = 8'h37;
           4'd8: o_asc_num = 8'h38;
           4'd9: o_asc_num = 8'h39;
        endcase
    end
endmodule