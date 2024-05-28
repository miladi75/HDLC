//////////////////////////////////////////////////
// Title:   testPr_hdlc
// Author: 
// Date:  
//////////////////////////////////////////////////

/* testPr_hdlc contains the simulation and immediate assertion code of the
   testbench. 

   For this exercise you will write immediate assertions for the Rx module which
   should verify correct values in some of the Rx registers for:
   - Normal behavior
   - Buffer overflow 
   - Aborts

   HINT:
   - A ReadAddress() task is provided, and addresses are documentet in the 
     HDLC Module Design Description
*/







program testPr_hdlc(
  in_hdlc uin_hdlc
);

// `include "Register_Addr_Constants.svh"
  
int TbErrorCnt;

  /****************************************************************************
   *                                                                          *
   *                               Student code                               *
   *                                                                          *
   ****************************************************************************/

   logic[2:0] RXSC = 3'h2;
   logic[2:0] TXSC = 3'h0;
   //logic[2:0] TxBuff_Addr = 3'h1;
   //Adding this from Resgister_Addr_oncstant.svh file to avoid error
//SECTION - ****************************************************************************************
  localparam logic [7:0]    START_END_PATTERN           = 8'b0111_1110;
  localparam logic [7:0]    IDLE_FRAME                  = 8'b1111_1111; 
   
  localparam logic [7:0]    ABORT_PATTERN               = 8'b1111_1110;
  localparam logic [7:0]    IDLE_PATTERN                = 8'b1111_1110;
  
  localparam logic          NR_FCS_BYTES                    = 2'h2; 
  localparam logic          TRUE                            = 1'b1;
  localparam logic          FALSE                           = 1'b0;
  
   //RX related address and constans
  localparam logic [7:0]    RxSC_Read_mask  =   8'b1101_1101;
  localparam logic [2:0]    RxSC_Addr       =   3'h2;
  localparam logic [2:0]    RxBuff_Addr     =   3'h3;
  localparam logic [2:0]    RxFrameLen      =   3'h4;

  localparam logic [7:0]    RXSC_FCS_EN                    = 8'b0010_0000;
  localparam logic [7:0]    RXSC_OVERFLOW_EN               = 8'b0001_0000;
  localparam logic [7:0]    RXSC_ABORT_SIGNAL              = 8'b0000_1000;
  localparam logic [7:0]    RXSC_FRAMEERROR                = 8'b0000_0100;
  localparam logic [7:0]    RXSC_DROPED                    = 8'b0000_0010;
  localparam logic [7:0]    RXSC_READY                     = 8'b0000_0001;
  

  //User define constants for Tx_SC Register
  localparam logic [7:0] TxSC_READ_MASK_CONST           =   8'b1111_1001;
  localparam logic [2:0] TxSC_ADDR_CONST                = 3'h0;
  localparam logic [2:0] TxBuff_Addr                    =   3'h1;
  localparam logic [7:0] TXSC_REG_FULL_CONST            = 8'b0001_0000;
  localparam logic [7:0] TXSC_TX_ABORTED_CONST          = 8'b0000_1000;
  localparam logic [7:0] TXSC_FRAME_ABORTED_CONST       = 8'b0000_0100;
  localparam logic [7:0] TXSC_TX_ENABLED_CONST          = 8'b0000_0010;
  localparam logic [7:0] TXSC_DONE_CONST                = 8'b0000_0001;
  
   
 
 
 



// 1. Correct data in RX buffer according to RX input.
// The buffer should contain up to 128 bytes (this includes the 2 FCS bytes, but not the flags).

