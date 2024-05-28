//////////////////////////////////////////////////
// Title:   RxController
// Author:  Karianne Krokan Kragseth
// Date:    25.09.2017
//////////////////////////////////////////////////


module RxController(
  input logic       Clk,             //Clock
  input logic       Rst,             //Synchrouneous reset
  input logic       NewByte,         //New RX byte has been received
  input logic       FlagDetect,      //Flag detected
  input logic       Overflow,        //RX buffer is full
  input logic       FCSerror,        //FCS error
  input logic       Abort,           //Abort detected
  output logic      EoF,             //Whole RX frame has been received
  output logic      ValidFrame,      //Receiving valid frame
  output logic      AbortedFrame,    //RX frame was aborted
  output logic      WriteByte,       //Write RX byte to buffer
  output logic      StartZeroDetect, //Start detecting inserted zeros
  output logic      FrameError,      //Error in received RX frame
  output logic      StartFCS,        //Start FCS calculation
  output logic      StopFCS          //Stop FCS calculation
);

  // Internal declarations
  enum logic [1:0] {
    IDLE,
    WAIT,
    OVERFLOW
  } Controlstate;

  logic [2:0] FlagCounter;         //Counts clk cylces after FlagDetect
  logic       FrameStatus;         //ValidFrame
  logic [7:0] FrameStatusReg;      //Delayed ValidFrame
  logic       NonByteAlignedError; //Received non-byte aligned rx frame

  // Internal assignments
  assign ValidFrame = (FrameStatusReg[0] || StartZeroDetect) && FrameStatusReg[5];
  assign StopFCS    = FrameStatus && FlagDetect;
  assign StartFCS   = StartZeroDetect;

  always_ff @(posedge Clk or negedge Rst) begin : la_ValidFrame
    if(~Rst) begin
      FrameStatus     <= 1'b0;
      FrameStatusReg  <=   '0;
      FlagCounter     <=   '0;
      StartZeroDetect <= 1'b0;
      AbortedFrame    <= 1'b0;
    end else begin
      if(Abort) begin
        FrameStatus  <= 1'b0;
        FlagCounter  <=   '0;
        if(ValidFrame)
          AbortedFrame <= 1'b1;
        else
          AbortedFrame <= 1'b0;
      end
      else if(FlagDetect) begin
        if(!ValidFrame) begin
          FrameStatus  <= 1'b1;
          FlagCounter  <= FlagCounter + 1;
          AbortedFrame <= 1'b0;
        end
        else begin
          FrameStatus <= 1'b0;
          FlagCounter <= 1'b0;
        end
      end
      else if(FlagCounter == 7) begin
          StartZeroDetect <= 1'b1;
          FlagCounter     <= 1'b0;
      end
      else if(FlagCounter > 0) begin //Delay start zero detect
        FlagCounter <= FlagCounter + 1;
      end
      else
        StartZeroDetect <= 1'b0;

      FrameStatusReg[6:0] <= FrameStatusReg >> 1;
      FrameStatusReg[7]   <= FrameStatus;
    end
  end


  always_ff @(posedge Clk or negedge Rst) begin : la_Controller
    if(~Rst) begin
      WriteByte           <= 1'b0;
      Controlstate        <= IDLE;
      EoF                 <= 1'b0;
      NonByteAlignedError <= 1'b0;
    end else begin
      case (Controlstate)
        IDLE : begin
          WriteByte           <= 1'b0;
          EoF                 <= 1'b0;
          NonByteAlignedError <= 1'b0;
          if(ValidFrame)
            Controlstate <= WAIT;
          else
            Controlstate <= IDLE;
        end
        WAIT : begin
          WriteByte  <= 1'b0;

          if(ValidFrame) begin
            if(Overflow)
              Controlstate <= OVERFLOW;
            else
              Controlstate <= WAIT;
              if(NewByte)
                WriteByte    <= 1'b1;
              else if(FlagDetect && !NewByte) begin
                NonByteAlignedError <= 1'b1;
                WriteByte           <= 1'b0;
              end
              else
                WriteByte    <= 1'b0;
            end
          else begin
            EoF          <= 1'b1;
            Controlstate <= IDLE;
            WriteByte    <= 1'b0;
          end
        end
        OVERFLOW : begin
          if(ValidFrame) begin
            Controlstate <= OVERFLOW;
            if(FlagDetect && !NewByte)
              NonByteAlignedError <= 1'b1;
          end
          else begin
            Controlstate <= IDLE;
            EoF          <= 1'b1;
          end
        end
      endcase
    end
  end

  always_ff @(posedge Clk or negedge Rst) begin : la_Error
    if(~Rst) begin
      FrameError <= 1'b0;
    end else begin
      if(NonByteAlignedError || FCSerror)
        FrameError <= 1'b1;
      else if(FlagDetect) //Clear frame error at start flag
        FrameError <= 1'b0;
    end
  end

endmodule
