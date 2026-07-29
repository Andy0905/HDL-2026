`timescale 1ns / 1ps

module tb_smart_traffic_controller();

    reg clk;
    reg rst;
    reg ped_request;
    reg school_zone;

    wire [2:0] main_light;
    wire [2:0] side_light;
    wire ped_walk;
    wire speed_warning;

    smart_traffic_controller uut (
        .clk(clk),
        .rst(rst),
        .ped_request(ped_request),
        .school_zone(school_zone),
        .main_light(main_light),
        .side_light(side_light),
        .ped_walk(ped_walk),
        .speed_warning(speed_warning)
    );

    // 10ns Clock Period
    always #5 clk = ~clk;

    initial begin
        $dumpfile("traffic_sim.vcd");
        $dumpvars(0, tb_smart_traffic_controller);

        clk = 0;
        rst = 0;
        ped_request = 0;
        school_zone = 0;

        // TC1: Reset
        $display("=== TC1: System Reset ===");
        #2 rst = 1;
        #10 rst = 0;

        // TC2: Normal Operation (No School Zone)
        $display("=== TC2: Standard Cycle ===");
        #160;

        // TC3: Pedestrian Request during Normal Mode (Walk = 4 Cycles)
        $display("=== TC3: Pedestrian Request (Standard Mode) ===");
        #10 ped_request = 1;
        #10 ped_request = 0;
        #100;

        // TC4: Activate School Zone Mode (Walk = 8 Cycles + Speed Warning ON)
        $display("=== TC4: Activating School Zone Mode ===");
        school_zone = 1;
        #20;
        ped_request = 1;
        #10 ped_request = 0;
        #160;

        // TC5: Reset during Active School Zone Walk Phase (Edge Case)
        $display("=== TC5: Edge Case - Reset during Active Pedestrian Phase ===");
        #10 ped_request = 1;
        #10 ped_request = 0;
        #25;
        rst = 1;
        #10 rst = 0;
        #60;

        $display("=== Simulation Finished ===");
        $finish;
    end

    initial begin
        $monitor("[Time %0t ns] State: Main=%b | Side=%b | Ped_Walk=%b | SchoolZone=%b | Warning=%b", 
                 $time, main_light, side_light, ped_walk, school_zone, speed_warning);
    end

endmodule