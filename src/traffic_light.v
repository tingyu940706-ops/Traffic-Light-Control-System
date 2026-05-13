//==============================================================
// Design: Campus Crosswalk Traffic Light Controller
// Type: 6-state Moore FSM + Synchronous Down Counter
//==============================================================
`timescale 1ns/1ps
module traffic_light (
    clk,
    reset,
    enable,
    ns_light,
    ew_light,
    ped_light,
    state,
    timer_count
);

//==============================================================
// 1. I/O Declaration
//==============================================================

input clk;
input reset;
input enable;

// 3-bit light encoding: {Red, Yellow, Green}
output reg [2:0] ns_light;
output reg [2:0] ew_light;

// pedestrian light: 1 = walk, 0 = off
output reg ped_light;

// debug signals for waveform and report
output reg [2:0] state;
output reg [7:0] timer_count;

//==============================================================
// 2. Light Encoding
//==============================================================

parameter RED    = 3'b100;
parameter YELLOW = 3'b010;
parameter GREEN  = 3'b001;

//==============================================================
// 3. State Encoding
//==============================================================

parameter S0 = 3'd0; //NS_GREEN
parameter S1 = 3'd1; //NS_YELLOW
parameter S2 = 3'd2; //EW_GREEN
parameter S3 = 3'd3; //EW_YELLOW
parameter S4 = 3'd4; //PED_WALK
parameter S5 = 3'd5; //CLEARANCE

//==============================================================
// 4. Timer Duration
//==============================================================


parameter T_NS_GREEN   = 8'd20;
parameter T_NS_YELLOW  = 8'd5;
parameter T_EW_GREEN   = 8'd15;
parameter T_EW_YELLOW  = 8'd5;
parameter T_PED_WALK   = 8'd10;
parameter T_CLEARANCE  = 8'd3;

//==============================================================
// 5. Internal Signals
//==============================================================

reg [2:0] next_state;
reg [7:0] load_value; //The load value for the next state's timer

wire timer_done;

assign timer_done = (timer_count == 8'd0);

//==============================================================
// 6. State Register + Synchronous Down Counter
//==============================================================
// use <= in sequential block
// state and timer_count only update here
// don't change them in other always blocks



always @(negedge clk or posedge reset)
begin
    if (reset) //when reset,back to S0
    begin
        state       <= S0;
        timer_count <= T_NS_GREEN;
    end
    else if (enable) //when enable=1 ,timer countdown every clk
    begin
        if (timer_done)//timer_count=0,then change to next_state
        begin
            state       <= next_state;
            timer_count <= load_value;
        end
        else //timer maintain before timer_count=0
        begin
            state       <= state;
            timer_count <= timer_count - 8'd1;
        end
    end
    else
    begin //count_enable's pause function
        state       <= state;
        timer_count <= timer_count;
    end
end

//==============================================================
// 7. Next-State Logic
//==============================================================
// combinational block uses =
// give default values first to avoid latch

always @(*)//recount when state change
begin
    next_state = state; //maintain at the original state
    load_value = T_NS_GREEN;//default load S0 state

    case (state)

        S0:
        begin
            next_state = S1;
            load_value = T_NS_YELLOW;
        end

        S1:
        begin
            next_state = S2;
            load_value = T_EW_GREEN;
        end

        S2:
        begin
            next_state = S3;
            load_value = T_EW_YELLOW;
        end

        S3:
        begin
            next_state = S4;
            load_value = T_PED_WALK;
        end

        S4:
        begin
            next_state = S5;
            load_value = T_CLEARANCE;
        end

        S5:
        begin
            next_state = S0;
            load_value = T_NS_GREEN;
        end

        default:
        begin
            next_state = S0;
            load_value = T_NS_GREEN;
        end

    endcase
end

//==============================================================
// 8. Output Decoder
//==============================================================
// Moore FSM: output only depends on state
// don't use enable or timer_count here

always @(*)
begin
    // default safe condition
    ns_light  = RED;
    ew_light  = RED;
    ped_light = 1'b0;

    case (state)

        S0:
        begin
            ns_light  = GREEN;
            ew_light  = RED;
            ped_light = 1'b0;
        end

        S1:
        begin
            ns_light  = YELLOW;
            ew_light  = RED;
            ped_light = 1'b0;
        end

        S2:
        begin
            ns_light  = RED;
            ew_light  = GREEN;
            ped_light = 1'b0;
        end

        S3:
        begin
            ns_light  = RED;
            ew_light  = YELLOW;
            ped_light = 1'b0;
        end

        S4:
        begin
            ns_light  = RED;
            ew_light  = RED;
            ped_light = 1'b1;
        end

        S5:
        begin
            ns_light  = RED;
            ew_light  = RED;
            ped_light = 1'b0;
        end

        default:
        begin
            ns_light  = RED;
            ew_light  = RED;
            ped_light = 1'b0;
        end

    endcase
end

endmodule
