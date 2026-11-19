`timescale 1ns / 1ps

module tb_gold_miner_top;

    reg clk          = 0;
    reg reset        = 1;
    reg launch_pulse = 0;
    reg move_tick    = 0;

    wire signed [5:0] hook_col;
    wire signed [5:0] hook_row;
    wire              carrying;
    wire       [15:0] score;

    gold_miner_top dut (
        .clk          (clk),
        .reset        (reset),
        .launch_pulse (launch_pulse),
        .move_tick    (move_tick),
        .hook_col     (hook_col),
        .hook_row     (hook_row),
        .carrying     (carrying),
        .score        (score)
    );

    always #5 clk = ~clk;  // 10 ns clock period

    // One movement tick, followed by one clock for collision detection.
    task move_once;
        begin
            move_tick = 1;
            @(negedge clk);
            move_tick = 0;
            @(negedge clk);
        end
    endtask

    initial begin
        // Reset points the hook straight down. Launch before it swings.
        repeat (2) @(negedge clk);
        reset = 0;
        launch_pulse = 1;
        @(negedge clk);
        launch_pulse = 0;

        // Extend four cells to the gold.
        repeat (4) move_once();

        if (hook_col !== 0 || hook_row !== 4 ||
            carrying !== 1'b1 || score !== 0) begin
            $display("FAIL pickup: col=%0d row=%0d carrying=%b score=%0d",
                     hook_col, hook_row, carrying, score);
            $finish;
        end

        // Retract four cells and let the score counter process delivery.
        repeat (4) move_once();
        repeat (2) @(negedge clk);

        if (hook_col !== 0 || hook_row !== 0 ||
            carrying !== 1'b0 || score !== 50)
            $display("FAIL delivery: col=%0d row=%0d carrying=%b score=%0d",
                     hook_col, hook_row, carrying, score);
        else
            $display("PASS: picked up gold at (0,4), returned home, scored 50");

        $finish;
    end

endmodule