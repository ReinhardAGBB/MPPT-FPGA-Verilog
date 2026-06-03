`timescale 1ns / 1ps

module mppt_controller #(
    
    parameter DATA_WIDTH = 16,          // Lebar bit ADC untuk tegangan dan arus
    parameter DUTY_WIDTH = 16,          // Resolusi duty cycle (contoh 16-bit PWM)
    parameter STEP_SIZE = 16'd50,       // Besar langkah kenaikan/penurunan duty cycle
    parameter MAX_DUTY = 16'd60000,     // Batas atas duty cycle untuk keamanan konverter
    parameter MIN_DUTY = 16'd5000       // Batas bawah duty cycle
)(
    input wire clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] v_adc,  // Data tegangan dari sensor/ADC
    input wire [DATA_WIDTH-1:0] i_adc,  // Data arus dari sensor/ADC
    output reg [DUTY_WIDTH-1:0] duty_cycle
);

    
    localparam STATE_SENSE    = 3'd0;
    localparam STATE_MULTIPLY = 3'd1;
    localparam STATE_COMPARE  = 3'd2;
    localparam STATE_UPDATE   = 3'd3;
    localparam STATE_WAIT     = 3'd4;

    reg [2:0] state;

    
    reg [DATA_WIDTH-1:0] v_current, v_prev;
    reg [DATA_WIDTH-1:0] i_current;
    
    
    reg [(2*DATA_WIDTH)-1:0] p_current, p_prev; 

   
    reg signed [(2*DATA_WIDTH):0] delta_p;
    reg signed [DATA_WIDTH:0] delta_v;

   
    reg [15:0] wait_counter;
    localparam WAIT_LIMIT = 16'd50000; 

    // Blok FSM utama
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Inisialisasi Register saat Reset [cite: 145-147]
            state <= STATE_SENSE;
            duty_cycle <= 16'd32768; // Mulai dari 50% duty cycle
            v_prev <= 0;
            p_prev <= 0;
            wait_counter <= 0;
        end else begin
            case (state)
                STATE_SENSE: begin
                    // STATE 1: Sense (Baca Data ADC) [cite: 155]
                    v_current <= v_adc;
                    i_current <= i_adc;
                    state <= STATE_MULTIPLY;
                end

                STATE_MULTIPLY: begin
                    // STATE 2: Multiply (Hitung Daya menggunakan fixed-point) [cite: 158-160]
                    p_current <= v_current * i_current;
                    state <= STATE_COMPARE;
                end

                STATE_COMPARE: begin
                    // STATE 3: Compare (Logika Inti Perturb & Observe) [cite: 161-163]
                    delta_p = p_current - p_prev;
                    delta_v = v_current - v_prev;

                    if (delta_p != 0) begin
                        if (delta_p > 0) begin
                            if (delta_v > 0) begin
                                // Turunkan Duty Cycle [cite: 153]
                                if (duty_cycle > (MIN_DUTY + STEP_SIZE))
                                    duty_cycle <= duty_cycle - STEP_SIZE;
                            end else begin
                                // Naikkan Duty Cycle [cite: 168]
                                if (duty_cycle < (MAX_DUTY - STEP_SIZE))
                                    duty_cycle <= duty_cycle + STEP_SIZE;
                            end
                        end else begin // delta_p < 0
                            if (delta_v > 0) begin
                                // Naikkan Duty Cycle [cite: 167]
                                if (duty_cycle < (MAX_DUTY - STEP_SIZE))
                                    duty_cycle <= duty_cycle + STEP_SIZE;
                            end else begin
                                // Turunkan Duty Cycle [cite: 171]
                                if (duty_cycle > (MIN_DUTY + STEP_SIZE))
                                    duty_cycle <= duty_cycle - STEP_SIZE;
                            end
                        end
                    end
                    // Jika delta_p == 0, duty_cycle dipertahankan [cite: 148]
                    state <= STATE_UPDATE;
                end

                STATE_UPDATE: begin
                    // STATE 4: Update Memory [cite: 154]
                    p_prev <= p_current;
                    v_prev <= v_current;
                    wait_counter <= 0;
                    state <= STATE_WAIT;
                end

                STATE_WAIT: begin
                    // STATE 5: Wait (Tunggu Timer Sampling) [cite: 169]
                    // Mencegah perubahan duty cycle terlalu cepat mendahului respons konverter
                    if (wait_counter < WAIT_LIMIT) begin
                        wait_counter <= wait_counter + 1;
                    end else begin
                        state <= STATE_SENSE;
                    end
                end

                default: state <= STATE_SENSE;
            endcase
        end
    end
endmodule