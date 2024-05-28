//////////////////////////////////////////////////
// Title:   AddresIF
// Author:  Karianne Krokan Kragseth
// Date:    25.09.2017
//////////////////////////////////////////////////


module AddressIF (
  input logic        Clk,             //Clock
  input logic        Rst,             //Synchrouneous reset
  input logic  [2:0] Address,         //Address for read/write
  input logic        WriteEnable,     //Write enabled
  input logic        ReadEnable,      //Read enabled
  input logic  [7:0] DataIn,          //Data in - write
  output logic [7:0] DataOut,         //Data out - read
  input logic        Rx_Overflow,     //RX buffer is full
  input logic        Rx_AbortedFrame, //RX frame was aborted
  input logic        Rx_FrameError,   //Error in received RX frame
  input logic        RxReady,         //RX buffer ready to be read
  input logic  [7:0] Rx_FrameSize,    //Number of bytes received (minus FCS bytes)
  input logic  [7:0] Rx_DataBuffer,   //Data read from RX buffer
  input logic        Tx_Done,         //TX buffer can be written
  input logic        Tx_Full,         //TX buffer is full
  input logic        Tx_AbortedTrans, //TX transmission is aborted
  output logic       Rx_Drop,         //Drop received RX frame
  output logic       Rx_FCSen,        //FCS error detection enabled
  output logic       Rx_ReadBuff,     //Read byte from RX buffer
  output logic       Tx_WrBuff,       //Write new byte to TX buffer
  output logic       Tx_Enable,       //Start transmission of TX buffer
  output logic [7:0] Tx_DataInBuff,   //Data from write
  output logic       Tx_AbortFrame    //Abort current TX frame
);

  //Internal declarations
  logic [7:0] Rx_SC;   //RX status and control register
  logic [7:0] Rx_Len;  //RX frame size
  logic [7:0] Rx_Buff; //RX data from buffer
  logic [7:0] Tx_SC;   //TX status and control register
  logic [7:0] Tx_Buff; //TX data to buffer

  //Internal assignments
  assign Rx_Drop       = Rx_SC[1];
  assign Rx_FCSen      = Rx_SC[5];
  assign Rx_Len        = Rx_FrameSize;
  assign Rx_Buff       = Rx_DataBuffer;
  assign Tx_Enable     = Tx_SC[1];
  assign Tx_AbortFrame = Tx_SC[2];
  assign Tx_DataInBuff = Tx_Buff;

  always_ff @(posedge Clk or negedge Rst) begin : proc_Write
    if(~Rst) begin
      Rx_SC <= '0;
      Tx_SC <= '0;
      Tx_WrBuff <= 1'b0;
      Tx_Buff   <=   '0;
    end else begin
      if(WriteEnable) begin
        case (Address)
          3'b000 : begin
            Tx_SC[1] <= DataIn[1]; //TxEnable
            Tx_SC[2] <= DataIn[2]; //TxAbort
          end
          3'b001 : begin
            Tx_Buff   <= DataIn;
            Tx_WrBuff <= 1'b1;
          end
          3'b010 : begin
            Rx_SC[1] <= DataIn[1]; //Drop
            Rx_SC[5] <= DataIn[5]; //FCSen
          end
        endcase
      end
      else begin
        Tx_SC[1]  <= 1'b0;
        Tx_SC[2]  <= 1'b0;
        Tx_WrBuff <= 1'b0;
        Tx_Buff   <=   '0;
        Rx_SC[1]  <= 1'b0;
      end

      Rx_SC[0]   <= RxReady;
      Rx_SC[2]   <= Rx_FrameError;
      Rx_SC[3]   <= Rx_AbortedFrame;
      Rx_SC[4]   <= Rx_Overflow;
      Rx_SC[7:6] <= '0;

      Tx_SC[0]   <= Tx_Done;
      Tx_SC[3]   <= Tx_AbortedTrans;
      Tx_SC[4]   <= Tx_Full;
      Tx_SC[7:5] <= '0;
    end
  end

  always_comb begin : proc_Read
    DataOut     = '0;
    Rx_ReadBuff = 1'b0;
    if(ReadEnable) begin
      case (Address)
        3'b000 : DataOut = Tx_SC;
        3'b010 : DataOut = Rx_SC;
        3'b011 : begin
          DataOut     = Rx_Buff;
          Rx_ReadBuff = 1'b1;
        end
        3'b100 : DataOut = Rx_Len;
      endcase
    end
  end

endmodule
