//////////////////////////////////////////////////
// Title:   assertions_hdlc
// Author:  
// Date:    
//////////////////////////////////////////////////

/* The assertions_hdlc module is a test module containing the concurrent
   assertions. It is used by binding the signals of assertions_hdlc to the
   corresponding signals in the test_hdlc testbench. This is already done in
   bind_hdlc.sv 

   For this exercise you will write concurrent assertions for the Rx module:
   - Verify that Rx_FlagDetect is asserted two cycles after a flag is received
   - Verify that Rx_AbortSignal is asserted after receiving an abort flag
*/





module assertions_hdlc (
  output int   ErrCntAssertions,

  input logic Clk,
  input logic Rst,

  input logic [2:0] Address,
  input logic       WriteEnable,
  input logic       ReadEnable,
  input logic [7:0] DataIn,
  input logic [7:0] DataOut,


  input logic Rx,
  input logic RxEN,

  input logic       Rx_ValidFrame,
  input logic [7:0] Rx_Data,
  input logic       Rx_AbortSignal,
  input logic       Rx_Ready,
  input logic       Rx_WrBuff,
  input logic       Rx_EoF,
  input logic [7:0] Rx_FrameSize,
  input logic       Rx_Overflow,
  input logic       Rx_FCSerr,
  input logic       Rx_FCSen,
  input logic [7:0] Rx_DataBuffOut,
  input logic       Rx_RdBuff,
  input logic       Rx_NewByte,
  input logic       Rx_StartZeroDetect,
  input logic       Rx_FlagDetect,
  input logic       Rx_AbortDetect,
  input logic       Rx_FrameError,
  input logic       Rx_Drop,
  input logic       Rx_StartFCS,
  input logic       Rx_StopFCS,
  input logic       RxD,
  input logic       ZeroDetect,

  input logic                 Tx,
  input logic                 TxEN,
  input logic                 Tx_Done,

  input logic                 Tx_ValidFrame,   
  input logic                 Tx_AbortedTrans, 
  input logic                 Tx_WriteFCS,     
  input logic                 Tx_InitZero,     
  input logic                 Tx_StartFCS,     
  input logic                 Tx_RdBuff,       

  input logic                 Tx_NewByte,

  input logic                 Tx_FCSDone,
  input logic [7:0]           Tx_Data, 

  input logic                 Tx_Full,
  input logic                 Tx_DataAvail,
  input logic        [7:0]    Tx_FrameSize,
  input logic [127:0][7:0]    Tx_DataArray,
  input logic        [7:0]    Tx_DataOutBuff,

  input logic       Tx_WrBuff,     
  input logic       Tx_Enable,    
  input logic [7:0] Tx_DataInBuff,
  input logic       Tx_AbortFrame
);

