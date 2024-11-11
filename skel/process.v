`timescale 1ns / 1ps

module process(
	input clk,				// clock 
	input [23:0] in_pix,	// valoarea pixelului de pe pozitia [in_row, in_col] din imaginea de intrare (R 23:16; G 15:8; B 7:0)
	output [5:0] row, col, 	// selecteaza un rand si o coloana din imagine
	output out_we, 			// activeaza scrierea pentru imaginea de iesire (write enable)
	output [23:0] out_pix,	// valoarea pixelului care va fi scrisa in imaginea de iesire pe pozitia [out_row, out_col] (R 23:16; G 15:8; B 7:0)
	output mirror_done,		// semnaleaza terminarea actiunii de oglindire (activ pe 1)
	output gray_done,		// semnaleaza terminarea actiunii de transformare in grayscale (activ pe 1)
	output filter_done);	// semnaleaza terminarea actiunii de aplicare a filtrului de sharpness (activ pe 1)

	reg [5:0] row_reg, col_reg; // Cream variabilele de tip reg pentru a nu modifica antetul modulului (parametrii)
	reg out_we_reg;
	reg [23:0] out_pix_reg;
	reg mirror_done_reg;
	reg gray_done_reg;
	reg filter_done_reg;
	
	assign row = row_reg; // Facem legatura cu output-urile
	assign col = col_reg;
	assign out_we = out_we_reg;
	assign out_pix = out_pix_reg;
	assign mirror_done = mirror_done_reg;
	assign gray_done = gray_done_reg;
	assign filter_done = filter_done_reg;

	reg [23:0] pix1, pix2; // Pentru exercitiul 1, pix1 si pix2 sunt cele 2 variabile pentru interschimbarea pixelului din jumatatea de sus a imaginii cu cel din jumatatea de jos a imaginii
	reg [4:0] state, next_state; // Pentru automat
	reg [5:0] next_row; // Pentru automat
	reg [5:0] next_col; // Pentru automat
	reg [7:0] max, min; // Pentru exercitiul 2, maximul dintre R,G,B pentru fiecare pixel, respectiv minimul
	reg [23:0] pix3=0; // Pentru exercitiul 2
	reg [23:0] vec1, vec2, vec3, vec4, vec5, vec6, vec7, vec8; // pentru exercitiul 3, vecinii fiecarui pixel
	reg [14:0] sum; // Suma vecinilor pixelului, luata pe 15 biti in cel mai nefavorabil caz, cand 9*pixelul_din_centru este foarte mare fata de 8*(suma de vecini) sau invers, si asa sum poate da peste 8 biti.
	reg [7:0] pix4; // Pentru exercitiul 3
	reg [23:0] pix5=0; // Pentru exercitiul 3
	reg sign; // Pentru exercitiul 3, bitul de semn al rezultatului sumei elementelor dupa inmultirea element cu element a celor 2 matrici (cea cu vecini si sharpmatrix)
	
	always @(posedge clk) begin // Partea secventiala
		state <= next_state;
		row_reg <= next_row;
		col_reg <= next_col;
	end
	
	always @(*)begin // Partea combinationala
		case(state)
		
			// START - Mirror
		
			0:begin // Ne aflam la pixelul de sus
				out_we_reg=0; // Ne asiguram ca avem scrierea dezactivata
				pix1=in_pix; // Salvam pixelul respectiv intr-o variabila auxiliara denumita "pix1"
				next_row=63-row_reg; // Ne mutam pe linia simetrica fata de axul imaginar ce injumatateste matricea pe orizontala
				next_state=1; 
			end
			
			1:begin // Ne aflam la pixelul din jumatatea de jos
				pix2=in_pix; // Analog "pix2"
				next_state=2;
				out_we_reg=1; // Activam scrierea
			end
			
			2:begin // Suntem tot in partea de jos si putem deja modifica pixelul cu cel de sus salvat in pix1
				out_pix_reg=pix1; // Aici am modificat 
				next_row=63-row_reg; // Pentru urmatoarea stare ne intoarcem pe partea de sus
				next_state=3;
			end
			
			3:begin
				out_pix_reg=pix2; // Modificam
				if(col_reg==63)begin // Vrem sa repetam operatiile de la starile 0, 1, 2 si 3 pentru TOATE perechile de pixeli din matrice
					if(row_reg<31)begin // Asadar, vom analiza toate cazurile in care trebuie sa ne deplasam diferit
						next_row=row_reg+1; // Parcurgerea perechilor de pixeli este de la stanga la dreapta, dinspre periferia matricii spre axul ce desparte imaginea in 2 jumatati
						next_col=0; // Daca coloana este ultima si randul este pana in cel alaturat axului, evident vom trece pe randul urmator si vom reseta coloana la 0
						next_state=0; // De asemenea, vom repeta algoritmul 
					end
					else if(row_reg==31)begin // Stim ca am finalizat oglindirea imaginii atunci cand s-a ajuns la elementul de sus ca fiind pe pozitia (31,63)
						next_state=4; // Mai exact (linia imediat alaturata axului imaginar, ultima coloana disponibila), si asa putem trece in starea urmatoare si sa setam oglindirea ca fiind finalizata
					end
				end
				else if (col_reg<63)begin	// Daca coloana este pana in ultima, iar linia este oricare (poate fi si cea alaturata axului), putem trece la coloana urmatoare fara nicio problema
					next_col=col_reg+1;
					next_state=0;
				end
			end
			
			4:begin
				mirror_done_reg=1;
				next_state=5;
				out_we_reg=0;
			end
			
			// STOP - Mirror
			
			// START - Grayscale
			
			5:begin
				next_row=0; // Sensul de parcurgere al matricii va fi acelasi ca cel de la Mirror, doar ca ne oprim la elementul din coltul din dreapta jos
				next_col=0;
				next_state=6;
				out_we_reg=0;
			end
			
			6:begin            // R-> 23:16            G-> 15:8             B-> 7:0
				max=0;			// Cea mai mica valoare posibila
				min=255;			// Cea mai mare valoare posibila, potrivit algoritmului de max si min dintre mai multe numere
				if(max<in_pix[23:16])begin
					max=in_pix[23:16]; 
				end
				if(min>in_pix[23:16])begin
					min=in_pix[23:16]; 
				end
				if(max<in_pix[15:8])begin
					max=in_pix[15:8]; 
				end
				if(min>in_pix[15:8])begin
					min=in_pix[15:8]; 
				end
				if(max<in_pix[7:0])begin
					max=in_pix[7:0]; // max(R,G,B)
				end
				if(min>in_pix[7:0])begin
					min=in_pix[7:0]; // min(R,G,B)
				end
				next_state=7;
			end
			
			7:begin
				out_we_reg=1;
				pix3[15:8]=(min+max)/2; // Am luat o variabila "pix3" pe care s-o construim bucata cu bucata, dupa care s-o atribuim direct pixelului din imagine
				pix3[23:16]=0;
				pix3[7:0]=0;
				out_pix_reg=pix3; // Am modificat pixelul
				if(row_reg<63)begin // Aceeasi parcurgere doar ca pana la elementul din dreapta jos
					if(col_reg<63)begin
						next_col=col_reg+1;
						next_state=6; // Din nou, vrem sa repetam operatiile din starile 6 si 7 pentru TOTI pixelii din imagine
					end
					else if(col_reg==63)begin
						next_row=row_reg+1;
						next_col=0;
						next_state=6;
					end
				end
				else if(row_reg==63)begin
					if(col_reg<63)begin
						next_col=col_reg+1;
						next_state=6;
					end
					else if(col_reg==63)begin
						next_state=8; // Daca am ajuns la elementul (63,63), stim sigur ca am finalizat Grayscale-ul
					end
				end
			end
			
			8:begin  // Ne pregatim
				gray_done_reg=1;
				out_we_reg=0;
				next_state=9;
			end
			
			// STOP - Grayscale
			
			// START - Filter
			
			9:begin    // Incepem de la elementul (0,0), acelasi sens de parcurgere ca la Grayscale
				next_row=0;
				next_col=0;
				next_state=10;
			end
						
			      //START - aflam vecinii dupa cazuri
				  
				   // Vecinul din stanga-sus - START
						
			10:begin    
				out_we_reg=0;
				if(row_reg==0 || col_reg==0 ||(row_reg==0 && col_reg==0))begin // Daca pixelul curent se afla pe prima linie SAU prima coloana SAU in colt (stiu ca e inclus intr-una din cele 2 conditii,
					vec1=0;																		// insa l-am scris pentru lizibilitate), atunci clar acesta nu are vecin in partea din stanga-sus
					next_state=12; // Evident, daca nu are vecin in partea din stanga-sus, sarim peste starea in care aflam vecinul deoarece l-am si considerat 0 din start si nu are sens
				end               // Prin urmare, mergem direct la starea in care verificam urmatorul tip de vecin, si anume cel de sus
				else begin // Daca poate sa aiba vecin in stanga sus, ne ducem acolo si il luam
					next_col=col_reg-1; // Ne ducem cu o coloana in spate
					next_row=row_reg-1; // Ne ducem cu o linie in spate, pentru ca asta inseamna stanga-sus fata de pixelul curent
					next_state=11;
				end
			end
			
			11:begin // Ne aflam la vecin
				vec1=in_pix[23:16]; // L-am memorat
				next_row=row_reg+1; // DAR trebuie sa ne si intoarcem la pixelul pentru care voiam sa aflam toti vecinii
				next_col=col_reg+1;
				next_state=12;
			end			
			
					//vecinul din stanga-sus - STOP
					
					// Vecinul de sus - START
			
			12:begin
				if(row_reg==0) begin // Daca e pe prima linie, nu are vecin sus
					vec2=0;
					next_state=14;
				end
				else begin // Daca poate sa aiba vecin in sus, ne ducem acolo si il luam
					next_row=row_reg-1;
					next_state=13;
				end 
			end
			
			13:begin  // L-am luat si ne intoarcem unde eram
				vec2=in_pix[23:16];
				next_row=row_reg+1;
				next_state=14;
			end
			
					// Vecinul de sus - STOP
					
					// Vecinul din dreapta-sus - START
			
			14:begin
				if(row_reg==0 || col_reg==63 || (row_reg==0 && col_reg==63)) begin // Daca e pe prima linie, ultima coloana sau colt dreapta sus, nu are vecin
					vec3=0;
					next_state=16;
				end
				else begin // Daca poate avea, mergem si-l luam
					next_row=row_reg-1;
					next_col=col_reg+1;
					next_state=15;
				end
			end					
			
			15:begin
				vec3=in_pix[23:16];
				next_row=row_reg+1;
				next_col=col_reg-1;
				next_state=16;
			end
			
					// Vecinul din dreapta-sus - STOP
					
					// Vecinul din dreapta - START
			
			16:begin
				if(col_reg==63)begin // Daca e pe ultima coloana, nu are vecin
					vec4=0;
					next_state=18;
				end
				else begin // Daca are mergem si-l luam
					next_col=col_reg+1;
					next_state=17;
				end
			end
			
			17:begin
				vec4=in_pix[15:8];
				next_col=col_reg-1;
				next_state = 18;
			end
			
					// Vecinul din dreapta - STOP
					
					// Vecinul din dreapta-jos - START
			
			18:begin 
				if(row_reg==63 || col_reg==63 || (row_reg==63 && col_reg ==63))begin // Daca e pe ultima coloana, ultima linie sau colt dreapta-jos, nu are vecin
					vec5=0;
					next_state=20;
				end
				else begin // Daca are mergem si-l luam
					next_col=col_reg+1;
					next_row=row_reg+1;
					next_state=19;
				end
			end
			
			19:begin
				vec5=in_pix[15:8];
				next_col=col_reg-1;
				next_row=row_reg-1;
				next_state=20;
			end
			
					// Vecinul din dreapta-jos - STOP
					
					// Vecinul de jos - START
			
			20:begin 
				if(row_reg==63)begin // Daca e pe ultima linie, nu are vecin
					vec6=0;
					next_state=22;
				end
				else begin // Daca are, mergem si il luam
					next_row=row_reg+1;
					next_state=21;
				end
			end
			
			21:begin
				vec6=in_pix[15:8];
				next_row=row_reg-1;
				next_state=22;
			end
			
					// Vecinul de jos - STOP
					
					// Vecinul din stanga-jos - START
			
			22:begin 
				if(col_reg==0 || row_reg==63 || (col_reg==0 && row_reg==63))begin // Daca e pe prima coloana, ultima linie sau coltul din stanga-jos, nu are vecin
					vec7=0;
					next_state=24;
				end
				else begin // Daca are mergem si-l luam
					next_row=row_reg+1;
					next_col=col_reg-1;
					next_state=23;
				end
			end
			
			23:begin
				vec7=in_pix[15:8];
				next_row=row_reg-1;
				next_col=col_reg+1;
				next_state=24;
			end
			
					// Vecinul din stanga-jos - STOP
					
					// Vecinul din stanga - START
			
			24:begin 
				if(col_reg==0)begin // Daca e pe prima coloana, nu are vecin 
					vec8=0;
					next_state=26;
				end
				else begin // Daca are, mergem si-l luam
					next_col=col_reg-1;
					next_state=25;
				end
			end
			
			25:begin
				vec8=in_pix[23:16];
				next_col=col_reg+1;
				next_state=26;
			end
			
					// Vecinul din stanga - STOP
			
					// STOP - Am aflat toti cei 8 vecini (vec1, vec2, vec3, vec4, vec5, vec6, vec7 si vec8)
					
					// NOTA FOARTE IMPORTANTA : Daca ati observat, la unii vecini am extras valoarea din bitii [23:16] si la altii din [15:8]. De ce ?
					//                          Fiindca atunci cand modificam valoarea unui pixel, acest pixel va deveni la randul sau vecin pentru alt pixel.
					//                          Practic trebuie sa ne gandim la o metoda de a salva versiunea veche INAINTE de a modifica valoarea din G.
					//                          Am ales sa profit de faptul ca datorita exercitiului 2 acum R si B sunt goale pentru fiecare pixel.
					//                          Am salvat versiunea veche a informatiei din canalul G in canalul R.
					//                          DOAR in cazurile pentru vecinii din : stanga, stanga-sus, sus, dreapta-sus am extras vecinul din bitii [23:16] (versiunea veche a lui G)
					//                               fiindca sensul meu de parcurgere este linie cu linie, de la stanga la dreapta. Mai exact, la vecinii din : dreapta, dreapta-jos
					//                               jos, stanga-jos inca nu am ajuns sa fac modificari, deci nu am de ce sa extrag din [23:16] intrucat acesta este gol. Extrag
					//                               din [15:8] G-ul si atat.
			
			26:begin
				pix4=in_pix[15:8]; // Salvam informatia din G inainte de a modifica pixelul intr-o variabila "pix4" ca sa nu ne incurcam momentan.
				sum=vec1+vec2+vec3+vec4+vec5+vec6+vec7+vec8; // Facem suma doar a vecinilor mai intai (suma care practic este negativa)
				if(sum>9*pix4)begin // Daca modulul partii negative este mai mare decat modulul partii pozitive, bitul de semn devine 1 (rezultat negativ)
					sign=1;
					sum=sum-9*pix4;
				end
				else begin // Altfel, bitul de semn devine 0 si calculam suma propriu-zisa, cea finala.
					sign=0;
					sum=9*pix4-sum;
				end
				next_state=27;
			end
			
			27:begin
				out_we_reg=1; //  Activam scrierea
				if(sign==1)sum=0; // Daca suma este negativa, o facem 0.
				else if(sum>255)sum=255; // Daca este pozitiva si mai este si mai mare decat 255, o facem chiar 255.
				pix5[15:8]=sum[7:0]; // Construim bucata cu bucata pixelul dorit intr-o variabila "pix5", incepand prin a salva suma in canalul G. Pix5 a fost initializat cu 0, deci are B = 0
				pix5[23:16]=pix4; // Pe canalul R plasam informatia veche din canalul G
				out_pix_reg=pix5; // Inlocuim cu totul pixelul curent cu cel creat pe bucati
				if(row_reg<63)begin // Aceeasi parcurgere
					if(col_reg<63)begin
						next_row=row_reg;
						next_col=col_reg+1;
						next_state=10; // Aceeasi regula, repetam operatiile din starile 9 ... 27 pentru TOTI pixelii
					end
					else if(col_reg==63)begin
						next_row=row_reg+1;
						next_col=0;
						next_state=10;
					end
				end
				else if(row_reg==63)begin
					if(col_reg<63)begin
						next_row=row_reg;
						next_col=col_reg+1;
						next_state=10;
					end
					else if(col_reg==63)begin
						next_row=0;
						next_col=0;
						next_state=28; // Cand am ajuns la elementul (63,63) stim ca am finalizat Filter-ul
						pix5=0;
					end
				end
			end
			
			28:begin // Insa sa nu uitam de faptul ca noi acum in R avem versiunile vechi ale tuturor pixelilor, trebuie sa le facem la loc 0
				pix5=in_pix;
				pix5[23:16]=0;
				out_pix_reg=pix5;
				if(row_reg<63)begin // Aceeasi regula de parcurgere
					if(col_reg<63)begin
						next_col=col_reg+1;
						next_state=28;
					end
					else if(col_reg==63)begin
						next_row=row_reg+1;
						next_col=0;
						next_state=28;
					end
				end
				else if(row_reg==63)begin
					if(col_reg<63)begin
						next_col=col_reg+1;
						next_state=28;
					end
					else if(col_reg==63)begin
						next_row=0;
						next_col=0;
						next_state=29;
					end
				end
			end
			
			29:begin
				filter_done_reg=1;
				out_we_reg=0;
				next_row=row_reg;
				next_col=col_reg;
				next_state=29;
			end
			
			// STOP - Filter
				
			default:begin // De aici se intra in automat, setam toate flag-urile pe 0 si ne pregatim sa incepem Mirror-ul
				next_state = 0;
				next_row = 0;
				next_col = 0;
				out_we_reg = 0;
				mirror_done_reg = 0;
				gray_done_reg = 0;
				filter_done_reg = 0;
			end
		endcase
	end
endmodule
