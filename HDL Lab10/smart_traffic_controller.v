// Module: smart_traffic_controller
// Description: School-Zone Smart Intersection Controller with school_zone input mode

module smart_traffic_controller (
    input wire clk,
    input wire rst,
    input wire ped_request,
    input wire school_zone,     // Active high when school zone active hours are ON
    output reg [2:0] main_light, // Bit 2 = Green, Bit 1 = Yellow, Bit 0 = Red
    output reg [2:0] side_light, // Bit 2 = Green, Bit 1 = Yellow, Bit 0 = Red
    output reg ped_walk,
    output reg speed_warning    // Active high signal for school zone warning lights
);

    // State Encoding
    localparam S_MAIN_GREEN  = 3'b000;
    localparam S_MAIN_YELLOW = 3'b001;
    localparam S_PED_WALK    = 3'b010;
    localparam S_SIDE_GREEN  = 3'b011;
    localparam S_SIDE_YELLOW = 3'b100;

    // Light Encodings [G, Y, R]
    localparam LIGHT_GREEN  = 3'b100;
    localparam LIGHT_YELLOW = 3'b010;
    localparam LIGHT_RED    = 3'b001;

    // Timing Constants
    localparam TIME_MAIN_GREEN  = 5;
    localparam TIME_MAIN_YELLOW = 2;
    localparam TIME_PED_NORMAL  = 4; // Standard walk duration
    localparam TIME_PED_SCHOOL  = 8; // Extended walk duration for students
    localparam TIME_SIDE_GREEN  = 3;
    localparam TIME_SIDE_YELLOW = 2;

    reg [2:0] current_state, next_state;
    reg [3:0] timer;
    reg ped_latched;

    // 1. Pedestrian Request Latch
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ped_latched <= 1'b0;
        end else begin
            if (ped_request)
                ped_latched <= 1'b1;
            else if (current_state == S_PED_WALK)
                ped_latched <= 1'b0;
        end
    end

    // 2. Sequential State Register & Timer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= S_MAIN_GREEN;
            timer <= 0;
        end else begin
            if (current_state != next_state) begin
                current_state <= next_state;
                timer <= 0;
            end else begin
                timer <= timer + 1'b1;
            end
        end
    end

    // 3. Next State Combinational Logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            S_MAIN_GREEN: begin
                if (timer >= TIME_MAIN_GREEN - 1 || ped_latched || ped_request)
                    next_state = S_MAIN_YELLOW;
            end

            S_MAIN_YELLOW: begin
                if (timer >= TIME_MAIN_YELLOW - 1) begin
                    if (ped_latched || ped_request)
                        next_state = S_PED_WALK;
                    else
                        next_state = S_SIDE_GREEN;
                end
            end

            S_PED_WALK: begin
                // Dynamically select walk timer threshold based on school_zone signal
                if (school_zone) begin
                    if (timer >= TIME_PED_SCHOOL - 1)
                        next_state = S_SIDE_GREEN;
                end else begin
                    if (timer >= TIME_PED_NORMAL - 1)
                        next_state = S_SIDE_GREEN;
                end
            end

            S_SIDE_GREEN: begin
                if (timer >= TIME_SIDE_GREEN - 1)
                    next_state = S_SIDE_YELLOW;
            end

            S_SIDE_YELLOW: begin
                if (timer >= TIME_SIDE_YELLOW - 1)
                    next_state = S_MAIN_GREEN;
            end

            default: next_state = S_MAIN_GREEN;
        endcase
    end

    // 4. Output Combinational Logic
    always @(*) begin
        main_light    = LIGHT_RED;
        side_light    = LIGHT_RED;
        ped_walk      = 1'b0;
        speed_warning = school_zone; // Speed warning active whenever school_zone=1

        case (current_state)
            S_MAIN_GREEN: begin
                main_light = LIGHT_GREEN;
                side_light = LIGHT_RED;
                ped_walk   = 1'b0;
            end
            S_MAIN_YELLOW: begin
                main_light = LIGHT_YELLOW;
                side_light = LIGHT_RED;
                ped_walk   = 1'b0;
            end
            S_PED_WALK: begin
                main_light = LIGHT_RED;
                side_light = LIGHT_RED;
                ped_walk   = 1'b1;
            end
            S_SIDE_GREEN: begin
                main_light = LIGHT_RED;
                side_light = LIGHT_GREEN;
                ped_walk   = 1'b0;
            end
            S_SIDE_YELLOW: begin
                main_light = LIGHT_RED;
                side_light = LIGHT_YELLOW;
                ped_walk   = 1'b0;
            end
        endcase
    end

endmodule