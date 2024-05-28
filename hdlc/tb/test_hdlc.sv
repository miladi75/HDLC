//////////////////////////////////////////////////
// Title:   test_hdlc
// Author:  Karianne Krokan Kragseth
// Date:    20.10.2017
//////////////////////////////////////////////////

/* test_hdlc is the testbench module of this design, it sets up the testing
   enviroment by connecting the DUT to an interface (in_hdlc.sv) in with all the
   signals used by the test program. 
   All simulation code and immediate assertions are found in testPr_hdlc.sv.
*/





module test_hdlc ();
  
  //Hdlc interface
  in_hdlc uin_hdlc();

  //Internal assignments
  assign uin_hdlc.Rx_ValidFrame      = u_dut.Rx_ValidFrame;
  assign uin_hdlc.Rx_Data            = u_dut.Rx_Data;
  assign uin_hdlc.Rx_AbortSignal     = u_dut.Rx_AbortSignal;
  assign uin_hdlc.Rx_WrBuff          = u_dut.Rx_WrBuff;
  assign uin_hdlc.Rx_EoF             = u_dut.Rx_EoF;
  assign uin_hdlc.Rx_FrameSize       = u_dut.Rx_FrameSize;
  assign uin_hdlc.Rx_Overflow        = u_dut.Rx_Overflow;
  assign uin_hdlc.Rx_FCSerr          = u_dut.Rx_FCSerr;
  assign uin_hdlc.Rx_FCSen           = u_dut.Rx_FCSen;
  assign uin_hdlc.Rx_DataBuffOut     = u_dut.Rx_DataBuffOut;
  assign uin_hdlc.Rx_RdBuff          = u_dut.Rx_RdBuff;
  assign uin_hdlc.Rx_NewByte         = u_dut.Rx_NewByte;
  assign uin_hdlc.Rx_StartZeroDetect = u_dut.Rx_StartZeroDetect;
  assign uin_hdlc.Rx_FlagDetect      = u_dut.Rx_FlagDetect;
  assign uin_hdlc.Rx_AbortDetect     = u_dut.Rx_AbortDetect;
  assign uin_hdlc.Rx_FrameError      = u_dut.Rx_FrameError;
  assign uin_hdlc.Rx_Drop            = u_dut.Rx_Drop;
  assign uin_hdlc.Rx_StartFCS        = u_dut.Rx_StartFCS;
  assign uin_hdlc.Rx_StopFCS         = u_dut.Rx_StopFCS;
  assign uin_hdlc.RxD                = u_dut.RxD;
  assign uin_hdlc.ZeroDetect         = u_dut.u_RxChannel.ZeroDetect;
  assign uin_hdlc.Tx_ValidFrame      = u_dut.Tx_ValidFrame;
  assign uin_hdlc.Tx_AbortedTrans    = u_dut.Tx_AbortedTrans;
  assign uin_hdlc.Tx_WriteFCS        = u_dut.Tx_WriteFCS;
  assign uin_hdlc.Tx_InitZero        = u_dut.Tx_InitZero;
  assign uin_hdlc.Tx_StartFCS        = u_dut.Tx_StartFCS;
  assign uin_hdlc.Tx_RdBuff          = u_dut.Tx_RdBuff;
  assign uin_hdlc.Tx_NewByte         = u_dut.Tx_NewByte;
  assign uin_hdlc.Tx_FCSDone         = u_dut.Tx_FCSDone;
  assign uin_hdlc.Tx_Data            = u_dut.Tx_Data;
  assign uin_hdlc.Tx_Full            = u_dut.Tx_Full;
  assign uin_hdlc.Tx_DataAvail       = u_dut.Tx_DataAvail;
  assign uin_hdlc.Tx_FrameSize       = u_dut.Tx_FrameSize;
  assign uin_hdlc.Tx_DataArray       = u_dut.Tx_DataArray;
  assign uin_hdlc.Tx_DataOutBuff     = u_dut.Tx_DataOutBuff;
  assign uin_hdlc.Tx_WrBuff          = u_dut.Tx_WrBuff;
  assign uin_hdlc.Tx_Enable          = u_dut.Tx_Enable;
  assign uin_hdlc.Tx_DataInBuff      = u_dut.Tx_DataInBuff;
  assign uin_hdlc.Tx_AbortFrame      = u_dut.Tx_AbortFrame;


  //Clock
  always #250ns uin_hdlc.Clk = ~uin_hdlc.Clk;

  //Dut
  Hdlc u_dut(
    .Clk         (uin_hdlc.Clk),
    .Rst         (uin_hdlc.Rst),
    // Address
    .Address     (uin_hdlc.Address),
    .WriteEnable (uin_hdlc.WriteEnable),
    .ReadEnable  (uin_hdlc.ReadEnable),
    .DataIn      (uin_hdlc.DataIn),
    .DataOut     (uin_hdlc.DataOut),
    // RX
    .Rx          (uin_hdlc.Rx),
    .RxEN        (uin_hdlc.RxEN),
    .Rx_Ready    (uin_hdlc.Rx_Ready),
    // TX
    .Tx          (uin_hdlc.Tx),
    .TxEN        (uin_hdlc.TxEN),
    .Tx_Done     (uin_hdlc.Tx_Done)
);

  //Test program
  testPr_hdlc u_testPr(
    .uin_hdlc (uin_hdlc)
  );

endmodule
