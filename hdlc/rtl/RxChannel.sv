//////////////////////////////////////////////////
// Title:   RxChannel
// Author:  Karianne Krokan Kragseth
// Date:    25.09.2017
//////////////////////////////////////////////////


module RxChannel (
  input logic        Clk,             //Clock
  input logic        Rst,             //Synchrouneous reset
  input logic        RxEN,            //Enable recive channel
  input logic        Rx,              //Received RX bit
  input logic        ValidFrame,      //Receiving valid frame
  input logic        StartZeroDetect, //Start detecting inserted zeros
  output logic       FlagDetect,      //Flag detected
  output logic [7:0] RxData,          //Received RX byte
  output logic       Abort,           //Abort detected
  output logic       NewByte,         //New RX byte has been received
  output logic       RxD              //Delayed RX bit
);

  // Local declarations
  logic       ZeroDetect;   //Inserted zero detected
  logic [7:0] TempRegister; //Temporary recived RX byte
  logic [2:0] BitCounter;   //Number of bits recived for current byte
  logic [5:0] CheckReg;     //Store last 6 bits, looks for inserted zeros
  logic [7:0] ShiftReg;     //Last 8 RX bits received

  // Local assignments
  assign ZeroDetect = !RxD && &CheckReg[5:1];

  always_ff @(posedge Clk or negedge Rst) begin : la_ZeroDetect
    if(~Rst) begin
      BitCounter   <=   '0;
      TempRegister <=   '0;
      NewByte      <= 1'b0;
      CheckReg     <=   '0;
      RxData       <= 1'b0;
    end else begin
      if(ValidFrame) begin
        if(!StartZeroDetect) begin
          CheckReg[4:0] <= CheckReg >> 1;
          CheckReg[5]   <= RxD;
        end
        else begin
          CheckReg[4:0] <=  '0;
          CheckReg[5]   <= RxD;
          BitCounter    <=  '0;
        end
          TempRegister[BitCounter] <= RxD;

        if(ZeroDetect) begin
          NewByte <= 1'b0;
        end
        else begin
          if(BitCounter == 7) begin
            BitCounter  <=   '0;
            NewByte     <= 1'b1;
          end
          else begin
            BitCounter <= BitCounter + 1;
            NewByte    <= 1'b0;
          end
        end
        if(NewByte)
          RxData <= TempRegister;
      end
      else begin
        NewByte    <= 1'b0;
        BitCounter <= 1'b0;
      end
    end
  end


  always_ff @(posedge Clk or negedge Rst) begin : la_FlagDetect
    if(~Rst) begin
      FlagDetect <= 1'b0;
      Abort      <= 1'b0;
      RxD        <= 1'b0;
      ShiftReg   <=   '0;
    end else begin
      FlagDetect    <= !ShiftReg[0] && &ShiftReg[6:1] && !ShiftReg[7];
      Abort         <= !ShiftReg[0] && &ShiftReg[7:1];

      ShiftReg[6:0] <= ShiftReg >> 1;
      ShiftReg[7]   <= Rx;

      RxD           <= ShiftReg[0];
    end
  end


endmodule
