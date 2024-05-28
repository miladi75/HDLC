//////////////////////////////////////////////////
// Title:   RxFCS
// Author:  Karianne Krokan Kragseth
// Date:    25.09.2017
//////////////////////////////////////////////////


module RxFCS(
  input logic       Clk,      //Clock
  input logic       Rst,      //Synchrouneous reset
  input logic       Rx,       //Received RX bit
  input logic       StartFCS, //Start FCS calculation
  input logic       StopFCS,  //Stop FCS calculation
  input logic       FCSen,    //FCS error detection enabled
  output logic      FCSerr    //FCS error
);

  // Internal declarations
  enum logic {
    IDLE,
    RUN
  } FCSState;
  logic [15:0] FCS_reg;    //FCS bytes
  logic  [4:0] ZeroRemove; //Checks if zero should be ignored

  always_ff @(posedge Clk or negedge Rst) begin : la_FCS
    if(~Rst) begin
      FCS_reg    <=   '0;
      FCSState   <= IDLE;
      ZeroRemove <=   '0;
      FCSerr     <= 1'b0;
    end else begin
      case (FCSState)
        IDLE : begin
          if(StartFCS) begin
            FCSState        <= RUN;
            FCS_reg[0]      <= Rx;
            ZeroRemove[4]   <= Rx;
            ZeroRemove[3:0] <= ZeroRemove[4:1];
          end
          else begin
            FCS_reg    <= '0;
            FCSState   <= IDLE;
            ZeroRemove <= '0;
          end
          FCSerr     <= 1'b0;
        end
        RUN : begin
          if(StopFCS) begin
            FCSState <= IDLE;
            FCSerr   <= FCSen && (|FCS_reg);
          end
          else begin
            FCSerr     <= 1'b0;
            FCSState <= RUN;
            ZeroRemove[4]   <= Rx;
            ZeroRemove[3:0] <= ZeroRemove[4:1];
            if(&ZeroRemove) begin //Ignore bit
              FCS_reg <= FCS_reg;
            end
            else begin
              FCS_reg[0]    <= Rx ^ FCS_reg[15];
              FCS_reg[1]    <= FCS_reg[0];
              FCS_reg[2]    <= FCS_reg[1] ^ FCS_reg[15];
              FCS_reg[14:3] <= FCS_reg[13:2];
              FCS_reg[15]   <= FCS_reg[14] ^ FCS_reg[15];
            end
          end
        end
      endcase
    end
  end

endmodule
