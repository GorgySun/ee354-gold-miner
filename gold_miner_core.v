


module score_counter 
(
    input wire clk,
    input wire reset,
    input wire update_score,
    input wire [7:0] object_value,

    output reg [15:0] score
);

    always @(posedge clk) 
    begin
        if (reset)
            score <= 16'd0;
        else if (update_score)
            score <= score + object_value;
    end

endmodule


module countdown_timer 
(
    input wire clk,
    input wire reset,
    input wire running,
    input wire second_tick,

    output reg [5:0] seconds_left,
    output wire time_up
);

    always @(posedge clk) 
    begin
        if (reset)
            seconds_left <= 6'd60;
        else if (running && second_tick && seconds_left != 0)
            seconds_left <= seconds_left - 6'd1;
    end

    assign time_up = (seconds_left == 0);

endmodule




module hook_grid 
(
    input  wire [2:0] direction,
    input  wire [4:0] step,

    output reg signed [5:0] hook_col,
    output reg signed [5:0] hook_row,
    output reg        [4:0] max_step
);

    localparam [2:0] FAR_LEFT     = 3'd0;
    localparam [2:0] LEFT         = 3'd1;
    localparam [2:0] SLIGHT_LEFT  = 3'd2;
    localparam [2:0] DOWN         = 3'd3;
    localparam [2:0] SLIGHT_RIGHT = 3'd4;
    localparam [2:0] RIGHT        = 3'd5;
    localparam [2:0] FAR_RIGHT    = 3'd6;

    // Distances in grid cells. half_dist advances every other step.
    wire signed [5:0] dist_cells;
    wire signed [5:0] half_dist;

    assign dist_cells = $signed({1'b0, step});
    assign half_dist  = dist_cells >>> 1;

    always @(*) begin
        case (direction)
            FAR_LEFT: begin
                hook_col = -dist_cells;
                hook_row =  half_dist;
                max_step = 5'd19;
            end

            LEFT: begin
                hook_col = -dist_cells;
                hook_row =  dist_cells;
                max_step = 5'd19;
            end

            SLIGHT_LEFT: begin
                hook_col = -half_dist;
                hook_row =  dist_cells;
                max_step = 5'd24;
            end

            DOWN: begin
                hook_col = 6'sd0;
                hook_row = dist_cells;
                max_step = 5'd24;
            end

            SLIGHT_RIGHT: begin
                hook_col = half_dist;
                hook_row = dist_cells;
                max_step = 5'd24;
            end

            RIGHT: begin
                hook_col = dist_cells;
                hook_row = dist_cells;
                max_step = 5'd19;
            end

            FAR_RIGHT: begin
                hook_col = dist_cells;
                hook_row = half_dist;
                max_step = 5'd19;
            end

            default: begin
                hook_col = 6'sd0;
                hook_row = 6'sd0;
                max_step = 5'd0;
            end
        endcase
    end

endmodule



module hook_controller (
    input wire       clk,
    input wire       reset,
    input wire       move_tick,
    input wire       launch_pulse,
    input wire       hit,
    input wire [3:0] hit_id,       // ID of the object hit, 0 through 9
    input wire [4:0] max_step,     // From hook_grid

    output reg [2:0] direction,
    output reg [4:0] step,
    output reg [9:0] object_available,
    output reg       carrying,
    output reg [3:0] carried_id,
    output reg       delivery_pulse,
    output reg       update_score
);

    localparam [1:0] SWING   = 2'd0,
                     EXTEND  = 2'd1,
                     RETRACT = 2'd2;

    reg [1:0] state;
    reg       swinging_right;

    always @(posedge clk) 
    begin
        if (reset) 
        begin
            state            <= SWING;
            direction        <= 3'd3;
            step             <= 5'd0;
            swinging_right   <= 1'b1;
            object_available <= 10'b1111111111;
            carrying         <= 1'b0;
            carried_id       <= 4'd0;
            delivery_pulse   <= 1'b0;
            update_score     <= 1'b0;
        end
        else 
        begin
            delivery_pulse <= 1'b0;
            update_score   <= 1'b0;

            // After arriving home, score the object once.
            if (delivery_pulse && carrying) 
            begin
                carrying     <= 1'b0;
                update_score <= 1'b1;
            end

            case (state)
                SWING: 
                begin
                    if (launch_pulse) 
                    begin
                        state <= EXTEND;
                    end
                    else if (move_tick) 
                    begin
                        if (direction == 3'd6) 
                        begin
                            direction      <= 3'd5;
                            swinging_right <= 1'b0;
                        end
                        else if (direction == 3'd0) 
                        begin
                            direction      <= 3'd1;
                            swinging_right <= 1'b1;
                        end
                        else if (swinging_right) 
                        begin
                            direction <= direction + 3'd1;
                        end
                        else 
                        begin
                            direction <= direction - 3'd1;
                        end
                    end
                end

                EXTEND: 
                begin
                    if (hit) 
                    begin
                        carried_id               <= hit_id;
                        carrying                 <= 1'b1;
                        object_available[hit_id] <= 1'b0;
                        state                    <= RETRACT;
                    end
                    else if (step == max_step) 
                    begin
                        state <= RETRACT;
                    end
                    else if (move_tick) 
                    begin
                        step <= step + 5'd1;
                    end
                end

                RETRACT: 
                begin
                    if (move_tick) 
                    begin
                        if (step <= 5'd1) 
                        begin
                            step           <= 5'd0;
                            delivery_pulse <= 1'b1;
                            state          <= SWING;
                        end
                        else 
                        begin
                            step <= step - 5'd1;
                        end
                    end
                end

                default: 
                begin
                    state          <= SWING;
                    direction      <= 3'd3;
                    step           <= 5'd0;
                    swinging_right <= 1'b1;
                end
            endcase
        end
    end

endmodule

module level_data (
    input  wire [3:0] object_id,

    output reg              valid,
    output reg signed [5:0] min_col,
    output reg signed [5:0] max_col,
    output reg signed [5:0] min_row,
    output reg signed [5:0] max_row,
    output reg        [7:0] object_value
);

    always @(*) begin
        // IDs outside this level describe an empty slot.
        valid        = 1'b0;
        min_col      = 6'sd0;
        max_col      = 6'sd0;
        min_row      = 6'sd0;
        max_row      = 6'sd0;
        object_value = 8'd0;

        case (object_id)
            4'd0: begin  // Gold directly below the miner
                valid        = 1'b1;
                min_col      = -6'sd1;
                max_col      =  6'sd1;
                min_row      =  6'sd4;
                max_row      =  6'sd5;
                object_value =  8'd50;
            end

            4'd1: begin  // Rock on the left diagonal
                valid        = 1'b1;
                min_col      = -6'sd9;
                max_col      = -6'sd8;
                min_row      =  6'sd8;
                max_row      =  6'sd9;
                object_value =  8'd10;
            end

            4'd2: begin  // Large gold on the far-right path
                valid        = 1'b1;
                min_col      = 6'sd12;
                max_col      = 6'sd15;
                min_row      = 6'sd6;
                max_row      = 6'sd8;
                object_value = 8'd100;
            end

            default: begin
                // Keep the empty-slot values above.
            end
        endcase
    end

endmodule


module collision_detector (
    input  wire signed [5:0] hook_col,
    input  wire signed [5:0] hook_row,
    input  wire        [9:0] object_available,

    output reg               hit,
    output reg         [3:0] hit_id
);

    wire [9:0] object_hit;

    // Check the hook tip against each object's rectangle.
    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) 
        begin
            localparam [3:0] OBJECT_ID = i;

            wire valid;
            wire signed [5:0] min_col, max_col;
            wire signed [5:0] min_row, max_row;

            level_data object_data (
                .object_id    (OBJECT_ID),
                .valid        (valid),
                .min_col      (min_col),
                .max_col      (max_col),
                .min_row      (min_row),
                .max_row      (max_row),
                .object_value ()
            );

            assign object_hit[i] = valid && object_available[i] &&
                                   (hook_col >= min_col) &&
                                   (hook_col <= max_col) &&
                                   (hook_row >= min_row) &&
                                   (hook_row <= max_row);
        end
    endgenerate

    // If objects overlap, pick the lowest matching ID.
    integer id;
    always @(*) begin
        hit    = 1'b0;
        hit_id = 4'd0;

        for (id = 0; id < 10; id = id + 1) begin
            if (object_hit[id] && !hit) begin
                hit    = 1'b1;
                hit_id = id[3:0];
            end
        end
    end

endmodule