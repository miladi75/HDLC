//////////////////////////////////////////////////
// Title:   TxController
// Author:  Karianne Krokan Kragseth
// Date:    16.10.2017
//////////////////////////////////////////////////

module TxController (
  input  logic Clk,          //Clock
  input  logic Rst,          //Synchrouneous reset
  input  logic DataAvail,    //Data is available in TX buffer
  input  logic AbortFrame,   //Abort current TX frame
  input  logic NewByte,      //New byte is loaded to be transmitted
  input  logic WrBuff,       //Write new byte to TX buffer
  input  logic FCSDone,      //Finished calculating FCS bytes
  output logic ValidFrame,   //Transmitting valid TX frame
  output logic RdBuff,       //Read new byte from TX buffer
  output logic WriteFCS,     //Transmit FCS byte
  output logic AbortedTrans, //TX transmission is aborted
  output logic InitZero,     //Initialize with two first bytes of TX buffer
  output logic StartFCS      //Start FCS calculation
);

  enum logic [2:0] {
    IDLE,
    WAIT_FCS,
    FIRST_READ,
    START,
    RUN,
    READ,
    FCS,
    ABORT
  } ControllerState;
  logic [2:0] NewByteCounter; //Counter NewByte's when in FCS state

  always_ff @(posedge Clk or negedge Rst) begin : la_Controller
    if(~Rst) begin
      ControllerState <= IDLE;
      ValidFrame      <= 1'b0;
      RdBuff          <= 1'b0;
      WriteFCS        <= 1'b0;
      AbortedTrans    <= 1'b0;
      InitZero        <= 1'b0;
      StartFCS        <= 1'b0;
      NewByteCounter  <=   '0;
    end else begin
      case (ControllerState)
        IDLE : begin
          ValidFrame      <= 1'b0;
          WriteFCS        <= 1'b0;
          AbortedTrans    <= 1'b0;
          InitZero        <= 1'b0;
          RdBuff          <= 1'b0;
          NewByteCounter  <=   '0;
          if(DataAvail && !AbortFrame) begin
            ControllerState <= WAIT_FCS;
            StartFCS        <= 1'b1;
          end
          else begin
            ControllerState <= IDLE;
            StartFCS        <= 1'b0;
          end
        end
        WAIT_FCS : begin
          StartFCS        <= 1'b0;
          if(AbortFrame)
            ControllerState <= ABORT;
          else if(FCSDone) begin
            ControllerState <= FIRST_READ;
            RdBuff          <= 1'b1;
          end
          else
            ControllerState <= WAIT_FCS;
        end
        FIRST_READ : begin
          RdBuff          <= 1'b0;
          if(AbortFrame)
            ControllerState <= ABORT;
          else 
            ControllerState <= START;
        end
        START : begin
          if(AbortFrame)
            ControllerState <= ABORT;
          else begin
            ControllerState <= READ;
            InitZero        <= 1'b1;
          end
        end
        RUN : begin
          ValidFrame      <= 1'b1;
          RdBuff          <= 1'b0;
          if(AbortFrame) begin
            ControllerState <= ABORT;
            WriteFCS        <=  1'b0;
          end
          else if(NewByte) begin
            if(DataAvail) begin //Available data in TX buffer
              ControllerState <= READ;
              WriteFCS        <= 1'b0;
            end
            else begin //No more data in TX buffer
              ControllerState <=  FCS; //Transmit FCS bytes
              WriteFCS        <= 1'b1;
            end
          end
          else begin
            ControllerState <=  RUN;
            WriteFCS        <= 1'b0;
          end
        end
        READ : begin
          ValidFrame      <= 1'b1;
          RdBuff          <= 1'b1;
          InitZero        <= 1'b0;
          if(AbortFrame)
            ControllerState <= ABORT;
          else
            ControllerState <= RUN;
        end
        FCS : begin
          if(AbortFrame)
            ControllerState <= ABORT;
          else begin
            if(NewByte) begin
              WriteFCS        <= 1'b1;
              NewByteCounter  <= NewByteCounter + 1;
            end
            else
              WriteFCS        <= 1'b0;

            if((NewByteCounter == 4) && NewByte) begin //Takes 5 "NewByte" before done transmitting
              ControllerState <= IDLE;
              ValidFrame      <= 1'b0;
            end
            else
              ControllerState <=  FCS;
          end
        end
        ABORT : begin
          ValidFrame   <= 1'b0;
          RdBuff       <= 1'b0;
          WriteFCS     <= 1'b0;
          InitZero     <= 1'b0;
          if(WrBuff) begin //Wait for new byte to be written to TX buffer (keeps AbortedTrans high)
            ControllerState <= IDLE;
            AbortedTrans    <= 1'b0;
          end
          else begin
            ControllerState <= ABORT;
            AbortedTrans    <=  1'b1;
          end
        end
      endcase
    end
  end

endmodule