`include "Register_Addr_Constants.svh"


  initial begin
    ErrCntAssertions  =  0;
    
  end

  /*******************************************
   *  Verify correct Rx_FlagDetect behavior  *
   *******************************************/

   // compare each bit of signal with frame patterns defined in Register_Addr_Constants.svn over
   // several clock cycles
   /*
   function automatic logic [7:0] generate_pattern_from_sig(input logic[7:0] frame_pattern, input logic signal);
    logic [7:0] res_seq;
    res_seq = (signal == frame_pattern[0]);
    for (int i = 1; i <= 7; i++) begin 
      if (i < 7) begin
        res_seq = {res_seq, (signal == frame_pattern[i])};
      end
    end
    return res_seq;
  endfunction
  
  
  
  
  logic [7:0] count_Rx_frames;
  
  always_ff @(posedge Clk or negedge Rst)  begin : Rx_BitsCount
    if (~Rst) begin
      count_Rx_frames <= 1'h0;
    end else begin 
      if (Rx_ValidFrame && !Rx_Drop && !Rx_EoF) begin
        count_Rx_frames <= count_Rx_frames + 1'h1;
      end else begin
        count_Rx_frames <= 1'h0;
      end 
    end
  end
  */


  sequence sq_start_end_flag(signal);  
    !signal ##1 signal[*6] ##1 !signal;
  endsequence
  
  //Abort pattern generation and checking (1111_1110).
  sequence sq_abort_flag(signal);
    //generate_pattern_from_sig(ABORT_PATTERN, signal);
    !signal ##1 signal[*7];
  endsequence


  sequence sq_idle_flag(signal);
      signal[*8];
  endsequence

  sequence sq_zero(signal);
      !signal ##1 signal[*5] ##1 !signal;
  endsequence


  sequence sq_rx_data_zero(logic[7:0] data, logic rx_after_0);
    ( data ==? {    rx_after_0,7'b11111xx}) or
    ( data ==? {1'bx,rx_after_0,6'b11111x}) or
    ( data ==? {2'bxx,rx_after_0,5'b11111}) or
    ((data ==? {3'bxxx,rx_after_0,4'b1111}) && ($past(data, 8) ==? 8'b1xxxxxxx)) or
    ((data ==? {4'bxxxx,rx_after_0,3'b111}) && ($past(data, 8) ==? 8'b11xxxxxx)) or
    ((data ==? {5'bxxxxx,rx_after_0,2'b11}) && ($past(data, 8) ==? 8'b111xxxxx)) or
    ((data ==? {6'bxxxxxx,rx_after_0,1'b1}) && ($past(data, 8) ==? 8'b1111xxxx)) or
    ((data ==? {7'bxxxxxxx,rx_after_0}) && ($past(data, 8) ==? 8'b11111xxx));
  endsequence

  sequence sq_tx_data_zero(logic[7:0] data);
    ( data ==? 8'b111110xx) or
    ( data ==? 8'bx111110x) or
    ( data ==? 8'bxx111110) or
    ((data ==? 8'bxxx11111) && ($past(data, 8) ==? 8'b0xxxxxxx)) or
    ((data ==? 8'bxxxx1111) && ($past(data, 8) ==? 8'b10xxxxxx)) or
    ((data ==? 8'bxxxxx111) && ($past(data, 8) ==? 8'b110xxxxx)) or
    ((data ==? 8'bxxxxxx11) && ($past(data, 8) ==? 8'b1110xxxx)) or
    ((data ==? 8'bxxxxxxx1) && ($past(data, 8) ==? 8'b11110xxx));
  endsequence


  /****************
   *  Properties  *
   ****************/

// 3. Correct bits set in RX status/control register after receiving frame.

  property pr_Rx_SC;
    @(posedge Clk) disable iff(!Rst) $rose(Rx_EoF) |->
      if (Rx_FrameError)
        !Rx_Ready && !Rx_Overflow && !Rx_AbortSignal && Rx_FrameError
      else if (Rx_Overflow && Rx_AbortSignal)
        Rx_Ready && Rx_Overflow && Rx_AbortSignal && Rx_FrameError
      else if (Rx_AbortSignal)
        Rx_Ready && !Rx_Overflow && Rx_AbortSignal && !Rx_FrameError
      else if (Rx_Overflow)
        Rx_Ready && Rx_Overflow && !Rx_AbortSignal && !Rx_FrameError
      else
        Rx_Ready && !Rx_Overflow && !Rx_AbortSignal && !Rx_FrameError
  endproperty


  // 5. Check if flag sequence is detected
  property pr_Rx_FlagDetect;
    @(posedge Clk)disable iff(!Rst) sq_start_end_flag(Rx) |-> ##2 Rx_FlagDetect;
  endproperty


  property pr_Tx_FlagDetect;
    @(posedge Clk) disable iff(!Rst) !$stable(Tx_ValidFrame) ##0 $past(!Tx_AbortFrame,2) |-> ##[0:2] sq_start_end_flag(Tx);
  endproperty  
  


  //  6.Zero insertion and removal for transparent transmission.
  property pr_Tx_zero_insertion;
    @(posedge Clk) disable iff(!Rst || !Tx_ValidFrame) $rose(Tx_NewByte) ##1 sq_tx_data_zero(Tx_Data) |-> ##[12:25] sq_zero(Tx);
  endproperty
  
  property pr_Rx_zero_removal;
    logic rx_after_0;
    //@(posedge Clk) disable iff(!Rst ) $rose(Rx_ValidFrame) ##1 Rx[*5] and Rx_ValidFrame[*6]  |-> !Rx;
    @(posedge Clk) disable iff(!Rst || !Rx_ValidFrame ) sq_zero(Rx) ##1 (1,rx_after_0 = Rx) |-> ##[9:17] $rose(Rx_NewByte) ##1 sq_rx_data_zero(Rx_Data, rx_after_0);
  endproperty
  

  //   7. Idle pattern generation and checking (1111_1111 when not operating).
  property pr_Rx_Idle_pattern;
    @(posedge Clk) disable iff(!Rst || Rx_AbortDetect) sq_idle_flag(Rx) |=> !Rx_ValidFrame;
  endproperty

  property pr_Tx_Idle_pattern;
    @(posedge Clk) disable iff(!Rst) !Tx_ValidFrame && Tx_FrameSize == 8'b0 |-> sq_idle_flag(Tx);
  endproperty

  // 8.Abort pattern generation and checking (1111_1110).
  // Remember that the 0 must be sent first.

  property pr_Rx_abort_pattern;
    @(posedge Clk) disable iff(!Rst) sq_abort_flag(Rx) |-> ##2 $rose(Rx_AbortDetect);
  endproperty

  
  property pr_Tx_abort_pattern;
    @(posedge Clk) disable iff(!Rst) $rose(Tx_AbortedTrans) |-> ##2  sq_abort_flag(Tx);
  endproperty

  // 9. When aborting frame during transmission, Tx_AbortedTrans should be asserted.
  property pr_Tx_abort_during_transmission;
    @(posedge Clk) disable iff(!Rst) $rose(Tx_AbortFrame) && Tx_DataAvail ##1 $fell(Tx_AbortFrame) |=> $rose(Tx_AbortedTrans);
  endproperty

  // 10.Abort pattern detected during valid frame should generate Rx_AbortSignal.
  property pr_Rx_AbortSignal;  
    @(posedge Clk)disable iff(!Rst) (Rx_AbortDetect && Rx_ValidFrame) |=> Rx_AbortSignal;
  endproperty


  // 12.When a whole RX frame has been received, check if end of frame is generated.
  property pr_Rx_end_of_frame;
    @(posedge Clk) disable iff(!Rst) $fell(Rx_ValidFrame) |=> $rose(Rx_EoF);
  endproperty
  
  // 13.When receiving more than 128 bytes, Rx_Overflow should be asserted.
  property pr_Rx_overflow;
    @(posedge Clk) disable iff(!Rst || !Rx_ValidFrame) $rose(Rx_ValidFrame) ##0 $rose(Rx_NewByte)[->129] |=> $rose(Rx_Overflow);
  endproperty

  
  // 14. Rx_FrameSize should equal the number of bytes received in a frame (max. 126 bytes =128
  // bytes in buffer – 2 FCS bytes).
  property pr_Rx_framesize; 
    int numBytes = 0;
    @(posedge Clk) disable iff(!Rst) $rose(Rx_ValidFrame) ##0 (##[1:10] $rose(Rx_NewByte),numBytes++)[*1:128] ##[1:5] $rose(Rx_EoF) ##0 !Rx_FrameError |=> (Rx_FrameSize == numBytes - 2);
  endproperty

  

  // 15. Rx_Ready should indicate byte(s) in RX buffer is ready to be read.
  property pr_Rx_rd_bytes_ready;
    @(posedge Clk)disable iff(!Rst) $rose(Rx_Ready) |=> !Rx_EoF ##0 !Rx_FrameError;
    //!(Rx_WrBuff && Rx_NewByte) |=> Rx_RdBuff;
  endproperty

  
  
  // 16. Non-byte aligned data or error in FCS checking should result in frame error.
  // Normally Rx_NewByte and Rx_FlagDetect triggers at the same time, so a offset means the data is not byte aligned
  property pr_Non_byte_aligned;
    @(posedge Clk) disable iff(!Rst) $rose(Rx_NewByte) ##[1:7] $rose(Rx_FlagDetect) |-> ##2 $rose(Rx_FrameError);
  endproperty

  property pr_FCSerr;
    @(posedge Clk) disable iff(!Rst) $rose(Rx_FCSerr) |=> $rose(Rx_FrameError);
  endproperty

  // 17.Tx_Done should be asserted when the entire TX buffer has been read for transmission.
  property pr_Tx_Done;
    @(posedge Clk) disable iff(!Rst) $fell(Tx_DataAvail) |-> $past(Tx_Done,1);
  endproperty


  //  18.Tx_Full should be asserted after writing 126 or more bytes to the TX buffer (overflow).
  property pr_Tx_Full;
    @(posedge Clk) disable iff(!Rst || Tx_Done) $fell(Tx_Done) ##2 Tx_WrBuff[->125] |=> Tx_Full;
  endproperty


  /*
  always_ff @(posedge Clk or negedge Rst) begin
    $display($stime,,,"RX=%b validframe=%b newbyte=%b overflow=%b abortdetect=%b frameerror=%b flagdetect=%b rxdata=%x",
    Rx,Rx_ValidFrame,Rx_NewByte,Rx_Overflow, Rx_AbortDetect, Rx_FrameError, Rx_FlagDetect, Rx_Data);
  end
  always_ff @(posedge Clk or negedge Rst) begin
    $display($stime,,,"TX=%b validframe=%b dataAvail=%b txDone=%b",
    Tx,Tx_ValidFrame,Tx_DataAvail,Tx_Done);
  end
  */


  /****************
   *  Assertions  *
   ****************/

  //3

  RX_SC_Assert : assert property (pr_Rx_SC) begin
    //$display("PASS: Rx Status/Control\n");
  end else begin 
    $error("FAIL::Incorrect bits set in RX status/control register after receiving frame"); 
    ErrCntAssertions++; 
  end

   
  //5
  RX_FlagDetect_Assert : assert property (pr_Rx_FlagDetect) begin
    //$display("PASS: RX Flag detect");
  end else begin 
    $error("FAIL::RX Flag sequence did not generate FlagDetect"); 
    ErrCntAssertions++; 
  end

  TX_FlagDetect_Assert : assert property (pr_Tx_FlagDetect) begin
    //$display("PASS: TX Flag detect");
  end else begin 
    $error("FAIL::TX Flag sequence did not generate FlagDetect"); 
    ErrCntAssertions++; 
  end
  
  //6.Zero insertion and removal for transparent transmission.
  zero_insertion_Assertion: assert property (pr_Tx_zero_insertion) begin
    //$display("PASS::Zero_Insertion");
  end else begin 
    $error("FAIL::Tx_Zero_Insertion");
    ErrCntAssertions++;
  end

  zero_removal_Assertion: assert property (pr_Rx_zero_removal) begin
    //$display("PASS::Zero_Removal");
  end else begin 
    $error("FAIL::Rx_Zero_Removal");
    ErrCntAssertions++;
  end
  
  //7. Idle pattern generation and checking (1111_1111 when not operating).
  RX_Idle_Pattern_Assert: assert property (pr_Rx_Idle_pattern) begin
    //$display("PASS: RX Idle flag");
  end else begin
    $error("FAIL::RX Idle sequence not generated"); 
    ErrCntAssertions++; 
  end

  TX_Idle_Pattern_Assert: assert property (pr_Tx_Idle_pattern) begin
    //$display("PASS: TX Idle flag");
  end else begin
    $error("FAIL::TX Idle sequence not generated"); 
    ErrCntAssertions++; 
  end
  
  
  // 8.Abort pattern generation and checking (1111_1110).
  // Remember that the 0 must be sent first.

  RX_Abort_Pattern_Assert: assert property (pr_Rx_abort_pattern) begin
    //$display("PASS: RX Abort pattern generated");
  end else begin 
    $error("FAIL::RX abort pattern not generated"); 
    //$display($stime,"\t\t RX abort pattern not generated %0b = ",sq_abort_flag );
    ErrCntAssertions++; 
  end
  
  TX_Abort_Pattern_Assert: assert property (pr_Tx_abort_pattern) begin
    //$display("PASS: TX Abort pattern generated");
  end else begin 
    $error("FAIL::TX abort pattern not generated"); 
    ErrCntAssertions++; 
  end
  
  
  // 9. When aborting frame during transmission, Tx_AbortedTrans should be asserted.
  TX_Abort_During_Transmission_Assert: assert property (pr_Tx_abort_during_transmission) begin
    //$display("PASS: Assert during transmission");
  end else begin 
    $error("FAIL::AbortSignal did not go high after AbortDetect during validframe"); 
    ErrCntAssertions++; 
  end

// 10.Abort pattern detected during valid frame should generate Rx_AbortSignal.
  RX_AbortSignal_Assert : assert property (pr_Rx_AbortSignal) begin
    //$display("PASS: Abort signal");
  end else begin 
    $error("FAIL::Tx_AbortedTrans did not go high when aborting during transmission"); 
    ErrCntAssertions++; 
  end
  
  // 12.When a whole RX frame has been received, check if end of frame is generated.
  RX_end_of_frame: assert property (pr_Rx_end_of_frame) begin
    //$display("PASS::RX_end_of_frame, Whole RX frame has been received\n");
  end else begin 
    $error("FAIL::RX_end_of_frame, End of frame not received."); 
    ErrCntAssertions++; 
  end 

  // 13.When receiving more than 128 bytes, Rx_Overflow should be asserted.
  RX_Overflow_Assert: assert property (pr_Rx_overflow) begin
    //$display("PASS:RX Overflow signal generated");
  end else begin 
    $error("FAIL::RX_Overflow did not go high with more then when more than 128 bytes were received"); 
    ErrCntAssertions++; 
  end

  // 14. Rx_FrameSize should equal the number of bytes received in a frame (max. 126 bytes =128
  // bytes in buffer – 2 FCS bytes).
  
  

  RX_Framesize_Assert: assert property (pr_Rx_framesize) begin
    //$display("PASS: RX Framesize correct");
  end else begin 
    $error("FAIL::RX_Framesize not equal to number of received bytes"); 
    ErrCntAssertions++; 
  end
  

  // 15. Rx_Ready should indicate byte(s) in RX buffer is ready to be read.
  RX_rd_bytes_ready_Assert: assert property (pr_Rx_rd_bytes_ready) begin
    //$display("PASS:RX_rd_bytes_ready. Byte(s) in RX buffer is ready to be read");
  end else begin 
    $error("FAIL::RX_rd_bytes_ready. Byte(s) in RX buffer is NOT ready to be read"); 
    ErrCntAssertions++; 
  end

  // 16. Non-byte aligned data or error in FCS checking should result in frame error.
  Non_byte_aligned_Assert: assert property (pr_Non_byte_aligned) begin 
    //$display("PASS::pr_Non_byte_aligned frame in FCS PASS "); 
  end else begin
    $error("FAIL::Non_byte_aligned Non-byte aligned frame in FCS Frame Error"); 
    ErrCntAssertions++; 
  end

  FCSerr_Assert: assert property (pr_FCSerr) begin 
    //$display("PASS::error in FCS checking result in frame error"); 
  end else begin
    $error("FAIL::error in FCS checking did not result in frame error"); 
    ErrCntAssertions++; 
  end

  // 17.Tx_Done should be asserted when the entire TX buffer has been read for transmission.
  Tx_Done_Assert: assert property (pr_Tx_Done) begin
    //$display("PASS::Tx_Done  asserted when the entire TX buffer has been read for transmission");
  end else begin
    $error("FAIL::Tx_Done should be asserted when the entire TX buffer has been read for transmission");
    ErrCntAssertions++; 
  end

  // 18.Tx_Full should be asserted after writing 126 or more bytes to the TX buffer (overflow).

  Tx_Full_Assert: assert property(pr_Tx_Full) begin
    //$display("PASS:Tx_Full. TX buffer full ");
  end else begin
    $error("FAIL::Tx_full. TX buffer not full after writing 126 or more bytes to the Tx buffer");
    ErrCntAssertions++; 
  end



endmodule
