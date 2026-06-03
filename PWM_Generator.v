`timescale 1ns / 1ps

module pwm_generator #(
    parameter DUTY_WIDTH = 16 
)(
    input wire clk,
    input wire rst,
    input wire [DUTY_WIDTH-1:0] duty_cycle, // Menerima nilai dari FSM MPPT
    output reg pwm_out                      // Sinyal keluaran fisik
);

    reg [DUTY_WIDTH-1:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            pwm_out <= 0;
        end else begin
            counter <= counter + 1;
            
            if (counter < duty_cycle)
                pwm_out <= 1'b1; 
            else
                pwm_out <= 1'b0; 
        end
    end

endmodule