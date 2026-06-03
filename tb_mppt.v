`timescale 1ns / 1ps

module tb_mppt();

    reg clk;
    reg rst;
    reg [15:0] v_pv;
    reg [15:0] i_pv;
    wire pwm_out;
    wire [15:0] duty_monitor;
    
    // Variabel untuk mensimulasikan intensitas cahaya matahari
    reg [15:0] iradiasi_max; 

    // Instansiasi Top Module
    mppt_top #(
        .DATA_WIDTH(16),
        .DUTY_WIDTH(16)
    ) UUT (
        .clk(clk),
        .rst(rst),
        .v_adc(v_pv),
        .i_adc(i_pv),
        .pwm_out(pwm_out),
        .duty_monitor(duty_monitor)
    );

    // Generate Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Skenario Simulasi Dinamis (Dipercepat 20ms)
    initial begin
        $dumpfile("mppt_sim.vcd");
        $dumpvars(0, tb_mppt);

        rst = 1;
        v_pv = 0;
        i_pv = 0;
        
        // Kondisi Tunak: Iradiasi tinggi (1000)
        iradiasi_max = 16'd1000; 
        
        #100;
        rst = 0; 

        // Fase 1: Cari MPP selama 10 milidetik (10.000.000 ns)
        #10000000;
        
        // Fase 2: Kondisi Dinamis, iradiasi anjlok persis di 10ms
        $display("Waktu 10ms: Iradiasi turun mendadak ke 600!");
        iradiasi_max = 16'd600; 

        // Fase 3: Cari MPP baru selama 10 milidetik
        #10000000;
        
        $display("Simulasi Selesai di 20ms!");
        $finish;
    end

    // Pemodelan Kurva PV yang merespons perubahan iradiasi
    always @(posedge clk) begin
        if (!rst) begin
            if (iradiasi_max > (duty_monitor / 65))
                v_pv = iradiasi_max - (duty_monitor / 65);
            else
                v_pv = 0;

            if (v_pv < iradiasi_max)
                i_pv = iradiasi_max - v_pv;
            else
                i_pv = 0;
        end
    end

endmodule