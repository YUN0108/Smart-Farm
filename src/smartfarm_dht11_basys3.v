`timescale 1ns / 1ps


module smartfarm_dht11_basys3 #(
    parameter [7:0] WINDOW_OPEN_TEMP_C  = 8'd31,
    parameter [7:0] WINDOW_CLOSE_TEMP_C = 8'd30,
    parameter [6:0] LCD_I2C_ADDR        = 7'h27
)(
    input  wire clk,        // 100MHz
    input  wire btnC,       // reset

    inout  wire dht11,      // DHT11
    input  wire flame,      // flame sensor

    // LCD I2C
    inout  wire i2c_scl,
    inout  wire i2c_sda,

    output wire servo_out,
    output wire sound,
    output wire RsTx,

    output wire fan_ena_pwm,
    output wire fan_in1,
    output wire fan_in2,

    // status LED
    output wire led_dht_error,
    output wire led_i2c_error
);

    // DHT11
    wire [7:0] humidity;
    wire [7:0] temperature;
    wire       data_valid;
    wire       dht_error;

    dht11_reader #(
        .CLK_HZ            (100000000),
        .POWERUP_DELAY_US  (1000000),
        .READ_INTERVAL_US  (2000000)
    ) u_dht11_reader (
        .clk          (clk),
        .rst          (btnC),
        .dht          (dht11),
        .humidity     (humidity),
        .temperature  (temperature),
        .data_valid   (data_valid),
        .error        (dht_error)
    );

    // LCD update
    reg [7:0] last_lcd_temperature;
    reg [7:0] last_lcd_humidity;
    reg       lcd_has_data;
    reg       lcd_update_pulse;

    always @(posedge clk) begin
        if (btnC) begin
            last_lcd_temperature <= 8'd0;
            last_lcd_humidity    <= 8'd0;
            lcd_has_data         <= 1'b0;
            lcd_update_pulse     <= 1'b0;
        end else begin
            lcd_update_pulse <= 1'b0;

            if (data_valid &&
                (!lcd_has_data ||
                 (temperature != last_lcd_temperature) ||
                 (humidity    != last_lcd_humidity))) begin
                last_lcd_temperature <= temperature;
                last_lcd_humidity    <= humidity;
                lcd_has_data         <= 1'b1;
                lcd_update_pulse     <= 1'b1;
            end
        end
    end

    wire i2c_ack_error;

    i2c_lcd_1602 #(
        .CLK_HZ   (100000000),
        .I2C_HZ   (100000),
        .I2C_ADDR (LCD_I2C_ADDR)
    ) u_i2c_lcd_1602 (
        .clk          (clk),
        .rst          (btnC),
        .temperature  (temperature),
        .humidity     (humidity),
        .data_valid   (lcd_update_pulse),
        .ack_error    (i2c_ack_error),
        .i2c_scl      (i2c_scl),
        .i2c_sda      (i2c_sda)
    );

    // latch I2C error
    reg i2c_error_latched;

    always @(posedge clk) begin
        if (btnC)
            i2c_error_latched <= 1'b0;
        else if (i2c_ack_error)
            i2c_error_latched <= 1'b1;
    end

    assign led_dht_error = dht_error;
    assign led_i2c_error = i2c_error_latched;

    // flame sync
    reg flame_meta;
    reg flame_sync;

    always @(posedge clk) begin
        if (btnC) begin
            flame_meta <= 1'b1;
            flame_sync <= 1'b1;
        end else begin
            flame_meta <= flame;
            flame_sync <= flame_meta;
        end
    end

    wire fire_detected = ~flame_sync;

    // window control
    servo_window_control #(
        .CLK_HZ           (100000000),
        .OPEN_TEMP_C      (WINDOW_OPEN_TEMP_C),
        .CLOSE_TEMP_C     (WINDOW_CLOSE_TEMP_C),
        .CLOSED_PULSE_US  (1000),
        .OPEN_PULSE_US    (2000)
    ) u_servo_window_control (
        .clk           (clk),
        .rst           (btnC),
        .valid         (data_valid),
        .temperature   (temperature),
        .force_closed  (fire_detected),
        .servo_pwm     (servo_out)
    );

    // fire alarm
    flame_uart_warning #(
        .CLK_FREQ            (100000000),
        .BAUD_RATE           (9600),
        .FIRE_REPEAT_CYCLES  (100000000),
        .BUZZ_HALF_PERIOD    (20833)
    ) u_flame_uart_warning (
        .clk    (clk),
        .rst    (btnC),
        .flame  (flame),
        .sound  (sound),
        .RsTx   (RsTx)
    );

    // fan control
    l298_humidity_fan_controller #(
        .CLK_FREQ_HZ        (100000000),
        .PWM_FREQ_HZ        (1000),
        .HUM_START_PERCENT  (8'd80),
        .HUM_FULL_PERCENT   (8'd100),
        .MIN_DUTY           (8'd128)
    ) u_l298_humidity_fan_controller (
        .clk             (clk),
        .rst             (btnC),
        .valid           (data_valid && !dht_error),
        .humidity        (humidity),
        .fan_ena_pwm     (fan_ena_pwm),
        .fan_in1         (fan_in1),
        .fan_in2         (fan_in2),
        .fan_duty_debug  ()
    );

endmodule
