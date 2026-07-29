`timescale 1ns / 1ps

module tb_traffic_light_controller;

    reg clk;
    reg reset;
    reg ped_request;
    wire [1:0] main_light;
    wire [1:0] side_light;
    wire walk_light;

    // Instantiate Unit Under Test (UUT)
    traffic_light_controller uut (
        .clk(clk),
        .reset(reset),
        .ped_request(ped_request),
        .main_light(main_light),
        .side_light(side_light),
        .walk_light(walk_light)
    );

    // Clock Generation (10ns period)
    always #5 clk = ~clk;

    initial begin
        // VCD Dump Setup
        $dumpfile("lab10_traffic_light.vcd");
        $dumpvars(0, tb_traffic_light_controller);

        // Initialize signals
        clk = 0;
        reset = 1;
        ped_request = 0;

        // Apply Reset
        #15 reset = 0;

        // Run full normal cycle without ped_request
        #200;

        // Assert Pedestrian Request during Main Green
        ped_request = 1;
        #20;
        ped_request = 0;

        // Finish simulation at required timestamp
        #57;
        $finish;
    end

endmodule