`timescale 1ns / 1ps

module mppt_top #(
    parameter DATA_WIDTH = 16,
    parameter DUTY_WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] v_adc,  // Input tegangan digital dari testbench/sensor
    input wire [DATA_WIDTH-1:0] i_adc,  // Input arus digital dari testbench/sensor
    output wire pwm_out,                 // Output sinyal PWM fisik ke gate driver
    output wire [DUTY_WIDTH-1:0] duty_monitor // Port tambahan untuk memantau pergerakan nilai duty cycle saat simulasi
);

    wire [DUTY_WIDTH-1:0] internal_duty;

    mppt_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .DUTY_WIDTH(DUTY_WIDTH)
    ) u_mppt_core (
        .clk(clk),
        .rst(rst),
        .v_adc(v_adc),
        .i_adc(i_adc),
        .duty_cycle(internal_duty)
    );

    pwm_generator #(
        .DUTY_WIDTH(DUTY_WIDTH)
    ) u_pwm_gen (
        .clk(clk),
        .rst(rst),
        .duty_cycle(internal_duty),
        .pwm_out(pwm_out)
    );

    assign duty_monitor = internal_duty;

endmodule
