//////////////////////////////////////////////////
// Title:   TxChannel
// Author:  Karianne Krokan Kragseth
// Date:    25.09.2017
//////////////////////////////////////////////////


module TxChannel(
  input logic       Clk,          //Clock
  input logic       Rst,          //Synchrouneous reset
  input logic       TxEN,         //Enable TX transmission
  input logic       ValidFrame,   //Transmitting valid TX frame
  input logic       AbortedTrans, //TX transmission is aborted
  input logic [7:0] Data,         //TX data
  input logic       InitZero,     //Initialize with two first bytes of TX buffer
  output logic      Tx,           //TX output
  output logic      NewByte       //New byte is loaded to be transmitted
);

  // Internal signals
  logic        TxD;           //Tx bit from la_ZeroDetect to la_FlagInsert
  logic [15:0] Temp_reg;      //Keeps track of bytes to be transmitted and zero insertion
  logic  [2:0] ZeroCounter;   //Counter for when to load new byte
  logic  [7:0] Transmitt_reg; //Shift-reg for bits to be transmitted
  logic        FlagState;     //States

  //Internal assignments
  assign OnesDetected = &Temp_reg[4:0];

  always_ff @(posedge Clk or negedge Rst) begin : la_ZeroDetect
    if(~Rst) begin
      NewByte     <= 1'b0;
      TxD         <= 1'b0;
      Temp_reg    <=   '0;
      ZeroCounter <=   '0;
    end
    else begin
      if(TxEN) begin
        TxD <= Temp_reg[0];
        if(ValidFrame) begin
          if(OnesDetected) begin //Insert zero
            Temp_reg[3:0] <= Temp_reg[4:1];
            Temp_reg[4]   <= 1'b0;
            NewByte       <= 1'b0;
          end
          else begin
            if(ZeroCounter == 3'b111) begin //Load new byte
              ZeroCounter <= '0;
              Temp_reg[7:0]  <= Temp_reg >> 1;
              Temp_reg[15:8] <= Data;
              NewByte        <= 1'b1;
            end
            else begin
              ZeroCounter  <= ZeroCounter + 1;
              Temp_reg     <= Temp_reg >> 1;
              Temp_reg[15] <= 1'b0;
              NewByte      <= 1'b0;
            end
          end
        end
        else begin
          if(InitZero)
            Temp_reg[7:0]  <= Temp_reg[7:0];
          else
            Temp_reg[7:0]  <= Data;
          
          Temp_reg[15:8] <= Data;
          NewByte        <= 1'b0;
          ZeroCounter    <=   '0;
        end
      end
    end
  end

  always_ff @(posedge Clk or negedge Rst) begin : la_FlagInsert
    if(~Rst) begin
      Tx            <= 1'b1;
      FlagState     <= 1'b0;
      Transmitt_reg <=   '1;
    end
    else begin
      case (FlagState)
        0 : begin 
          Tx <= Transmitt_reg[0];
          
          if(ValidFrame && !AbortedTrans) begin //Start transmitting TX buffer
            Transmitt_reg <= 8'b0111_1110; //Load and tranmsit start Flag
            FlagState     <= 1'b1;
          end
          else begin
            Transmitt_reg[7]   <= 1'b1;
            Transmitt_reg[6:0] <= Transmitt_reg >> 1;
          end
        end
        1 : begin 
          
          if(AbortedTrans) begin //Frame is aborted
            Transmitt_reg <= 8'b1111_1110; //Load and tranmsit abort pattern
            FlagState     <= 1'b0;
            Tx            <= Transmitt_reg[0];
          end
          else if(!ValidFrame) begin //Finished transmitting TX buffer
            Transmitt_reg <= 8'b1011_1111; //Load and tranmsit end Flag (8'b0111_1110)
            FlagState     <= 1'b0;
            Tx            <= 1'b0;
          end
          else begin
            Transmitt_reg[7]   <= TxD;
            Transmitt_reg[6:0] <= Transmitt_reg >> 1;
            Tx                 <= Transmitt_reg[0];
          end
        end
      endcase
    end
  end


endmodule