//2. Attempting to read RX buffer after aborted frame, frame error or dropped frame should
//result in zero

  // VerifyAbortReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer is zero after abort.
  task VerifyAbortReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;

    ReadAddress(RxSC_Addr, ReadData);
    abortSignal : assert (ReadData & RXSC_ABORT_SIGNAL) begin 
      //$display($stime,"\t\t PASS::RX_AbortSignal correct\n");
    end else begin 
       $display($stime,"\t\t FAIL::RX_AbortSignal wrong\n");
    end


    ReadAddress(RxBuff_Addr, ReadData);

    abortBuffEmpty : assert (ReadData == 8'h0) begin
      //$display($stime,"\t\t PASS::RX_Buff empty\n");
    end else begin 
      $display($stime,"\t\t FAIL::RX_Buff not empty\n");
    end


  endtask

  // VerifyNormalReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer contains correct data.
  task VerifyNormalReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData, ReadLen;
    wait(uin_hdlc.Rx_Ready);

    ReadAddress(RxSC_Addr, ReadData);

    
    NormalSC0 : assert ((ReadData & RXSC_READY) == TRUE)
    //$display($stime,"\t\t PASS::Rx Status Ready OK \n");
    else $display($stime,"\t\t FAIL::Rx Status Ready\n");

    NormalSC1 : assert ((ReadData & RXSC_DROPED) == FALSE)
    //$display($stime,"\t\t PASS::RxSC frame dropped OK\n");
    else $display($stime,"\t\t FAIL::RxSC Frame drop\n");

    NormalSC2 : assert ((ReadData & RXSC_FRAMEERROR) == FALSE)
    //$display($stime,"\t\t PASS::RXSC_FRAMEERROR OK \n");
    else $display($stime,"\t\t FAIL::RXSC_FRAMEERROR\n");

    NormalSC3 : assert ((ReadData & RXSC_ABORT_SIGNAL) == FALSE)
    //$display($stime,"\t\t PASS::RXSC_ABORT_SIGNAL Abort signal OK \n");
    else $display($stime,"\t\t FAIL::RXSC_ABORT_SIGNAL Fail Abort signal\n");

    NormalSC4 : assert ((ReadData & RXSC_OVERFLOW_EN) == FALSE)
    //$display($stime,"\t\t PASS::RXSC_OVERFLOW_EN overflow signal OK\n");
    else $display($stime,"\t\t FAIL::RXSC_OVERFLOW_EN overflow signal fail\n");


    ReadAddress(RxFrameLen, ReadLen );

    Normal : assert (ReadLen == Size)
    //$display($stime,"\t\t PASS::RX_Len correct: %d\n",ReadLen);
    else $display($stime,"\t\t FAIL::RC_Len incorrect\n");

    for(int i = 0; i < ReadLen;i++) begin
      ReadAddress(RxBuff_Addr, ReadData);

      NormalBuff : assert (ReadData == data[i])
      //$display($stime,"\t\t PASS::RX_Buff correct \n");
      else $display($stime,"\t\t FAIL::RC_Buff incorrect\n");
    end

  
  endtask

  // VerifyNormalReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer contains correct data.
  task VerifyOverflowReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData, ReadLen;
    wait(uin_hdlc.Rx_Ready);

    ReadAddress(RxSC_Addr, ReadData );

    OverflowReceive : assert (ReadData & RXSC_OVERFLOW_EN)
    //$display($stime,"\t\t PASS::RX_Overflow OverflowReceive\n");
    else $display($stime,"\t\t FAIL::RX_Overflow not empty\n");

    ReadAddress(RxFrameLen, ReadLen );

    OverflowReceiveLen : assert (ReadLen == Size)
    //$display($stime,"\t\t PASS::RX_Len correct: %d\n",ReadLen);
    else $display($stime,"\t\t FAIL::RC_Len incorrect\n");

    for(int i = 0; i < ReadLen;i++) begin
      ReadAddress(RxBuff_Addr,ReadData);

      OverflowBuff : assert (ReadData == data[i])
      //$display($stime,"\t\t PASS::RX_Buff correct \n");
      else $display($stime,"\t\t FAIL::RC_Buff incorrect\n");
    end

    for(int i = 0; i < 10;i++) begin
      ReadAddress(RxBuff_Addr,ReadData);

      OverflowBuff : assert (ReadData == 0)
      //$display($stime,"\t\t PASS::RX_Buff zero\n");
      else $display($stime,"\t\t FAIL::RC_Buff not zero\n");
    end

  endtask

  task VerifyFCSerrReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData, ReadLen;

    ReadAddress(RxSC_Addr, ReadData );

    FCSERR : assert (ReadData & RXSC_FRAMEERROR) begin
      //$display($stime,"\t\t PASS::RX_FramError generated\n");
    end else begin
      $display($stime,"\t\t FAIL::RX_FramError not generated\n");
    end

    @(posedge uin_hdlc.Clk);
    ReadAddress(RxBuff_Addr, ReadData);

    Err_Assert : assert (ReadData == '0) begin
      //$display($stime,"\t\t PASS::Frame empty after error\n");
    end else begin
      $display($stime,"\t\t FAIL::Frame not empty after error\n");
    end




  endtask

  task VerifyDropReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData, ReadLen;

    WriteAddress(RxSC_Addr,RXSC_DROPED);

    @(posedge uin_hdlc.Clk);
    ReadAddress(RxBuff_Addr, ReadData);

    Drop_Assert : assert (ReadData == '0) begin
      //$display($stime,"\t\t PASS::Frame dropped\n");
    end else begin
      $display($stime,"\t\t FAIL::Frame not dropped\n");
    end

  endtask


  

  // TRANSMIT
  task VerifyAbortTransmit(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;

    ReadAddress(TxSC_ADDR_CONST, ReadData);
    //RxSC_Read_mask
    abortSignal : assert (ReadData & 8'b00001000) begin 
      //$display($stime,"\t\t PASS::RX_AbortSignal correct\n");
    end else begin 
       $display($stime,"\t\t FAIL::RX_AbortSignal wrong\n");
    end


    ReadAddress(3'h3, ReadData);

    abortBuffEmpty : assert (ReadData == 8'h0) begin
      //$display($stime,"\t\t PASS::RX_Buff empty\n");
    end else begin 
      $display($stime,"\t\t FAIL::RX_Buff not empty\n");
    end


  endtask

  task VerifyNormalTransmit(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData, ReadLen;
    wait(uin_hdlc.Rx_Ready);


    ReadAddress(3'h2, ReadData);

    
    NormalSC0 : assert ((ReadData & RXSC_READY) == TRUE)
    //$display($stime,"\t\t PASS::Rx Status Ready OK \n");
    else $display($stime,"\t\t FAIL::Rx Status Ready\n");

    NormalSC1 : assert ((ReadData & RXSC_DROPED) == FALSE)
    //$display($stime,"\t\t PASS::RxSC frame dropped OK\n");
    else $display($stime,"\t\t FAIL::RxSC Frame drop\n");

    NormalSC2 : assert ((ReadData & RXSC_FRAMEERROR) == FALSE)
    //$display($stime,"\t\t PASS::RXSC_FRAMEERROR OK \n");
    else $display($stime,"\t\t FAIL::RXSC_FRAMEERROR\n");

    NormalSC3 : assert ((ReadData & RXSC_ABORT_SIGNAL) == FALSE)
    //$display($stime,"\t\t PASS::RXSC_ABORT_SIGNAL Abort signal OK \n");
    else $display($stime,"\t\t FAIL::RXSC_ABORT_SIGNAL Fail Abort signal\n");

    NormalSC4 : assert ((ReadData & RXSC_OVERFLOW_EN) == FALSE)
    //$display($stime,"\t\t PASS::RXSC_OVERFLOW_EN overflow signal OK\n");
    else $display($stime,"\t\t FAIL::RXSC_OVERFLOW_EN overflow signal fail\n");

    /*
    NormalSC5 : assert ((ReadData & RXSC_FCS_EN) == FALSE)
    //$display($stime,"\t\t PASS::RXSC_FCS_EN FCS error detection enabled signal OK\n");
    else $display($stime,"\t\t FAIL::RXSC_FCS_EN FCS error detectionEn fail\n");
    */

    ReadAddress(RxFrameLen, ReadLen );

    Normal : assert (ReadLen == Size)
    //$display($stime,"\t\t PASS::RX_Len correct: %d\n",ReadLen);
    else $display($stime,"\t\t FAIL::RC_Len incorrect\n");

    for(int i = 0; i < ReadLen;i++) begin
      ReadAddress(3'h3,ReadData);

      NormalBuff : assert (ReadData == data[i]) begin
      //$display($stime,"\t\t PASS::RX_Buff correct \n");
      end else $display($stime,"\t\t FAIL::RC_Buff incorrect\n");
    end

  
  endtask




  //4. Correct TX output according to written TX buffer.

  // TODO: 11. CRC generation and Checking.

  /****************************************************************************
   *                                                                          *
   *                             Simulation code                              *
   *                                                                          *
   ****************************************************************************/

  initial begin
    $display("*************************************************************");
    $display("%t - Starting Test Program", $time);
    $display("*************************************************************");

    Init();

    //Receive: Size, Abort, FCSerr, NonByteAligned, Overflow, Drop, SkipRead
    Receive( 10, 0, 0, 0, 0, 0, 0); //Normal
    Receive( 40, 1, 0, 0, 0, 0, 0); //Abort
    Receive(126, 0, 0, 0, 1, 0, 0); //Overflow
    Receive( 45, 0, 0, 0, 0, 1, 0); //Drop
    Receive(126, 0, 0, 0, 0, 0, 0); //Normal
    Receive(122, 1, 0, 0, 0, 0, 0); //Abort
    Receive(126, 0, 0, 0, 1, 0, 0); //Overflow
    Receive( 47, 0, 0, 1, 0, 0, 0); //NonByteAligned
    Receive( 25, 0, 1, 0, 0, 0, 0); //FCSerr
    

    Transmit(40, 0, 0); //Normal
    Transmit(100, 1, 0); //Abort
    Transmit(126, 0, 1); //Overflow
    Transmit(126, 0, 0); //Normal

    $display("*************************************************************");
    $display("%t - Finishing Test Program", $time);
    $display("*************************************************************");
    $stop;
  end

  final begin

    $display("*********************************");
    $display("*                               *");
    $display("* \tAssertion Errors: %0d\t  *", TbErrorCnt + uin_hdlc.ErrCntAssertions);
    $display("*                               *");
    $display("*********************************");

  end

  //Coverage
  covergroup rx_hdlc_cg @(posedge uin_hdlc.Clk);
    Address: coverpoint uin_hdlc.Address {
      bins Tx_SC = {0};
      bins Tx_Buff = {1};
      bins Rx_SC = {2};
      bins Rx_Buff = {3};
      bins Rx_Len = {4};
    }
    DataIn: coverpoint uin_hdlc.DataIn {
      bins zero = {0};
      bins low = {[0:50]};
      bins high = {[51:254]};
      bins max = {255};
    }
    DataOut: coverpoint uin_hdlc.DataOut {
      bins zero = {0};
      bins low = {[0:50]};
      bins high = {[51:254]};
      bins max = {255};
    }
    Rx_Data: coverpoint uin_hdlc.Rx_Data {
      bins zero = {0};
      bins low = {[0:50]};
      bins high = {[51:254]};
      bins max = {255};
    }
    Rx_ValidFrame: coverpoint uin_hdlc.Rx_ValidFrame {
      bins Rx_InvalidFrame = {0};
      bins Rx_ValidFrame = {1};
    }
    Rx_WrBuff: coverpoint uin_hdlc.Rx_WrBuff {
      bins not_Rx_wrBuff = {0};
      bins Rx_WrBuff = {1};
    }
    Rx_EoF: coverpoint uin_hdlc.Rx_EoF {
      bins not_Rx_EoF = {0};
      bins Rx_EoF = {1};
    }
    Rx_AbortSignal: coverpoint uin_hdlc.Rx_AbortSignal {
      bins not_Rx_AbortSignal = {0};
      bins Rx_AbortSignal = {1};
    }
    Rx_FrameError: coverpoint uin_hdlc.Rx_FrameError {
      bins not_Rx_FrameError = {0};
      bins Rx_FrameError = {1};
    }
    Rx_FCSerr: coverpoint uin_hdlc.Rx_FCSerr {
      bins not_Rx_FCSerr = {0};
      bins Rx_FCSerr = {1};
    }
    Rx_Ready: coverpoint uin_hdlc.Rx_Ready {
      bins not_Rx_ready = {0};
      bins Rx_ready = {1};
    }
    Rx_FrameSize: coverpoint uin_hdlc.Rx_FrameSize {
      bins zero = {0};
      bins low = {[0:50]};
      bins high = {[51:125]};
      bins max = {126};
    }
    Rx_Overflow: coverpoint uin_hdlc.Rx_Overflow {
      bins not_Rx_Overflow = {0};
      bins Rx_Overflow = {1};
    }
    Rx_Drop: coverpoint uin_hdlc.Rx_Drop {
      bins not_Rx_Drop = {0};
      bins Rx_Drop = {1};
    }
    Rx_AbortDetect: coverpoint uin_hdlc.Rx_AbortDetect {
      bins abortdetect[] = {[0:1]};
    }
  endgroup;

  covergroup tx_hdlc_cg @(posedge uin_hdlc.Clk);
    Tx_Data: coverpoint uin_hdlc.Tx_Data {
      bins zero = {0};
      bins low = {[0:50]};
      bins high = {[51:254]};
      bins max = {255};
    }
    Tx_ValidFrame: coverpoint uin_hdlc.Tx_ValidFrame {
      bins Tx_InvalidFrame = {0};
      bins Tx_ValidFrame = {1};
    }
    Tx_AbortedTrans: coverpoint uin_hdlc.Tx_AbortedTrans {
      bins not_Tx_AbortedTrans = {0};
      bins Tx_AbortedTrans = {1};
    }
    Tx_FrameSize: coverpoint uin_hdlc.Tx_FrameSize {
      bins zero = {0};
      bins low = {[0:50]};
      bins high = {[51:125]};
      bins max = {126};
    }
    Tx_Enable: coverpoint uin_hdlc.Tx_Enable {
      bins not_TXEN = {0};
      bins TXEN = {1};
    }
    Tx_Full: coverpoint uin_hdlc.Tx_Full {
      bins not_Tx_Full = {0};
      bins Tx_Full = {1};
    }
    Tx_AbortFrame: coverpoint uin_hdlc.Tx_AbortFrame {
      bins not_Tx_AbortFrame = {0};
      bins Tx_AbortFrame = {1};
    }
    Tx_DataAvail: coverpoint uin_hdlc.Tx_DataAvail {
      bins avail[] = {[0:1]};
    }
    Tx_WrBuff: coverpoint uin_hdlc.Tx_WrBuff {
      bins wrbuff[] = {[0:1]};
    }
  endgroup;

  rx_hdlc_cg rx_hdlc_cg_inst = new;
  tx_hdlc_cg tx_hdlc_cg_inst = new;

  // always @(posedge uin_hdlc.Clk) begin 
  //   rx_hdlc_cg_inst.sample();
  //   tx_hdlc_cg_inst.sample();
  // end
    

  task Init();
    uin_hdlc.Clk         =   1'b0;
    uin_hdlc.Rst         =   1'b0;
    uin_hdlc.Address     =   3'b000;
    uin_hdlc.WriteEnable =   1'b0;
    uin_hdlc.ReadEnable  =   1'b0;
    uin_hdlc.DataIn      =   1'b0;
    uin_hdlc.TxEN        =   1'b1;
    uin_hdlc.Rx          =   1'b1;
    uin_hdlc.RxEN        =   1'b1;

    TbErrorCnt = 0;

    #1000ns;
    uin_hdlc.Rst         =   1'b1;
  endtask

  task WriteAddress(input logic [2:0] Address ,input logic [7:0] Data);
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Address     = Address;
    uin_hdlc.WriteEnable = 1'b1;
    uin_hdlc.DataIn      = Data;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.WriteEnable = 1'b0;
  endtask

  task ReadAddress(input logic [2:0] Address, output logic [7:0] Data);
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Address    = Address;
    uin_hdlc.ReadEnable = 1'b1;
    #100ns;
    Data                = uin_hdlc.DataOut;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.ReadEnable = 1'b0;
  endtask

  task InsertFlagOrAbort(int flag);
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b0;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    if(flag)
      uin_hdlc.Rx = 1'b0;
    else
      uin_hdlc.Rx = 1'b1;
  endtask

  task MakeRxStimulus(logic [127:0][7:0] Data, int Size);
    logic [4:0] PrevData;
    PrevData = '0;
    for (int i = 0; i < Size; i++) begin
      for (int j = 0; j < 8; j++) begin
        if(&PrevData) begin
          @(posedge uin_hdlc.Clk);
          uin_hdlc.Rx = 1'b0;
          PrevData = PrevData >> 1;
          PrevData[4] = 1'b0;
        end

        @(posedge uin_hdlc.Clk);
        uin_hdlc.Rx = Data[i][j];

        PrevData = PrevData >> 1;
        PrevData[4] = Data[i][j];
      end
    end
  endtask
  
  task Receive(int Size, int Abort, int FCSerr, int NonByteAligned, int Overflow, int Drop, int SkipRead);
    logic [127:0][7:0] ReceiveData;
    logic       [15:0] FCSBytes;
    logic   [2:0][7:0] OverflowData;
    string msg;
    if(Abort)
      msg = "- Abort";
    else if(FCSerr)
      msg = "- FCS error";
    else if(NonByteAligned)
      msg = "- Non-byte aligned";
    else if(Overflow)
      msg = "- Overflow";
    else if(Drop)
      msg = "- Drop";
    else if(SkipRead)
      msg = "- Skip read";
    else
      msg = "- Normal";
    $display("*************************************************************");
    $display("%t - Starting task Receive %s", $time, msg);
    $display("*************************************************************");

    for (int i = 0; i < Size; i++) begin
      ReceiveData[i] = $urandom;
    end

    ReceiveData[Size-1] = 255;

    ReceiveData[Size]   = '0;
    ReceiveData[Size+1] = '0;

    //Calculate FCS bits;
    GenerateFCSBytes(ReceiveData, Size, FCSBytes);
    ReceiveData[Size]   = FCSBytes[7:0];
    ReceiveData[Size+1] = FCSBytes[15:8];
    
    if( FCSerr) begin
      ReceiveData[Size]   = FCSBytes[7:0] & 8'b0101_0101; 
      ReceiveData[Size+1] = FCSBytes[15:8] & 8'b1010_1010;
    end



    //Enable FCS
    if(!Overflow && !NonByteAligned)
      WriteAddress(RXSC, 8'h20);
    else
      WriteAddress(RXSC, 8'h00);

    //Generate stimulus
    InsertFlagOrAbort(1);
    
    MakeRxStimulus(ReceiveData, Size + 2);

    
    if(NonByteAligned) begin
      @(posedge uin_hdlc.Clk);
      uin_hdlc.Rx = 1'b0;
      @(posedge uin_hdlc.Clk);
      uin_hdlc.Rx = 1'b1;
      @(posedge uin_hdlc.Clk);
      uin_hdlc.Rx = 1'b0;
    end
    
    if(Overflow) begin
      OverflowData[0] = 8'h44;
      OverflowData[1] = 8'hBB;
      OverflowData[2] = 8'hCC;
      MakeRxStimulus(OverflowData, 3);
    end
    
    if(Abort) begin
      InsertFlagOrAbort(0);
    end else begin
      InsertFlagOrAbort(1);
    end
    
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    
    repeat(8)
    @(posedge uin_hdlc.Clk);
    
    if(Abort)
    VerifyAbortReceive(ReceiveData, Size);
    else if(Overflow)
    VerifyOverflowReceive(ReceiveData, Size);
    else if(FCSerr || NonByteAligned)
    VerifyFCSerrReceive(ReceiveData,Size);
    else if (Drop)
    VerifyDropReceive(ReceiveData,Size);
    else if(!SkipRead)
    VerifyNormalReceive(ReceiveData, Size);
    

    #5000ns;
  endtask

  task Transmit( int Size, int Abort, int Overflow);
    logic [127:0][7:0] TransmitData;
    logic       [15:0] FCSBytes;
    logic   [2:0][7:0] OverflowData;
    logic [7:0] count1s;
    logic [7:0] ReadData;
    string msg;
    if(Abort)
      msg = "- Abort";
      else if(Overflow)
      msg = "- Overflow";
      else
      msg = "- Normal";
      $display("*************************************************************");
    $display("%t - Starting task Transmit %s", $time, msg);
    $display("*************************************************************");

    uin_hdlc.Rst = 1'b1;

    wait(uin_hdlc.Tx_Done);
    for (int i = 0; i < Size; i++) begin
      @(posedge uin_hdlc.Clk);
      TransmitData[i] = $urandom;
      WriteAddress(TxBuff_Addr,TransmitData[i]);
    end

    if (Overflow) begin
      @(posedge uin_hdlc.Clk)
      WriteAddress(TxBuff_Addr,$urandom);
      @(posedge uin_hdlc.Clk)
      WriteAddress(TxBuff_Addr,$urandom);
      @(posedge uin_hdlc.Clk)
      WriteAddress(TxBuff_Addr,$urandom);
      @(posedge uin_hdlc.Clk)

      ReadAddress(TxSC_ADDR_CONST, ReadData);

      assert (ReadData & TXSC_REG_FULL_CONST) begin
        //$display($stime,"\t\t PASS::TX Full \n");
      end else begin
        $display($stime,"\t\t FAIL::TX Full Err\n");

      end
    end

    TransmitData[Size]   = '0;
    TransmitData[Size+1] = '0;

    //Calculate FCS bits;
    GenerateFCSBytes(TransmitData, Size, FCSBytes);
    TransmitData[Size]   = FCSBytes[7:0];
    TransmitData[Size+1] = FCSBytes[15:8];

    WriteAddress(TxSC_ADDR_CONST, TXSC_TX_ENABLED_CONST);

    @(negedge uin_hdlc.Tx);

    repeat(8) begin
      @(posedge uin_hdlc.Clk);
    end



    count1s = '0;
    for (int i = 0; i < Size; i++) begin
      //$display($stime,"\t\t Transmit: %x\n",TransmitData[i]);
      
      if(Abort && (i == Size/2)) begin
        break;
      end
      
      for( int j = 0; j < 8 ; j++) begin
        if (TransmitData[i][j]) begin
          count1s++;
        end else begin 
          count1s=0;
        end

        if (count1s >= 5) begin
          @(posedge uin_hdlc.Clk);
          assert (uin_hdlc.Tx == 0)  begin
            //$display($stime,"\t\t PASS::TX insert zero. TX=%b",uin_hdlc.Tx);
          end else begin
            $display($stime,"\t\t FAIL::TX insert zero fail. TX=%b",uin_hdlc.Tx);
          end
          count1s = '0;
          @(posedge uin_hdlc.Clk);
        end else begin
          assert (TransmitData[i][j] == uin_hdlc.Tx)
          begin
            //$display($stime,"\t\t pass::TX Data correct. TX=%b should be Data=%h\n",uin_hdlc.Tx,TransmitData[i][j]);
          end
          else begin
            $display($stime,"\t\t FAIL::TX Data incorrect. count=%d TX=%b should be Data=%h\n", count1s, uin_hdlc.Tx,TransmitData[i][j]);
          end
          @(posedge uin_hdlc.Clk);
        end
      end
    end

    if(Abort) begin 
      WriteAddress(TxSC_ADDR_CONST, TXSC_FRAME_ABORTED_CONST);
      @(posedge uin_hdlc.Clk);
      @(posedge uin_hdlc.Clk);
      ReadAddress(TxSC_ADDR_CONST, ReadData);

      assert (ReadData & TXSC_TX_ABORTED_CONST) begin 
        //$display($stime,"\t\t PASS::TX abort \n");
      end else begin
        $display($stime,"\t\t FAIL::TX abort fail\n");
      end

      repeat(16)
        @(posedge uin_hdlc.Clk);

    end else begin
      wait(uin_hdlc.Tx_NewByte);

      wait(uin_hdlc.Tx_WriteFCS);


      @(negedge uin_hdlc.Tx_ValidFrame);
      repeat(5)
        @(posedge uin_hdlc.Clk);
    end

    uin_hdlc.Rst = 1'b0;
      

    endtask

  task GenerateFCSBytes(logic [127:0][7:0] data, int size, output logic[15:0] FCSBytes);
    logic [23:0] CheckReg;
    CheckReg[15:8]  = data[1];
    CheckReg[7:0]   = data[0];
    for(int i = 2; i < size+2; i++) begin
      CheckReg[23:16] = data[i];
      for(int j = 0; j < 8; j++) begin
        if(CheckReg[0]) begin
          CheckReg[0]    = CheckReg[0] ^ 1;
          CheckReg[1]    = CheckReg[1] ^ 1;
          CheckReg[13:2] = CheckReg[13:2];
          CheckReg[14]   = CheckReg[14] ^ 1;
          CheckReg[15]   = CheckReg[15];
          CheckReg[16]   = CheckReg[16] ^1;
        end
        CheckReg = CheckReg >> 1;
      end
    end
    FCSBytes = CheckReg;
  endtask

endprogram
