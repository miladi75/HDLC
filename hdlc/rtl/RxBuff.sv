//////////////////////////////////////////////////
// Title:   RxBuff
// Author:  Karianne Krokan Kragseth
// Date:    25.09.2017
//////////////////////////////////////////////////


module RxBuff(
  input logic        Clk,           //Clock
  input logic        Rst,           //Synchrouneous reset
  input logic  [7:0] DataBuff,      //
  input logic        EoF,           //Whole RX frame has been received
  input logic        WrBuff,        //Write RX byte to buffer
  input logic        ReadBuff,      //Read byte from RX buffer
  input logic        AbortedFrame,  //RX frame was aborted
  input logic        FrameError,    //Error in received RX frame
  input logic        Drop,          //Drop received RX frame
  input logic        FlagDetect,    //Flag detected
  output logic [7:0] FrameSize,     //Number of bytes received (minus FCS bytes)
  output logic       RxReady,       //RX Buffer ready to be read
  output logic [7:0] RxDataBuffOut, //Data read from RX buffer
  output logic       Overflow       //RX buffer is full
);

  localparam [7:0] MAX_COUNT = 8'b1000_0000; //128 bytes

  //Local declarations
  logic              LoadFrameSize; //Store Count(number of writes) in FrameSize
  logic              EnCount;       //Count +1
  logic              RstCount;      //Reset counter
  logic        [7:0] Count;         //Number of Writes/Reads
  logic [127:0][7:0] DataArray;     //RX buffer
  enum logic [1:0] {
    IDLE,
    WRITE,
    READ
  } CurrentState, NextState;


  always_ff @(posedge Clk or negedge Rst) begin : la_Buffer
    if(~Rst) begin
      DataArray <= '0;
    end else begin
      if(WrBuff && !Overflow) begin
        DataArray[Count] <= DataBuff;
        RxDataBuffOut     <= '0;
      end
      else if(!RxReady) begin
        RxDataBuffOut <= '0;
      end
      else
        RxDataBuffOut <= DataArray[Count];
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
      FrameSize   <= '0;
    end else begin
      if(LoadFrameSize)
        FrameSize <= Count - 2;
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
        RxReady       <= 1'b0;
        LoadFrameSize <= 1'b0;
        Overflow      <= 1'b0;
        if(WrBuff) begin
          NextState <= WRITE;
          EnCount   <=  1'b1;
          RstCount  <=  1'b0;
        end
        else begin
          NextState <= IDLE;
          EnCount   <= 1'b0;
          RstCount  <= 1'b1;
        end
      end
      WRITE : begin
        if(Count == MAX_COUNT) begin
          if(WrBuff)
            Overflow <= 1'b1;
          
          EnCount <=1'b0;
        end
        else begin
          Overflow <= 1'b0;
          EnCount  <= WrBuff;
        end
        
        if(FrameError) begin
          RxReady   <= 1'b0;
          NextState <= IDLE;
          RstCount  <= 1'b1;
        end
        else if((EoF)) begin
          RxReady       <= 1'b1;
          NextState     <= READ;
          LoadFrameSize <= 1'b1;
          RstCount      <= 1'b1;
        end
        else begin
          RxReady       <= 1'b0;
          NextState     <= WRITE;
          LoadFrameSize <= 1'b0;
          RstCount      <= 1'b0;
        end
      end
      READ : begin
        EnCount       <= ReadBuff;
        LoadFrameSize <= 1'b0;
        
        if((Count == FrameSize) || Drop || FrameError || AbortedFrame) begin
          Overflow  <= 1'b0;
          RxReady   <= 1'b0;
          NextState <= IDLE;
          RstCount  <= 1'b1;
        end
        else begin
          RxReady <= 1'b1;
          if(FlagDetect) begin //Receving new frame without reading whole previous frame
            NextState <= WRITE;
            Overflow  <=  1'b0;
            RxReady   <=  1'b0;
            RstCount  <=  1'b1;
          end
          else begin
            NextState <= READ;
            RstCount  <= 1'b0;
          end
        end
      end
    endcase
  end


endmodule
