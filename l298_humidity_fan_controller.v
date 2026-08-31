`timescale 1ns / 1ps

// fan pwm
// 80% start / 100% full
module l298_humidity_fan_controller #(
    parameter integer CLK_FREQ_HZ       = 100000000,
    parameter integer PWM_FREQ_HZ       = 1000,

    // start humidity
    parameter [7:0] HUM_START_PERCENT   = 8'd80,

    // full duty humidity
    parameter [7:0] HUM_FULL_PERCENT    = 8'd100,

    // min duty
    parameter [7:0] MIN_DUTY            = 8'd128
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       valid,
    input  wire [7:0] humidity,

    output wire       fan_ena_pwm,
    output reg        fan_in1,
    output reg        fan_in2,

    // duty debug
    output reg [7:0]  fan_duty_debug
);

    localparam integer PWM_PERIOD_COUNT = CLK_FREQ_HZ / PWM_FREQ_HZ;

    localparam integer HUM_RANGE_INT =
        (HUM_FULL_PERCENT > HUM_START_PERCENT) ?
        (HUM_FULL_PERCENT - HUM_START_PERCENT) : 1;

    localparam integer DUTY_RANGE_INT = 255 - MIN_DUTY;

    reg [31:0] pwm_count;
    reg [7:0]  fan_duty;
    reg [15:0] duty_calc;

    wire [31:0] pwm_compare;

    // pwm counter
    always @(posedge clk) begin
        if (rst) begin
            pwm_count <= 32'd0;
        end else begin
            if (pwm_count >= PWM_PERIOD_COUNT - 1)
                pwm_count <= 32'd0;
            else
                pwm_count <= pwm_count + 1'b1;
        end
    end

    // duty calc
    always @(*) begin
        fan_duty = 8'd0;
        duty_calc = 16'd0;

        if (!valid) begin
            fan_duty = 8'd0;
        end else if (humidity < HUM_START_PERCENT) begin
            fan_duty = 8'd0;
        end else if (humidity >= HUM_FULL_PERCENT) begin
            fan_duty = 8'hFF;
        end else begin
            duty_calc =
                MIN_DUTY +
                (((humidity - HUM_START_PERCENT) * DUTY_RANGE_INT) / HUM_RANGE_INT);

            fan_duty = duty_calc[7:0];
        end
    end

    // forward only
    always @(*) begin
        if (fan_duty == 8'd0) begin
            fan_in1 = 1'b0;
            fan_in2 = 1'b0;
        end else begin
            fan_in1 = 1'b1;
            fan_in2 = 1'b0;
        end
    end

    always @(*) begin
        fan_duty_debug = fan_duty;
    end

    assign pwm_compare = (PWM_PERIOD_COUNT * fan_duty) >> 8;

    assign fan_ena_pwm =
        (fan_duty == 8'd0)  ? 1'b0 :
        (fan_duty == 8'hFF) ? 1'b1 :
        (pwm_count < pwm_compare);

endmodule
