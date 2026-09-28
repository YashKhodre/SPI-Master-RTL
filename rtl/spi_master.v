module spi_master #(
    parameter integer CLK_DIV = 10
) (
    input clk,
    input reset,
    input start,
    input [7:0] tx_data,
    input miso,

    output reg mosi,
    output reg sclk,
    output reg cs,
    output reg [7:0] rx_data,
    output reg done
    
);

localparam IDLE = 2'b00;
localparam LOAD = 2'b01;
localparam TRANSFER = 2'b10;
localparam DONE = 2'b11;

reg [1:0] state;
reg [1:0] next_state;

reg [7:0] tx_shift_reg;
reg [7:0] rx_shift_reg;
reg [2:0] bit_count;


reg [7:0] clk_div_counter;
reg spi_tick;
reg transfer_done;

always @(posedge clk) begin
    if(reset) begin
        clk_div_counter <= 8'd0;
        spi_tick <= 1'b0;
    end

    else begin
        if (clk_div_counter == CLK_DIV - 1) begin
            clk_div_counter <= 8'd0;
            spi_tick <= 1'b1;
        end

        else begin
            clk_div_counter <= clk_div_counter + 1;
            spi_tick <= 1'b0;
        end
    end
end

always @(posedge clk) begin

    if (reset) begin
        state        <= IDLE;
        tx_shift_reg <= 8'd0;
        rx_shift_reg <= 8'd0;
        bit_count    <= 3'd0;
        mosi         <= 1'b0;
        sclk         <= 1'b0;
        cs           <= 1'b1;
        rx_data      <= 8'd0;
        done         <= 1'b0;
        transfer_done <= 1'b0;

    end

    else begin
        state <= next_state;

        if (state == LOAD) begin

            tx_shift_reg   <= tx_data;
            rx_shift_reg   <= 8'd0;
            bit_count      <= 3'd0;
            cs             <= 1'b0;
            sclk           <= 1'b0;
            mosi           <= tx_data[7];
            transfer_done  <= 1'b0;
        end

        if (state == TRANSFER) begin
            if(spi_tick) begin
                if (sclk == 1'b1) begin
            
            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
            mosi <= tx_shift_reg[6];
        end

        else begin

            if (bit_count ==3'd7) begin

                rx_shift_reg <= {rx_shift_reg[6:0], miso};
                rx_data <= {rx_shift_reg[6:0], miso};
                transfer_done <= 1'b1;
                bit_count <= 3'd0;
            end

                 else begin
                    rx_shift_reg <= {rx_shift_reg[6:0], miso};
                    bit_count <= bit_count + 3'd1;
                 end
        end 
                sclk <= ~sclk;
            end
        end

        if (state == DONE) begin 
            cs <= 1'b1;
            sclk <= 1'b0;
            mosi <= 1'b0;
            done <= 1'b1;
        end

        if (state == IDLE) begin 
            done <= 1'b0;
        end
    end
end


always @(*) begin

    next_state = state;

    case(state)

    IDLE: begin
        if(start) begin
            next_state = LOAD;
        end
            else begin
            next_state = IDLE;
            end
    end

    LOAD: begin
        next_state = TRANSFER;
    end

    TRANSFER: begin
        if (transfer_done)
        next_state = DONE;
        else
        next_state = TRANSFER;
    end 

    DONE: begin 
        next_state = IDLE;
    end 
    endcase
end 
        
endmodule