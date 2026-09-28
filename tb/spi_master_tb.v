`timescale 1ns/1ps

module spi_master_tb;

    reg clk;
    reg reset;

    reg start;
    reg [7:0] tx_data;
    reg miso;
    //spi slave model
    reg [7:0] slave_tx_data;
    reg [2:0] slave_bit_count;

    wire mosi;
    wire sclk;
    wire cs;
    wire [7:0] rx_data;
    wire done;

    spi_master #(
        .CLK_DIV(10)
    ) uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .tx_data(tx_data),
        .miso(miso),

        .mosi(mosi),
        .sclk(sclk),
        .cs(cs),
        .rx_data(rx_data),
        .done(done)
    );

    always #5 clk = ~clk;

    always @(negedge cs) begin

    slave_bit_count = 3'd0;
    miso = slave_tx_data[7];

    end

    always @(negedge sclk) begin

        if (!cs) begin 

            if (slave_bit_count < 3'd7) begin 

                slave_bit_count = slave_bit_count + 3'd1;
                miso = slave_tx_data[7 - slave_bit_count];

            end 
            else begin
                miso = 1'b0;
            end 
        end
    end

    task spi_transfer;
    input [7:0] master_data;
    input [7:0] slave_data;

    begin

        tx_data = master_data;
        slave_tx_data = slave_data;

        start = 1'b1;

        @(posedge clk);

        start = 1'b0;

        @(posedge done);

        if(rx_data == slave_data) begin 
            $display("======================================");
            $display("SPI TEST PASSED");
            $display("TX DATA     = %h", master_data);
            $display("EXPECTED RX = %h", slave_data);
            $display("ACTUAL RX   = %h", rx_data);
            $display("======================================");
        end

        else begin 
            $display("======================================");
            $display("SPI TEST FAILED");
            $display("TX DATA     = %h", master_data);
            $display("EXPECTED RX = %h", slave_data);
            $display("ACTUAL RX   = %h", rx_data);
            $display("======================================");
        end

        // Give DUT time to return to IDLE
        repeat (2) @(posedge clk);
    end
    endtask


   
    initial begin

        $dumpfile("waveforms/spi_master.vcd");
        $dumpvars(0, spi_master_tb);

        clk     = 1'b0; 
        reset   = 1'b1;
        start   = 1'b0;
        tx_data = 8'h00;
        miso    = 1'b0;

        slave_tx_data = 8'h00;
        slave_bit_count = 3'd0;

        repeat (5) @(posedge clk);

        reset = 1'b0;

          $display("======================================");
          $display("SPI MASTER TEST STARTED");
          $display("======================================");

          spi_transfer(8'hA4, 8'hB7);
          spi_transfer(8'hA5, 8'hB6);
          spi_transfer(8'h3C, 8'hD7);
          spi_transfer(8'hF0, 8'h29);
          spi_transfer(8'h81, 8'h56);
          spi_transfer(8'h00, 8'hFF);
          spi_transfer(8'hFF, 8'h00);
          spi_transfer(8'hAA, 8'h55);
          spi_transfer(8'h55, 8'hAA);

          $finish;

    end 
    endmodule
