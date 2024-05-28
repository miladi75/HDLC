//////////////////////////////////////////////////
// Title:   TxFCS
// Author:  Karianne Krokan Kragseth
// Date:    25.09.2017
//////////////////////////////////////////////////


module TxFCS(
  input logic               Clk,        //Clock
  input logic               Rst,        //Synchrouneous reset
  input logic               DataAvail,  //Data is available in TX buffer
  input logic               ValidFrame, //Transmitting valid TX frame
  input logic  [127:0][7:0] DataBuff,   //TX buffer
  input logic         [7:0] TxBuff,     //Next TX byte in buffer to be transmitted
  input logic         [7:0] FrameSize,  //Number of bytes in TX buffer
  input logic               WriteFCS,   //Transmit FCS byte
  input logic               StartFCS,   //Start FCS calculation
  output logic        [7:0] Data,       //Next TX byte to be transmitted
  output logic              FCSDone     //Finished calculating FCS bytes
);

  enum logic [2:0] {
    IDLE,
    CALC_FCS,
    RUN,
    FCS1,
    FCS2
  } FCSstate;
  logic [15:0] FCS_reg;         //FCS bytes
  logic  [7:0] FCSFrameCounter; //Number of bytes from TX buffer used in FCS calculation
  logic  [2:0] BitCounter;      //Number of bit in each byte used in FCS calculation

  always_ff @(posedge Clk or negedge Rst) begin : la_FCS
    if(~Rst) begin
      Data            <=   '1;
      FCS_reg         <=   '1;
      FCSstate        <= IDLE;
      FCSFrameCounter <=   '0;
      BitCounter      <=   '0;
      FCSDone         <= 1'b0;
    end else begin
      case (FCSstate)
        IDLE : begin
          Data            <=   '1;
          FCS_reg         <=   '0;
          FCSFrameCounter <=   '0;
          BitCounter      <=   '0;
          FCSDone         <= 1'b0;
          FCSFrameCounter <=   '0;
          if(StartFCS)
            FCSstate        <= CALC_FCS;
          else
            FCSstate        <= IDLE;
        end
        CALC_FCS : begin
          //Polonymial: 0x8005
          FCS_reg[0]    <= DataBuff[FCSFrameCounter][BitCounter] ^ FCS_reg[15];
          FCS_reg[1]    <= FCS_reg[0];
          FCS_reg[2]    <= FCS_reg[1] ^ FCS_reg[15];
          FCS_reg[14:3] <= FCS_reg[13:2];
          FCS_reg[15]   <= FCS_reg[14] ^ FCS_reg[15];

          Data    <= TxBuff;
          
          if(BitCounter == 7) begin
            BitCounter      <=   '0;
            FCSFrameCounter <= FCSFrameCounter + 1;
            if(FCSFrameCounter != (FrameSize+1)) begin //+1 because of 2 extra bytes with only zeros
              FCSstate <= CALC_FCS;
              FCSDone  <= 1'b0;
            end
            else begin
              FCSstate <=  RUN;
              FCSDone  <= 1'b1;
            end
          end
          else begin
            FCSstate        <= CALC_FCS;
            BitCounter      <= BitCounter + 1;
            FCSFrameCounter <= FCSFrameCounter;
          end
        end
        RUN : begin
          FCS_reg <= FCS_reg;
          
          if(DataAvail)
            Data <= TxBuff;
          else
            Data <= Data;

          if(!ValidFrame && !DataAvail)
            FCSstate <= IDLE;
          else if(WriteFCS)
            FCSstate <= FCS1;
          else
            FCSstate <= RUN;
        end
        FCS1 : begin
          FCS_reg  <= FCS_reg;

          if(!ValidFrame) begin
            FCSstate <= IDLE;
            Data     <= Data;
          end
          else if(WriteFCS) begin //Transmit second FCS byte
            FCSstate  <= FCS2;
            Data[7] <= FCS_reg[0];
            Data[6] <= FCS_reg[1];
            Data[5] <= FCS_reg[2];
            Data[4] <= FCS_reg[3];
            Data[3] <= FCS_reg[4];
            Data[2] <= FCS_reg[5];
            Data[1] <= FCS_reg[6];
            Data[0] <= FCS_reg[7];
          end
          else begin //Transmit first FCS byte
            FCSstate  <= FCS1;
            Data[7] <= FCS_reg[8];
            Data[6] <= FCS_reg[9];
            Data[5] <= FCS_reg[10];
            Data[4] <= FCS_reg[11];
            Data[3] <= FCS_reg[12];
            Data[2] <= FCS_reg[13];
            Data[1] <= FCS_reg[14];
            Data[0] <= FCS_reg[15];
          end
        end
        FCS2 : begin
          FCS_reg  <= FCS_reg;

          if(!ValidFrame) begin
            FCSstate <= IDLE;
            Data     <=   '0;
          end
          else if(WriteFCS) begin //Set Data='0 to stop Zero Insertion from stalling end flag generation
            FCSstate <= FCS2;
            Data     <=   '0;
          end
          else begin
            FCSstate <= FCS2;
          end
        end
      endcase
    end
  end


endmodule
