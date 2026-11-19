module gold_miner_top (
    input  wire              clk,
    input  wire              reset,
    input  wire              launch_pulse,
    input  wire              move_tick,

    output wire signed [5:0] hook_col,
    output wire signed [5:0] hook_row,
    output wire              carrying,
    output wire       [15:0] score
);

    wire [2:0] direction;
    wire [4:0] step;
    wire [4:0] max_step;

    wire [9:0] object_available;
    wire       hit;
    wire [3:0] hit_id;
    wire [3:0] carried_id;

    wire       update_score;
    wire [7:0] object_value;

    hook_controller controller (
        .clk              (clk),
        .reset            (reset),
        .move_tick        (move_tick),
        .launch_pulse     (launch_pulse),
        .hit              (hit),
        .hit_id           (hit_id),
        .max_step         (max_step),
        .direction        (direction),
        .step             (step),
        .object_available (object_available),
        .carrying         (carrying),
        .carried_id       (carried_id),
        .delivery_pulse   (),
        .update_score     (update_score)
    );

    hook_grid grid (
        .direction (direction),
        .step      (step),
        .hook_col  (hook_col),
        .hook_row  (hook_row),
        .max_step  (max_step)
    );

    collision_detector detector (
        .hook_col         (hook_col),
        .hook_row         (hook_row),
        .object_available (object_available),
        .hit              (hit),
        .hit_id           (hit_id)
    );

    // Look up the point value of the object being carried.
    level_data carried_object (
        .object_id    (carried_id),
        .valid        (),
        .min_col      (),
        .max_col      (),
        .min_row      (),
        .max_row      (),
        .object_value (object_value)
    );

    score_counter points (
        .clk          (clk),
        .reset        (reset),
        .update_score (update_score),
        .object_value (object_value),
        .score        (score)
    );

endmodule