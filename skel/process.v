`timescale 1ns / 1ps

module process(
    input clk,              // clock 
    input [23:0] in_pix,    // valoarea pixelului de pe pozitia [in_row, in_col] din imaginea de intrare (R 23:16; G 15:8; B 7:0)
    output reg [5:0] row, col,  // selecteaza un rand si o coloana din imagine
    output reg out_we,          // activeaza scrierea pentru imaginea de iesire (write enable)
    output reg [23:0] out_pix,  // valoarea pixelului care va fi scrisa in imaginea de iesire pe pozitia [out_row, out_col] (R 23:16; G 15:8; B 7:0)
    output reg mirror_done,  // semnaleaza terminarea actiunii de oglindire (activ pe 1)
    output reg gray_done,    // semnaleaza terminarea actiunii de transformare in grayscale (activ pe 1)
    output reg filter_done); // semnaleaza terminarea actiunii de aplicare a filtrului de sharpness (activ pe 1)

	reg [23:0] pix1, pix2;
	reg [5:0] state, next_state;
	reg [5:0] next_row;
	reg [5:0] next_col;
	reg [7:0] max, min;
	reg [23:0] pix3=0;
	reg [23:0] vec1, vec2, vec3, vec4, vec5, vec6, vec7, vec8;
	reg [14:0] sum;
	reg [7:0] pix4;
	reg [23:0] pix5=0;
	reg sign;
	
	always @(posedge clk) begin    
		state <= next_state;
		row <= next_row;
		col <= next_col;
	end
	
	always @(*)begin
		case(state)
			0:begin
				out_we=0;
				pix1=in_pix;
				next_row=63-row;
				next_col=col;
				next_state=1;
			end
			
			1:begin
				pix2=in_pix;
				next_col=col;
				next_row=row;
				next_state=2;
			end
			
			2:begin
				out_we=1;
				out_pix=pix1;
				next_row=63-row;
				next_col=col;
				next_state=3;
			end
			
			3:begin
				out_pix=pix2;
				if(col==63)begin
					if(row<31)begin
						next_row=row+1;
						next_col=0;
						next_state=0;
					end
					else if(row==31)begin
						next_row=row;
						next_col=col;
						next_state=4;
					end
				end
				else if (col<63)begin	
					next_row=row;
					next_col=col+1;
					next_state=0;
				end
			end
			
			4:begin
				mirror_done=1;
				out_we=0;
				next_row=row;
				next_col=col;
				next_state=5;
			end
			
			5:begin
				max=0;
				min=0;
				next_row=0;
				next_col=0;
				next_state=6;
			end
			
			6:begin            // R-> 23:16            G-> 15:8             B-> 7:0
				out_we=0;
				if(in_pix[23:16]>in_pix[15:8])begin
					max=in_pix[23:16];
					min=in_pix[15:8];
				end
				else begin 
					max=in_pix[15:8];
					min=in_pix[23:16];
				end
				if(max<in_pix[7:0])begin
					max=in_pix[7:0];
				end
				if(min>in_pix[7:0])begin
					min=in_pix[7:0];
				end
				next_state=7;
			end
			
			7:begin
				out_we=1;
				pix3[15:8]=(min+max)/2;
				pix3[23:16]=0;
				pix3[7:0]=0;
				out_pix=pix3;
				if(row<63)begin
					if(col<63)begin
						next_row=row;
						next_col=col+1;
						next_state=6;
					end
					else if(col==63)begin
						next_row=row+1;
						next_col=0;
						next_state=6;
					end
				end
				else if(row==63)begin
					if(col<63)begin
						next_row=row;
						next_col=col+1;
						next_state=6;
					end
					else if(col==63)begin
						next_row=row;
						next_col=col;
						next_state=8;
					end
				end
			end
			
			8:begin  // ne pregatim
				gray_done=1;
				out_we=0;
				next_row=row;
				next_col=col;
				next_state=9;
			end
			
			9:begin    // incepem din stanga sus
				next_row=0;
				next_col=0;
				next_state=10;
			end
						
			//START - aflam vecinii dupa cazuri
						
			10:begin    //vecinul din stanga sus - START
				out_we=0;
				if(row==0 || col==0 ||(row==0 && col==0))begin // daca poate sa aiba vecin in stanga sus, ne ducem acolo si il luam
					vec1=0;
					next_state=12;
				end
				else begin 
					next_col=col-1;
					next_row=row-1;
					next_state=11;
				end
			end
			
			11:begin // l-am luat si ne intoarcem unde eram
				vec1=in_pix[23:16];
				next_row=row+1;
				next_col=col+1;
				next_state=12;
			end			//vecinul din stanga sus - STOP
			
			12:begin
				if(row==0) begin
					vec2=0;
					next_state=14;
				end// daca poate sa aiba vecin in sus, ne ducem acolo si il luam
				else begin
					next_row=row-1;
					next_state=13;
				end 
			end
			
			13:begin  // l-am luat si ne intoarcem unde eram
				vec2=in_pix[23:16];
				next_row=row+1;
				next_state=14;
			end
			
			14:begin // dreapta-sus
				if(row==0 || col==63 || (row==0 && col==63)) begin
					vec3=0;
					next_state=16;
				end
				else begin
					next_row=row-1;
					next_col=col+1;
					next_state=15;
				end
			end
			
			15:begin
				vec3=in_pix[23:16];
				next_row=row+1;
				next_col=col-1;
				next_state=16;
			end
			
			16:begin // dreapta
				if(col==63)begin
					vec4=0;
					next_state=18;
				end
				else begin
					next_col=col+1;
					next_state=17;
				end
			end
			
			17:begin
				vec4=in_pix[15:8];
				next_col=col-1;
				next_state = 18;
			end
			
			18:begin // dreapta jos
				if(row==63 || col==63 || (row==63 && col ==63))begin
					vec5=0;
					next_state=20;
				end
				else begin
					next_col=col+1;
					next_row=row+1;
					next_state=19;
				end
			end
			
			19:begin
				vec5=in_pix[15:8];
				next_col=col-1;
				next_row=row-1;
				next_state=20;
			end
			
			20:begin // jos
				if(row==63)begin
					vec6=0;
					next_state=22;
				end
				else begin
					next_row=row+1;
					next_state=21;
				end
			end
			
			21:begin
				vec6=in_pix[15:8];
				next_row=row-1;
				next_state=22;
			end
			
			22:begin // stanga jos
				if(col==0 || row==63 || (col==0 && row==63))begin
					vec7=0;
					next_state=24;
				end
				else begin
					next_row=row+1;
					next_col=col-1;
					next_state=23;
				end
			end
			
			23:begin
				vec7=in_pix[15:8];
				next_row=row-1;
				next_col=col+1;
				next_state=24;
			end
			
			24:begin // stanga
				if(col==0)begin
					vec8=0;
					next_state=26;
				end
				else begin
					next_col=col-1;
					next_state=25;
				end
			end
			
			25:begin
				vec8=in_pix[23:16];
				next_col=col+1;
				next_state=26;
			end
			
			// STOP - am aflat vecinii
			
			26:begin
				pix4=in_pix[15:8];
				sum=vec1+vec2+vec3+vec4+vec5+vec6+vec7+vec8;
				if(sum>9*pix4)begin
					sign=1;
					sum=sum-9*pix4;
				end
				else begin
					sign=0;
					sum=9*pix4-sum;
				end
				next_state=27;
			end
			
			27:begin
				out_we=1;
				if(sign==1)sum=0;
				else if(sum>255)sum=255;
				pix5[15:8]=sum[7:0];
				pix4=in_pix[15:8];
				pix5[23:16]=pix4;
				out_pix=pix5;
				if(row<63)begin
					if(col<63)begin
						next_row=row;
						next_col=col+1;
						next_state=10;
					end
					else if(col==63)begin
						next_row=row+1;
						next_col=0;
						next_state=10;
					end
				end
				else if(row==63)begin
					if(col<63)begin
						next_row=row;
						next_col=col+1;
						next_state=10;
					end
					else if(col==63)begin
						next_row=0;
						next_col=0;
						next_state=28;
						pix5=0;
					end
				end
			end
			
			28:begin
				pix5=in_pix;
				pix5[23:16]=0;
				out_pix=pix5;
				if(row<63)begin
					if(col<63)begin
						next_row=row;
						next_col=col+1;
						next_state=28;
					end
					else if(col==63)begin
						next_row=row+1;
						next_col=0;
						next_state=28;
					end
				end
				else if(row==63)begin
					if(col<63)begin
						next_row=row;
						next_col=col+1;
						next_state=28;
					end
					else if(col==63)begin
						next_row=0;
						next_col=0;
						next_state=29;
					end
				end
			end
			
			29:begin
				filter_done=1;
				out_we=0;
				next_row=row;
				next_col=col;
				next_state=28;
			end
				
			default:begin
				next_state = 0;
				next_row = 0;
				next_col = 0;
				out_we = 0;
				mirror_done = 0;
				gray_done = 0;
				filter_done = 0;
			end
		endcase
	end
endmodule