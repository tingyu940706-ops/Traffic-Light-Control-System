`timescale 1ns/1ps
`include "traffic_light.v"

module tb;

reg clk;
reg reset;
reg enable;

wire [2:0] ns_light;
wire [2:0] ew_light;
wire       ped_light;
wire [2:0] state;
wire [7:0] timer_count;

integer error_count;
integer pass_count;

//==============================================================
// DUT Instantiation
//==============================================================
traffic_light UUT (
    .clk(clk),
    .reset(reset),
    .enable(enable),
    .ns_light(ns_light),
    .ew_light(ew_light),
    .ped_light(ped_light),
    .state(state),
    .timer_count(timer_count)
);

//==============================================================
// Clock Generation
//==============================================================
initial begin

// waveform dump
		
        $dumpfile("traffic01.vcd");
        $dumpvars(0, tb);
		
		
    clk = 1'b0;
end

always #5 clk = ~clk;

//==============================================================
// Expected Output Checker
//==============================================================
task check_output;
    input [2:0] exp_state;
    input [2:0] exp_ns;
    input [2:0] exp_ew;
    input       exp_ped;
    begin
        #1;
        if (state !== exp_state ||
            ns_light !== exp_ns ||
            ew_light !== exp_ew ||
            ped_light !== exp_ped) begin

            error_count = error_count + 1;
            $display("[ERROR] time=%0t state=%0d exp_state=%0d NS=%b exp_NS=%b EW=%b exp_EW=%b PED=%b exp_PED=%b timer=%0d",
                     $time, state, exp_state,
                     ns_light, exp_ns,
                     ew_light, exp_ew,
                     ped_light, exp_ped,
                     timer_count);
        end
        else begin
            pass_count = pass_count + 1;
            $display("[PASS ] time=%0t state=%0d NS=%b EW=%b PED=%b timer=%0d",
                     $time, state, ns_light, ew_light, ped_light, timer_count);
        end
    end
endtask

//==============================================================
// Main Test Flow
//==============================================================
initial begin
    $fsdbDumpfile("traffic_light.fsdb");
    $fsdbDumpvars(0, tb);

    error_count = 0;
    pass_count  = 0;

    reset  = 1'b1;
    enable = 1'b0;

    //==========================================================
    // Test 1: Reset behavior
    //==========================================================
    #20;
    check_output(3'd0, 3'b001, 3'b100, 1'b0);

    reset  = 1'b0;
    enable = 1'b1;

    //==========================================================
	// Test 2: Normal FSM sequence
	// design updates at negedge clk ---use @(negedge clk)
    //==========================================================

    // S0: NS green, EW red, pedestrian off
    repeat (21) @(negedge clk);
    check_output(3'd1, 3'b010, 3'b100, 1'b0);

    // S1: NS yellow, EW red, pedestrian off
    repeat (6) @(negedge clk);
    check_output(3'd2, 3'b100, 3'b001, 1'b0);

    // S2: NS red, EW green, pedestrian off
    repeat (16) @(negedge clk);
    check_output(3'd3, 3'b100, 3'b010, 1'b0);

    // S3: NS red, EW yellow, pedestrian off
    repeat (6) @(negedge clk);
    check_output(3'd4, 3'b100, 3'b100, 1'b1);

    // S4: all vehicle red, pedestrian walk
    repeat (11) @(negedge clk);
    check_output(3'd5, 3'b100, 3'b100, 1'b0);

    // S5: all red clearance, pedestrian off
    repeat (4) @(negedge clk);
    check_output(3'd0, 3'b001, 3'b100, 1'b0);

    //==========================================================
    // Test 3: Enable pause function
    //==========================================================
    enable = 1'b0;
    repeat (5) @(negedge clk);

    // when enable = 0, FSM should stay at S0
	// timer should stop counting and state should not change
    check_output(3'd0, 3'b001, 3'b100, 1'b0);

    enable = 1'b1;

    //==========================================================
    // Test 4: Reset during operation
    //==========================================================
    repeat (8) @(negedge clk);
    reset = 1'b1;
    #10;
    check_output(3'd0, 3'b001, 3'b100, 1'b0);

    reset = 1'b0;
    enable = 1'b1;

    //==========================================================
    // Final Summary
    //==========================================================
    #20;
    $display("==============================================");
    $display("Traffic Light Controller Verification Summary");
    $display("PASS  = %0d", pass_count);
    $display("ERROR = %0d", error_count);

    if (error_count == 0)
	begin
		$display("==============================================================");
        $display("                 🎉  Simulation Finish ! 🎉");
        $display("==============================================================");
        $display("*******************************************************");
        $display("**                                                   **");
        $display("**                Congratulations !!                 **");
        $display("**                 All test passed!!                   **");
        $display("**                                                   **");
        $display("**************************************************************");
        $display("");
        $display("⠀⠀⠀⠀⠀⠀⠀⠀       ⠀⠀⠀⠀⢀⣤⣤⣄⠀⣀⣀⣀⠀⠀⠀⠀");
        $display("⠀⠀⠀       ⣴⠟⠛⠓⠶⣤⠴⠶⢶⡿⠁⣶⣽⣯⠉⠁⠹⡆⠀⠀⠀");
        $display("⠀⠀       ⠀⣿⠀⠀⠀⠀⠀⠀⠀⢸⡁⢼⣿⡏⠙⠻⣾⡛⢿⣆⠀⠀");
        $display("⠀⠀       ⠀⣻⠋⠀⠀⠀⠀⠀⠀⠈⠓⠶⠞⠷⣤⣼⣯⠟⣸⡟⠀⠀");
        $display("⠀       ⠀⢸⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⠶⠞⢙⣆⣀⠀");
        $display("       ⢠⡶⢾⡶⠤⠀⢠⣤⠀⠀⠀⠀⠀⠀⠀⠀⣤⡄⠀⠚⢩⡏⠉⠁");
        $display("⠀       ⢀⣼⣷⠒⠀⠈⠋⠀⠀⠀⢶⡲⠀⠀⠀⠛⠁⠀⡈⣹⠛⠛⠀");
        $display("⠀       ⠀⢠⡼⠷⣯⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠿⠛⠷⠆⠀");
        $display("       ⠀⠀⠈⠀⠀⠀⠉⠙⠓⠒⠶⠶⠶⠶⠒⠚⠛⠉⠁⠀⠀⠀⠀⠀");
        $display("");
        $display("==============================================================");
	end
    else
	begin
		$display("-----------------------------------------------------");
        $display("     [!] Some tests failed.                         ");
        $display("     Keep going! Please check your logic carefully. ");
        $display("     You've got this, don't give up!                ");
        $display("-----------------------------------------------------");


    $finish;
	end
end

endmodule
