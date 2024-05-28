//////////////////////////////////////////////////
// Title:   HDLC
// Author:  Karianne Krokan Kragseth
// Date:    25.09.2017
//////////////////////////////////////////////////


module Hdlc (
  input logic        Clk, //Clock
  input logic        Rst, //Reset
  // Address
  input logic  [2:0] Address,     //Address for read/write
  input logic        WriteEnable, //Write enable
  input logic        ReadEnable,  //Read enable
  input logic  [7:0] DataIn,      //Data input
  output logic [7:0] DataOut,     //Data output
  // TX
  output logic       Tx,      //TX serial line
  input logic        TxEN,    //TX enabled
  output logic       Tx_Done, //TX buffer can be written
  // RX
  input logic        Rx,      //RX serial line
  input logic        RxEN,    //RX enalbed
  output logic       Rx_Ready //RX Buffer ready to be read
);

////////////////////////////
//    Internal signals    //
////////////////////////////

  // Tx
  
  //From u_TxController
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

  //From u_TxBuff
//  logic              Tx_Done;        //TX buffer can be written
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

  // Rx

  //From u_RxController
  logic Rx_ValidFrame;      //Receiving valid frame
  logic Rx_WrBuff;          //Write RX byte to buffer
  logic Rx_EoF;             //Whole RX frame has been received, end of frame
  logic Rx_AbortSignal;     //RX frame was aborted
  logic Rx_StartZeroDetect; //Start detecting inserted zeros
  logic Rx_FrameError;      //Error in received RX frame
  logic Rx_StartFCS;        //Start FCS calculation
  logic Rx_StopFCS;         //Stop FCS calculation

  //From u_RxChannel
  logic [7:0] Rx_Data;        //Received RX byte
  logic       Rx_NewByte;     //New RX byte has been received
  logic       Rx_FlagDetect;  //Flag detected
  logic       Rx_AbortDetect; //Abort detected
  logic       RxD;            //Delayed RX bit, 9 clock cycles

  //From u_RxFCS
  logic Rx_FCSerr; //FCS error

  //From u_RxBuff
//  logic       Rx_Ready;       //RX Buffer ready to be read
  logic [7:0] Rx_FrameSize;   //Number of bytes received (minus FCS bytes)
  logic       Rx_Overflow;    //RX buffer is full
  logic [7:0] Rx_DataBuffOut; //Data read from RX buffer

  //From u_AddressIF
  logic Rx_FCSen;  //FCS error detection enabled
  logic Rx_RdBuff; //Read byte from RX buffer
  logic Rx_Drop;   //Drop received RX frame


//////////////////////////////
//    Address read/write    //
//////////////////////////////

  AddressIF u_AddressIF(
    .Clk(             Clk             ),
    .Rst(             Rst             ),
    .Address(         Address         ),
    .WriteEnable(     WriteEnable     ),
    .ReadEnable(      ReadEnable      ),
    .DataIn(          DataIn          ),
    .DataOut(         DataOut         ),
    //Inputs
    .Rx_Overflow(     Rx_Overflow     ),
    .Rx_AbortedFrame( Rx_AbortSignal  ),
    .Rx_FrameError(   Rx_FrameError   ),
    .RxReady(         Rx_Ready        ),
    .Rx_FrameSize(    Rx_FrameSize    ),
    .Rx_DataBuffer(   Rx_DataBuffOut  ),
    .Tx_Done(         Tx_Done         ),
    .Tx_Full(         Tx_Full         ),
    .Tx_AbortedTrans( Tx_AbortedTrans ),
    //Outputs
    .Rx_Drop(         Rx_Drop         ),
    .Rx_ReadBuff(     Rx_RdBuff       ),
    .Rx_FCSen(        Rx_FCSen        ),
    .Tx_WrBuff(       Tx_WrBuff       ),
    .Tx_Enable(       Tx_Enable       ),
    .Tx_DataInBuff(   Tx_DataInBuff   ),
    .Tx_AbortFrame(   Tx_AbortFrame   )
  );

