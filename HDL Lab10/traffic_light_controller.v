`timescale 1ns / 1ps

module traffic_light_controller (
    input wire clk,
    input wire reset,
    input wire ped_request,
    output reg [1:0] main_light, // 2'b10=Green, 2'b01=Yellow, 2'b00=Red
    output reg [1:0] side_light, // 2'b10=Green, 2'b01=Yellow, 2'b00=Red
    output reg walk_light        // Challenge Activity: On during side-green
);

    // Light encoding parameters
    parameter RED    = 2'b00,
              YELLOW = 2'b01,
              GREEN  = 2'b10;

    // FSM State Encoding
    parameter S_MAIN_GREEN  = 2'b00,
              S_MAIN_YELLOW = 2'b01,
              S_SIDE_GREEN  = 2'b10,
              S_SIDE_YELLOW = 2'b11;

    // Timing Intervals (in clock cycles)
    parameter TIME_MAIN_GREEN_NORMAL = 8,
              TIME_MAIN_GREEN_PED    = 3, // Shortened when ped_request is 1
              TIME_YELLOW            = 2,
              TIME_SIDE_GREEN        = 5;

    reg [1:0] state, next_state;
    reg [3:0] timer;

    // 1. Sequential State Register & Timer Counter
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_MAIN_GREEN;
            timer <= 4'd0;
        end else begin
            if (state != next_state) begin
                state <= next_state;
                timer <= 4'd0; // Reset timer on state transition
            end else begin
                timer <= timer + 1'b1;
            end
        end
    end

    // 2. Next-State Combinational Logic
    always @(*) begin
        case (state)
            S_MAIN_GREEN: begin
                // ped_request shortens main-green interval
                if (ped_request && timer >= (TIME_MAIN_GREEN_PED - 1))
                    next_state = S_MAIN_YELLOW;
                else if (timer >= (TIME_MAIN_GREEN_NORMAL - 1))
                    next_state = S_MAIN_YELLOW;
                else
                    next_state = S_MAIN_GREEN;
            end

            S_MAIN_YELLOW: begin
                if (timer >= (TIME_YELLOW - 1))
                    next_state = S_SIDE_GREEN;
                else
                    next_state = S_MAIN_YELLOW;
            end

            S_SIDE_GREEN: begin
                if (timer >= (TIME_SIDE_GREEN - 1))
                    next_state = S_SIDE_YELLOW;
                else
                    next_state = S_SIDE_GREEN;
            end

            S_SIDE_YELLOW: begin
                if (timer >= (TIME_YELLOW - 1))
                    next_state = S_MAIN_GREEN;
                else
                    next_state = S_SIDE_YELLOW;
            end

            default: next_state = S_MAIN_GREEN;
        endcase
    end

    // 3. Moore Output Logic
    always @(*) begin
        // Default outputs
        main_light = RED;
        side_light = RED;
        walk_light = 1'b0;

        case (state)
            S_MAIN_GREEN: begin
                main_light = GREEN;
                side_light = RED;
                walk_light = 1'b0;
            end

            S_MAIN_YELLOW: begin
                main_light = YELLOW;
                side_light = RED;
                walk_light = 1'b0;
            end

            S_SIDE_GREEN: begin
                main_light = RED;
                side_light = GREEN;
                walk_light = 1'b1; // Walk light turns on ONLY during side-green
            end

            S_SIDE_YELLOW: begin
                main_light = RED;
                side_light = YELLOW;
                walk_light = 1'b0;
            end

            default: begin
                main_light = RED;
                side_light = RED;
                walk_light = 1'b0;
            end
        endcase
    end

endmodule
