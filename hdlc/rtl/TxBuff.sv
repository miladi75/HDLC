//////////////////////////////////////////////////
// Title:   TxBuff
// Author:  Karianne Krokan Kragseth
// Date:    25.09.2017
//////////////////////////////////////////////////


module TxBuff(
  input logic               Clk,          //Clock
  input logic               Rst,          //Synchrouneous reset
  input logic               RdBuff,       //Read new byte from TX buffer
  input logic               WrBuff,       //Write new byte to TX buffer
  input logic               Enable,       //Start transmission of TX buffer
  input logic         [7:0] DataInBuff,   //Data from write
  input logic               AbortedTrans, //TX transmission is aborted
  output logic              DataAvail,    //Data is available in TX buffer
  output logic              Done,         //TX buffer can be written
  output logic        [7:0] DataOutBuff,  //Next TX byte in buffer to be transmitted
  output logic              Full,         //TX buffer is full
  output logic [127:0][7:0] DataArray,    //TX buffer
  output logic        [7:0] FrameSize     //Number of bytes in TX buffer
);
  localparam MAX_COUNT = 8'b0111_1110; //Max. = 126 bytes, 126 + 2 FCS bytes = 128 bytes

  // Internal declarations
  enum logic [1:0] {
    IDLE  = 2'b00,
    WRITE = 2'b01,
    READ  = 2'b10
  } CurrentState, NextState;

  logic       LoadFrameSize; //Store Count(number of writes) in FrameSize
  logic       EnCount;       //Count +1
  logic [7:0] Count;         //Number of Writes/Reads
  logic       RstCount;      //Reset counter

  // Internal assignments
  assign DataOutBuff = DataArray[Count];
  assign Full        = (Count == MAX_COUNT) ? 1'b1 : 1'b0;

  always_ff @(posedge Clk or negedge Rst) begin : la_Buffer
    if(~Rst) begin
      DataArray <= 0;
    end else begin
      if(WrBuff && !Full && !DataAvail)
        DataArray[Count] <= DataInBuff;
      else if(CurrentState==IDLE) //Reset data buffer after transmission
        DataArray <= '0;;
    end
  end

  always_ff @(posedge Clk or negedge Rst) begin : la_Counter
    if(~Rst) begin
      Count <= '0;
    end else begin
      if(RstCount)
        Count <= '0;
      else if(EnCount)
        Count <= Count + 1;
    end
  end

  always_ff @(posedge Clk or negedge Rst) begin : la_FrameSize
    if(~Rst) begin
      FrameSize <= '0;
    end else begin
      if(LoadFrameSize)
        FrameSize <= Count;
    end
  end


  always_ff @(posedge Clk or negedge Rst) begin : la_FSM
    if(~Rst) begin
      CurrentState <= IDLE;
    end else begin
      CurrentState <= NextState;
    end
  end

  always_comb begin : la_ReadWrite
    case (CurrentState)
      IDLE : begin
        Done          = 1'b1;
        DataAvail     = 1'b0;
        LoadFrameSize = 1'b0;

        if(WrBuff) begin
          NextState = WRITE;
          EnCount   =  1'b1;
          RstCount  =  1'b0;
        end
        else begin
          NextState = IDLE;
          EnCount   = 1'b0;
          RstCount  = 1'b1;
        end
      end
      WRITE : begin
        if(Count == MAX_COUNT)
          EnCount = 1'b0;
        else
          EnCount = WrBuff;

        Done      = 1'b0;
        DataAvail = 1'b0;

        if(Enable) begin
          NextState     = READ;
          LoadFrameSize = 1'b1;
          RstCount      = 1'b1;
        end
        else begin
          NextState     = WRITE;
          LoadFrameSize =  1'b0;
          RstCount      =  1'b0;
        end
      end
      READ : begin
        DataAvail     = 1'b1;
        EnCount       = RdBuff;
        LoadFrameSize = 1'b0;

        if((Count == (FrameSize-1)) || AbortedTrans) begin //Framsize-1 because first read won't be counted
          Done      = 1'b1;
          NextState = IDLE;
          RstCount  = 1'b1;
        end
        else begin
          Done      = 1'b0;
          NextState = READ;
          RstCount  = 1'b0;
        end
      end
    endcase
  end

endmodule