/////////////////////
//    Transmitt    //
/////////////////////

  TxController u_TxController(
    .Clk(          Clk             ),
    .Rst(          Rst             ),
    //Inputs
    .DataAvail(    Tx_DataAvail    ),
    .AbortFrame(   Tx_AbortFrame   ),
    .NewByte(      Tx_NewByte      ),
    .WrBuff(       Tx_WrBuff       ),
    .FCSDone(      Tx_FCSDone      ),
    //Outputs
    .ValidFrame(   Tx_ValidFrame   ),
    .RdBuff(       Tx_RdBuff       ),
    .WriteFCS(     Tx_WriteFCS     ),
    .AbortedTrans( Tx_AbortedTrans ),
    .InitZero(     Tx_InitZero     ),
    .StartFCS(     Tx_StartFCS     )
  );

  TxBuff u_TxBuff(
    .Clk(          Clk             ),
    .Rst(          Rst             ),
    //Inputs
    .RdBuff(       Tx_RdBuff       ),
    .WrBuff(       Tx_WrBuff       ),
    .Enable(       Tx_Enable       ),
    .DataInBuff(   Tx_DataInBuff   ),
    .AbortedTrans( Tx_AbortedTrans ),
    //Outputs
    .DataOutBuff(  Tx_DataOutBuff  ),
    .DataAvail(    Tx_DataAvail    ),
    .Done(         Tx_Done         ),
    .Full(         Tx_Full         ),
    .DataArray(    Tx_DataArray    ),
    .FrameSize(    Tx_FrameSize    )
  );

  TxFCS u_TxFCS(
    .Clk(         Clk            ),
    .Rst(         Rst            ),
    //Inputs
    .ValidFrame(  Tx_ValidFrame  ),
    .DataAvail(   Tx_DataAvail   ),
    .DataBuff(    Tx_DataArray   ),
    .TxBuff(      Tx_DataOutBuff ),
    .WriteFCS(    Tx_WriteFCS    ),
    .FrameSize(   Tx_FrameSize   ),
    .StartFCS(    Tx_StartFCS    ),
    //Outputs
    .Data(        Tx_Data        ),
    .FCSDone(     Tx_FCSDone     )
  );

  TxChannel u_TxChannel(
    .Clk(          Clk             ),
    .Rst(          Rst             ),
    //Inputs
    .TxEN(         TxEN            ),
    .ValidFrame(   Tx_ValidFrame   ),
    .AbortedTrans( Tx_AbortedTrans ),
    .Data(         Tx_Data         ),
    .InitZero(     Tx_InitZero     ),
    //Outputs
    .Tx(           Tx              ),
    .NewByte(      Tx_NewByte      )
  );

///////////////////
//    Receive    //
///////////////////

  RxController u_RxController(
    .Clk(             Clk                ),
    .Rst(             Rst                ),
    //Inputs
    .NewByte(         Rx_NewByte         ),
    .FlagDetect(      Rx_FlagDetect      ),
    .Overflow(        Rx_Overflow        ),
    .FCSerror(        Rx_FCSerr          ),
    .Abort(           Rx_AbortDetect     ),
    //Outputs
    .AbortedFrame(    Rx_AbortSignal     ),
    .EoF(             Rx_EoF             ),
    .ValidFrame(      Rx_ValidFrame      ),
    .WriteByte(       Rx_WrBuff          ),
    .StartZeroDetect( Rx_StartZeroDetect ),
    .FrameError(      Rx_FrameError      ),
    .StartFCS(        Rx_StartFCS        ),
    .StopFCS(         Rx_StopFCS         )
  );


  RxBuff u_RxBuff(
    .Clk(           Clk             ),
    .Rst(           Rst             ),
    //Inputs
    .DataBuff(      Rx_Data         ),
    .EoF(           Rx_EoF          ),
    .WrBuff(        Rx_WrBuff       ),
    .Drop(          Rx_Drop         ),
    .FlagDetect(    Rx_FlagDetect   ),
    .AbortedFrame(  Rx_AbortSignal  ),
    .FrameError(    Rx_FrameError   ),
    .ReadBuff(      Rx_RdBuff       ),
    //Outputs
    .Overflow(      Rx_Overflow     ),
    .RxReady(       Rx_Ready        ),
    .FrameSize(     Rx_FrameSize    ),
    .RxDataBuffOut( Rx_DataBuffOut  )
  );

  RxFCS u_RxFCS(
    .Clk(        Clk           ),
    .Rst(        Rst           ),
    //Inputs
    .Rx(         RxD           ),
    .StartFCS(   Rx_StartFCS   ),
    .StopFCS(    Rx_StopFCS    ),
    .FCSen(      Rx_FCSen      ),
    //Outputs
    .FCSerr(     Rx_FCSerr     )
  );

  RxChannel u_RxChannel(
    .Clk(              Clk                ),
    .Rst(              Rst                ),
    //Inputs
    .RxEN(             RxEN               ),
    .Rx(               Rx                 ),
    .ValidFrame(       Rx_ValidFrame      ),
    .StartZeroDetect(  Rx_StartZeroDetect ),
    //Outputs
    .RxD(              RxD                ),
    .FlagDetect(       Rx_FlagDetect      ),
    .RxData(           Rx_Data            ),
    .Abort(            Rx_AbortDetect     ),
    .NewByte(          Rx_NewByte         )
  );

endmodule
