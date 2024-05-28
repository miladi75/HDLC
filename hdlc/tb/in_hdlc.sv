//////////////////////////////////////////////////
// Title:   in_hdlc
// Author:  Karianne Krokan Kragseth
// Date:    20.10.2017
//////////////////////////////////////////////////

interface in_hdlc ();
  //`include "Register_Addr_Constants.svh"
  //Tb
  int ErrCntAssertions;

  //Clock and reset
  logic Clk;
  logic Rst;

  // Address
  logic [2:0] Address;
  logic       WriteEnable;
  logic       ReadEnable;
  logic [7:0] DataIn;
  logic [7:0] DataOut;

  // TX
  logic Tx;
  logic TxEN;
  logic Tx_Done;
  
  logic Tx_ValidFrame;   //Transmitting valid TX frame
  logic Tx_AbortedTrans; //TX transmission is aborted
  logic Tx_WriteFCS;     //Transmit FCS byte
  logic Tx_InitZero;     //Initialize zero insertion with two first bytes of TX buffer
  logic Tx_StartFCS;     //Start FCS calculation
  logic Tx_RdBuff;       //Read new byte from TX buffer

  //From u_TxChannel
  logic Tx_NewByte; //New byte is loaded to be transmitted

  //From u_TxFCS
  logic       Tx_FCSDone; //Finished calculating FCS bytes
  logic [7:0] Tx_Data;    //Next TX byte to be transmitted

  logic              Tx_Full;        //TX buffer is full
  logic              Tx_DataAvail;   //Data is available in TX buffer
  logic        [7:0] Tx_FrameSize;   //Number of bytes in TX buffer
  logic [127:0][7:0] Tx_DataArray;   //TX buffer
  logic        [7:0] Tx_DataOutBuff; //Next TX byte in buffer to be transmitted

  //From u_AddressIF
  logic       Tx_WrBuff;     //Write new byte to TX buffer
  logic       Tx_Enable;     //Start transmission of TX buffer
  logic [7:0] Tx_DataInBuff; //Data from write
  logic       Tx_AbortFrame; //Abort current TX frame







  // RX
  logic Rx;
  logic RxEN;

  // Rx
  logic       Rx_ValidFrame;
  logic [7:0] Rx_Data;
  logic       Rx_AbortSignal;
  logic       Rx_Ready;
  logic       Rx_WrBuff;
  logic       Rx_EoF;
  logic [7:0] Rx_FrameSize;
  logic       Rx_Overflow;
  logic       Rx_FCSerr;
  logic       Rx_FCSen;
  logic [7:0] Rx_DataBuffOut;
  logic       Rx_RdBuff;
  logic       Rx_NewByte;
  logic       Rx_StartZeroDetect;
  logic       Rx_FlagDetect;
  logic       Rx_AbortDetect;
  logic       Rx_FrameError;
  logic       Rx_Drop;
  logic       Rx_StartFCS;
  logic       Rx_StopFCS;
  logic       RxD;
  logic       ZeroDetect;

endinterface
