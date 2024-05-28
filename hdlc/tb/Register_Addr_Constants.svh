`ifndef REGISTER_ADDRESSES_CONSTANTS_SVH
`define REGISTER_ADDRESSES_CONSTANTS_SVH


  // HDLC Verification patterns constants
  localparam logic [7:0]    START_END_PATTERN = 8'b0111_1110;
  localparam logic [7:0]    IDLE_FRAME =   8'b1111_1111;

  //Mask for READING Control register Rx
  localparam logic [7:0]    RxSC_Read_mask  =   8'b1101_1101;
  


  localparam logic [2:0]    TxSC_Addr       =   3'h0;
  localparam logic [2:0]    TxBuff_Addr     =   3'h1;

  localparam logic [2:0]    RxSC_Addr       =   3'h2;
  localparam logic [2:0]    RxBuff_Addr     =   3'h3;
  localparam logic [2:0]    RxFrameLen      =   3'h4;

  localparam logic          TRUE            =   1'b1;
  localparam logic          FALSE           =   1'b0;


  //User define constants for Tx_SC Register
  localparam logic [7:0] TxSC_READ_MASK_CONST           =   8'b1111_1001;

  localparam logic [2:0] TxSC_ADDR_CONST                = 3'h0;
  localparam logic [7:0] TXSC_REG_FULL_CONST            = 8'b0001_0000;
  localparam logic [7:0] TXSC_TX_ABORTED_CONST          = 8'b0000_1000;
  localparam logic [7:0] TXSC_FRAME_ABORTED_CONST       = 8'b0000_0100;
  localparam logic [7:0] TXSC_TX_ENABLED_CONST          = 8'b0000_0010;
  localparam logic [7:0] TXSC_DONE_CONST                = 8'b0000_0001;
  
  //Rx constants
  localparam logic [7:0] RXSC_FCS_EN                    = 8'b0010_0000;
  localparam logic [7:0] RXSC_OVERFLOW_EN               = 8'b0001_0000;
  localparam logic [7:0] RXSC_ABORT_SIGNAL              = 8'b0000_1000;
  localparam logic [7:0] RXSC_FRAMEERROR                = 8'b0000_0100;
  localparam logic [7:0] RXSC_DROPED                    = 8'b0000_0010;
  localparam logic [7:0] RXSC_READY                     = 8'b0000_0001;
  
//Pattern sequences
localparam logic [7:0] ABORT_PATTERN                    = 8'b1111_1110;
localparam logic [7:0] IDLE_PATTERN                     = 8'b1111_1110;


localparam logic NR_FCS_BYTES = 2'h2;


//SOME useful testvectors

/*
localparam logic ALL_ZEROS = 8'h00000000;
localparam logic ALL_ONES = 8'hFFFFFFFF;
localparam logic LSB_ONE = 8'h00000001;
localparam logic MSB_ONE = 8'h80000001;
localparam logic ALT_ZEROS_ONES = 8'h55555555;
localparam logic ALT_ONES_ZEROS = 8'hAAAAAAAA;
localparam logic RAND_VAL_0 = 8'hDEADBEEF;
localparam logic RAND_VAL_1 = 8'h7F35AEC5;
*/


`endif /*REGISTER_ADDRESSES_CONSTANTS_SVH*/