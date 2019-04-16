*-----------------------------------------------------------
* Title      : EASyTicTacToe
* Written by : Adrian Sorge (tinf101313)
* Date       : 
* Description: Einfaches TicTacToe Spiel
*-----------------------------------------------------------

WHITE		equ	$00FFFFFF	;farbe weiss
GREEN		equ	$00008000	;farbe gruen
FIELD_SIZE 	equ	9		;groesse des Feldes

	org		$8000

field		ds.b	FIELD_SIZE	;fuer spielfeld
dr_cell		ds.b	1		;fuer zelle, die gezeichnet werden soll
player		ds.b	1		;fuer spieler, der an der reihe ist
moves		ds.b	1		;fuer anzahl der zuege
won		ds.b	1		;fuer anzeige, ob jemand gewonnen hat
won_player	ds.b	1		;fuer spieler, der gewonnen hat
won_line	ds.b	1		;welche linie gewonnen	hat 
lines		ds.b	8		;linien
best_line	ds.b	1		;beste linie
place_stone	ds.b	1		;platz,an dem das zeichen gesetzt werden soll

	org		$1000
x_offset	dc.w	$B4,$B4,$B4,$5A,$5A,$5A,$0,$0,$0	;X Offset fuer das Zeichnen der Symbole
y_offset	dc.w	$0,$5A,$B4,$0,$5A,$B4,$0,$5A,$B4	;Y Offset fuer das Zeichnen der Symbole
line_code	dc.w	%1110000000000000,%0001110000000000,%0000001110000000
		dc.w	%1001001000000000,%0100100100000000,%0010010010000000
		dc.w	%1000100010000000,%0010101000000000	;Bit Codes, um die Felder einer Reihe zu beschreiben
st_pl1_won	dc.b	'Spieler hat gewonnen',0	;String, der angezeigt wird, wenn der Spieler gewonnen hat
st_pl2_won	dc.b	'Computer hat gewonnen',0	;String, der angezeigt wird, wenn der Computer gewonnen hat		
st_reset	dc.b	'Fuer neues Spiel bitte r druecken',0	;String, der angezeigt wird, wenn das Spiel zuende ist
line_tab	dc.b	%10010010,%10001000,%10000101,%01010000
		dc.b	%01001011,%01000100,%00110001,%00101000
		dc.b	%00100110 ;Tabelle, die die Felder den einzelnen Reihen zuordnet


    ORG    $0400
START:                  
			move.b	#12,d0		;Ausschalten des Echos
			trap	#15		;Ausfuehren des Befehls
game_reset		bsr	init_field	;Initialisierung des Spielfeldes
			bsr	init_game	;zuruecksetzten aller Variablen
l_dr_update		bsr	dr_field	;zeichen des Spielfeldes
			cmp.b	#9,moves	;beende das spiel nach 8 zuegen
			beq	b_reset		;strung zum reset
			clr.l	d1		;loeschen des reg, in das das ergebnis der auslesens der tastatur geschrieben wird
			cmp.b	#1,player	;test, ob spieler, oder computer an der reihe sind
			bne	player2		;wenn computer, sprung
			move.b	#5,d0		;opcode fuer auslesen der tastatur
			trap #15		;ausfuehren des befehls
			sub.b	#$31,d1		;umwandlung ascii zu zahl
continue		lea	field,a1 	;zeiger auf das spielfeld
			cmp.b	#0,0(a1,d1)	;schauen, ob das feld an der eingegebenen Stelle frei ist
			bne	l_dr_update	;falls nicht, springe zurück zur eingabe
			move.b	player,0(a1,d1)	;falls frei, dann setzt spieler in feld			
			cmp.b	#1,player	;wechseln des spielers
			beq	c_pl2		;sprung, wenn 1
			move.b	#1,player	;wenn 2, dann 1
			jmp	c_pl_end	;sprung zum ende des wechsels
c_pl2			move.b	#2,player	;wenn 1, dann 2
c_pl_end		bsr	test_win	;testen, ob einer gewonnen hat
			add.b	#1,moves	;addiere 1 auf die zuege
			cmp.b	#1,won		;schauen, ob das spiel gewonnen
			bne	l_dr_update	;wenn nicht, dann zurück zum zeichnen
			bsr	dr_field	;wenn gewonnen, dann zeichen feld
			bsr	dp_won		;anzeigen der nachricht, dass das speil gewonnen ist
b_reset			lea	st_reset,a1	;laden des strings fuer reset in zeiger
l_reset			move.w	#0,d1		;laden der x pos fuer ausgabe
			move.w	#315,d2		;laden der y pos fuer ausgabe
			move.b	#95,d0		;laden des opcodes
			trap	#15		;ausfuehre des befehls
			clr.l	d1		;loeschen des registers fuer eingabe
			move.b	#5,d0		;opcode fuer einlesen
			trap #15		;ausfuehren des befehls
			cmp.b	#$72,d1		;vergleichen, ob r
			beq	game_reset	;wenn ja, reset
			jmp	l_reset		;wenn nein, schleife, bis r kommt
player2			bsr	eval_lines	;auswerten der linien
			move.b	place_stone,d1	;laden des platzierten steines 
			jmp	continue	;ruecksprung zum platzieren des steines

*-----------------------------------------------------------
* Funktionen, um etwas auf dem Bildschirm anzuzeigen
*-----------------------------------------------------------

*-----------------------------------------------------------
* sc_white	-	setze den stift auf weiss
* Parameter 	: 	keine
* Rueckgabe     : 	keine
* lokale var	: 	d1: farbe,d0 opcode
*-----------------------------------------------------------
sc_white		movem.l d0-d1,-(a7)	;Funktion, um die Farbe des pen auf weiss zu setzen
			move.l	#WHITE,d1	;kopiere gewuenschte Farbe in Register
			move.b	#80,d0		;lade befehl in register
			trap	#15		;fuehre befehl aus
			movem.l	(a7)+,d0-d1
			rts
			
*-----------------------------------------------------------
* sc_white	-	setze den stift auf gruen
* Parameter 	: 	keine
* Rueckgabe     : 	keine
* lokale var	: 	d1: farbe,d0 opcode
*-----------------------------------------------------------

sc_green		movem.l d0-d1,-(a7)	;Funktion, um die Farbe des pen auf gruen zu setzen
			move.l	#GREEN,d1	;kopiere gewuenschte Farbe in Register
			move.b	#80,d0		;lade befehl in register
			trap	#15		;fuehre befehl aus
			movem.l	(a7)+,d0-d1
			rts

*-----------------------------------------------------------
* dr_l1		-	male eine linie
* Parameter 	: 	keine
* Rueckgabe     : 	keine
* lokale var	: 	d1:x1,d2:y1,d3:x2,d4:y2,d0:opcode
*-----------------------------------------------------------
			
dr_l1       		movem.l d0-d4,-(a7) 	;Funktion, erste vertikale linie zu zeichnen
			move.l  #90,d1      	;lade x1 in register
			move.l  #0,d2       	;lade y1 in register
			move.l  #90,d3      	;lade x2 in register
			move.l  #270,d4     	;lade y2 in register
			move.b  #84,d0      	;lade befehl in register
       			trap    #15         	;fuehre befehl aus
       			movem.l (a7)+,d0-d4
      			rts

*-----------------------------------------------------------
* dr_l2		-	male eine linie
* Parameter 	: 	keine
* Rueckgabe     : 	keine
* lokale var	: 	d1:x1,d2:y1,d3:x2,d4:y2,d0:opcode
*-----------------------------------------------------------



dr_l2       		movem.l d0-d4,-(a7) 	;Funktion, zweite vertikale linie zu zeichnen
			move.l  #180,d1     	;lade x1 in register
			move.l  #0,d2       	;lade y1 in register
			move.l  #180,d3     	;lade x2 in register
			move.l  #270,d4     	;lade y2 in register
			move.b  #84,d0      	;lade befehl in register
			trap    #15         	;fuehre befehl aus
			movem.l (a7)+,d0-d4
			rts

*-----------------------------------------------------------
* dr_l3		-	male eine linie
* Parameter 	: 	keine
* Rueckgabe     : 	keine
* lokale var	: 	d1:x1,d2:y1,d3:x2,d4:y2,d0:opcode
*-----------------------------------------------------------


dr_l3       		movem.l d0-d4,-(a7) 	;Funktion, erste horizontale linie zu zeichnen
			move.l  #0,d1       	;lade x1 in register
			move.l  #90,d2      	;lade y1 in register
			move.l  #270,d3     	;lade x2 in register
			move.l  #90,d4      	;lade y2 in register
			move.b  #84,d0      	;lade befehl in register
			trap    #15         	;fuehre befehl aus
            		movem.l (a7)+,d0-d4
			rts

*-----------------------------------------------------------
* dr_l4		-	male eine linie
* Parameter 	: 	keine
* Rueckgabe     : 	keine
* lokale var	: 	d1:x1,d2:y1,d3:x2,d4:y2,d0:opcode
*-----------------------------------------------------------

dr_l4       		movem.l d0-d4,-(a7) 	;Funktion, zweite horizontale linie zu zeichnen
			move.l  #0,d1       	;lade x1 in register
			move.l  #180,d2     	;lade y1 in register
			move.l  #270,d3     	;lade x2 in register
			move.l  #180,d4     	;lade y2 in register
			move.b  #84,d0      	;lade befehl in register
			trap    #15         	;fuehre befehl aus
			movem.l (a7)+,d0-d4
			rts

*-----------------------------------------------------------
* dr_cross	-	zeichne ein kreuz
* Parameter 	: 	dr_cell feld, in das das kreuz gezeichnet werden soll
* Rueckgabe     : 	keine
* lokale var	: 	d0:opcode,d1:x1,d2:y1,d3:x2,d4:y2,d5:zelle
*-----------------------------------------------------------
			
			
dr_cross    		movem.l d0-d5/a1-a2,-(a7) ;Funktion, zweite horizontale linie zu zeichnen
			lea	y_offset,a1	;lade y offset
			lea	x_offset,a2	;lade x offset
			move.b	dr_cell,d5	;lade feld, das gezeichnet werden soll
			asl.w	#1,d5		;da die adressen in word sind, muss die variable verdoppelt werden
			move.l  #0,d1       	;lade x1 in register
			add.w	0(a1,d5),d1	;addiere x offset
			move.l  #0,d2     	;lade y1 in register
			add.w	0(a2,d5),d2	;addiere y offset
			move.l  #90,d3     	;lade x2 in register
			add.w	0(a1,d5),d3	;addiere x offset
			move.l  #90,d4     	;lade y2 in register
			add.w	0(a2,d5),d4	;addiere y offset
			move.b  #84,d0      	;lade befehl in register
			trap    #15         	;fuehre befehl aus
			move.l  #90,d1       	;lade x1 in register
			add.w	0(a1,d5),d1	;addiere x offset
			move.l  #0,d2     	;lade y1 in register
			add.w	0(a2,d5),d2	;addiere y offset
			move.l  #0,d3     	;lade x2 in register
			add.w	0(a1,d5),d3	;addiere x offset
			move.l  #90,d4      	;lade y2 in register
			add.w	0(a2,d5),d4	;addiere y offset
			move.b  #84,d0      	;lade befehl in register
			trap    #15         	;fuehre befehl aus
			movem.l (a7)+, d0-d5/a1-a2
			rts

*-----------------------------------------------------------
* dr_circle	-	zeichne einen kries
* Parameter 	: 	dr_cell feld, in das das kreuz gezeichnet werden soll
* Rueckgabe     : 	keine
* lokale var	: 	d0:opcode,d1:x1,d2:y1,d3:x2,d4:y2,d5:zelle
*-----------------------------------------------------------
			
dr_circle   		movem.l d0-d5/a1-a2,-(a7) ;Funktion, zweite horizontale linie zu zeichnen
			lea	y_offset,a1	;lade y offset
			lea	x_offset,a2	;lade x offset
			move.b	dr_cell,d5	;lade feld, dass gezeichnet werden soll
			asl.w	#1,d5		;verschiebung, da adressen in w
			move.l  #0,d1       	;lade x1 in register
			add.w	0(a1,d5),d1	;addiere x offset
			move.l  #0,d2     	;lade y1 in register
			add.w	0(a2,d5),d2	;addiere y offset
			move.l  #90,d3    	;lade x2 in register
			add.w	0(a1,d5),d3	;addiere x offset
			move.l  #90,d4     	;lade y2 in register
			add.w	0(a2,d5),d4	;addiere y offset
			move.b  #88,d0      	;lade befehl in register
			trap    #15         	;zeichne kreis
			movem.l (a7)+, d0-d5/a1-a2
			rts

*-----------------------------------------------------------
* dr_field	-	zeiche das spielfeld 
* Parameter 	: 	keine
* Rueckgabe     : 	keine
* lokale var	: 	d0:opcode,d1:opcode2,d7:zaehlvariable
*-----------------------------------------------------------
			
dr_field    		movem.l d0-d1/d7/a1,-(a7)
			move.b  #11,d0		;lade opcode zum loeschen des bildschirms
			move.w	#$FF00,d1	;lade zusatz opcode
			trap    #15		;loesche bildschirm
			bsr sc_green		;setzte farbe zu gruen
 			bsr dr_l1		;zeiche erste linie
         		bsr dr_l2		;zeiche	zweite linie
            		bsr dr_l3		;zeichen dritte linie
            		bsr dr_l4		;zeichen vierte linie
            		move.b  #FIELD_SIZE,d7	;lade groesse des feldes
            		subq.b	#1,d7		;subtrahiere 1, fuer indizieren
            		lea field,a1		;lade pointer auf das feld
test_cell  		cmp.b	#0,0(a1,d7)	;schaue, ob feld leer
			beq	dr_p_end	;wenn leer, dann ende der switch
			bsr	sc_white	;setze stift auf weiss
			cmp.b	#1,0(a1,d7)	;schaue, ob feld 1
			beq	dr_p_1		;wenn 1, dann springe	
			move.b	d7,dr_cell	;wenn nicht, dann kopiere zelle in dr_cell
			bsr	dr_cross	;zeichne kreuz
			jmp	dr_p_end	;pringe zum ende der switch
dr_p_1			move.b	d7,dr_cell	;wenn 1, dann kopiere feld in dr_cell
			bsr	dr_circle	;male kreis
dr_p_end		subq.b	#1,d7		;subtrahiere 1 fuer die schleife
			bpl	test_cell	;wenn positiv, springe zu start der schleife
			movem.l (a7)+,d0-d1/d7/a1
			rts

*-----------------------------------------------------------
* dp_won	-	zeige string, wer gewonnen hat
* Parameter 	: 	won_player: welcher spieler gewonnen hat
* Rueckgabe     : 	keine
* lokale var	: 	d0:opcode,d1:xPos,d2:yPos
*-----------------------------------------------------------
			
dp_won			movem.l d0-d2/a1,-(a7)
			cmp.b	#1,won_player	;schaue, ob spieler 1 gewonnen hat
			beq	b_pl1_won	;wenn ja, dann springe
			lea	st_pl2_won,a1	;lade zeiger auf string fuer computer gewonnen
			jmp	b_pl_won_end	;springe zum ende
b_pl1_won		lea	st_pl1_won,a1	;lade zeiger auf string spieler gewonnen
b_pl_won_end		move.w	#0,d1		;setze x pos
			move.w	#300,d2		;setze y pos
			move.b	#95,d0		;lade opcode
			trap	#15		;gebe text aus
			movem.l	(a7)+,d0-d2/a1
			rts	

		
*-----------------------------------------------------------
* Funktionen, fuer das Spiel
*-----------------------------------------------------------


*-----------------------------------------------------------
* init_game	-	initialisiert der Spiel
* Parameter 	: 	keine
* Rueckgabe     : 	player:1,moves:0,won:0,won_player:0
* lokale var	: 	keine
*-----------------------------------------------------------

init_game		move.b	#1,player	;spieler beginnt
			move.b	#0,moves	;zuruecksetzen der zuege
			move.b	#0,won		;keiner hat gewonnen
			move.b	#0,won_player	;keiner hat gewonnen
			rts

*-----------------------------------------------------------
* init_lines	-	initialisiert alle linien mit 0
* Parameter 	: 	keine
* Rueckgabe     : 	lines:[0,0,0,0,0,0,0,0]
* lokale var	: 	d1:zaehlvariable
*-----------------------------------------------------------
			
init_lines		movem.l d1/a1,-(a7)
			lea	lines,a1	;lade zeiger auf linien
			move.b	#8,d1		;lade anzahl der linien
i_lines_s		subq.b	#1,d1		;beginn der schleife
			move.b	#0,(a1)+	;schreibe 0 in linie
			cmp.b	#0,d1		;vergleiche, ob fertig
			bne	i_lines_s	;wenn nicht, springe
			movem.l	(a7)+,d1/a1
			rts

*-----------------------------------------------------------
* init_field	-	initialisiert das spielfeld mit 0
* Parameter 	: 	keine
* Rueckgabe     : 	field:[0,0,0,0,0,0,0,0,0]
* lokale var	: 	d1:zaehlvariable
*-----------------------------------------------------------
			
			
init_field		movem.l d1/a1,-(a7)
			lea	field,a1	;lade zeiger auf feld
			move.b	#FIELD_SIZE,d1	;lade feldgroesse
i_field_s		subq.b	#1,d1		;subtrahiere 1
			move.b	#0,(a1)+	;setzte feld auf 0
			cmp.b	#0,d1		;schaue, ob fertig
			bne	i_field_s	;wenn nicht, springe zum anfang
			movem.l	(a7)+,d1/a1
			rts

*-----------------------------------------------------------
* test_win	-	teste, ob ein spieler gewonnen hat
* Parameter 	: 	keine
* Rueckgabe     : 	won, player_won
* lokale var	: 	d1:zwischenspeicher,d2:zaehlvariable
*-----------------------------------------------------------
			
			
			
test_win		movem.l d1-d2/a1,-(a7)
			lea	field,a1	;lade zeiger auf feld
			clr.l	d2		;loesche register fuer zaehlvariable
			cmp.b	#4,moves	;wenn noch keine 4 zuege, kann keiner gewonnen haben
			blt	test_win_end	;wenn wahr, dann sprung zum ende
			*testen der Horizontalen linien
hor_start		move.b	0(a1,d2),d1	;kopieren des ersten feldes der line nach d1
			cmp.b	#0,d1		;vergleichen, ob 0
			beq	hor_end		;wenn 0, dann ist diese linie nicht gewonnen
			cmp.b	1(a1,d2),d1	;vergleiche ob 2. feld gleich erstes feld
			beq	hor_2		;wenn ja, springe zu nächstem vergleich
			jmp	hor_end		;wenn nein, springe zum ende
hor_2			cmp.b	2(a1,d2),d1	;vergleiche 3. position mit der ersten
			beq	won_end		;wenn gleich, dann gewonnen
hor_end			add.b	#3,d2		;wenn nicht, dann nächste horizontale linie
			cmp.b	#6,d2		;vergleich, ob alle linen ueberprueft wurden
			ble	hor_start	;wenn nicht, springe zum start
			*testen der vertikalen linien
			move.b	#0,d2		;loeschen von zaehlvariable
ver_start		move.b	0(a1,d2),d1	;kopieren des ersten feldes	
			cmp.b	#0,d1		;vergleichen, ob 0
			beq	ver_end		;wenn ja, springe zum ende
			cmp.b	3(a1,d2),d1	;vergleiche erstes und zweites
			beq	ver_2		;wenn gleich, springe zum vergleich drittes
			jmp	ver_end		;wenn nicht, springe zum ende
ver_2			cmp.b	6(a1,d2),d1	;vergleiche erstes und drittes
			beq	won_end		;wenn gleich, dann spiel gewonnen
ver_end			add.b	#1,d2		;naechste linie
			cmp.b	#3,d2		;schaue, ob alle linien ueberprueft
			blt	ver_start	;wenn nicht, springe zum anfang
			*testen der schraegen
			move.b	0(a1),d1	;lade erstes element der ersten schraege
			cmp.b	#0,d1		;schaue, ob es 0 ist
			beq	sch_3		;wenn ja, dann springe zum ende
			cmp.b	4(a1),d1	;vergleiche mit 2. element
			beq	sch_2		;wenn gleich, dann vergleich mit drittem
			jmp	sch_3		;wen nicht, dann ende
sch_2			cmp.b	8(a1),d1	;vergleiche erstes mit drittem
			beq	won_end		;wenn gleich, dann gewonnen
sch_3			move.b	2(a1),d1	;lade erstes element der zweiten schraege
			cmp.b	#0,d1		;vergleiche mit 0
			beq	sch_end		;wenn ja, dann springe zum ende
			cmp.b	4(a1),d1	;vergleiche mit zweitem
			beq	sch_4		;wenn gleich, dann springe zum dritten vergleich
			jmp	sch_end		;springe zum ende
sch_4			cmp.b	6(a1),d1	;vergleiche erstes und drittes element 
			beq	won_end		;wenn gleich, dann gewonnen			
sch_end		
			*falls kein test einen sprung in die gewinn marke ausgeloest hat,			
			* pringe zum ende der funktion
			jmp	test_win_end	;spring zum ende der funktion
			*falls einer gewonnen hat
won_end			move.b	#1,won		;setze flag auf 1
			move.b	d1,won_player	;lade spieler, der gewonnen hat in variable
			*falls keiner gewonnen hat
test_win_end			
			movem.l	(a7)+,d1-d2/a1
			rts


*-----------------------------------------------------------
* eval_lines	-	wertet die linien aus
* Parameter 	: 	keine
* Rueckgabe     : 	place_stone,best_line
* lokale var	: 	d1:verschiebung des zeigers,d2:zaehlvariable,d3:zaehlvariable,d4:liniencode,d5:code der besten zeile
*-----------------------------------------------------------

eval_lines		movem.l d1-d5/a1-a3,-(a7)
			cmp.b	#0,won		;schauen, ob einer gewonnen hat
			bne	eval_end	;wenn ja, muss funktion nicht ausgefuehrt werden
			lea	field,a1	;lade zeiger auf feld
			lea	line_tab,a2	;lade zeiger auf tabelle der linien
			lea	lines,a3	;lade zeiger auf linien
			clr.l	d1		;loesche register
			clr.l	d2		;loesche register
			clr.l	d3		;loesche register
			clr.l	d4		;loesche register
			clr.l	d5		;loesche register
			bsr	init_lines	;initialisiere alle linien mit 0
l_sw			move.b	0(a1,d2),d1	;kopieren des wertes in dem auszuwertenden feldes
			clr.l	d3		;loeschen der zaehlvariable fuer innere schleife
			move.b	0(a2,d2),d4	;kopiere code der linie in register
			cmp.b	#2,d1		;test, um werte eindeutig zu machen
			bne	b_1		;wenn es eine 1 ist
			asl	#1,d1		;da 2 entweder zwei kriese oder ein kreuz bedeuten kann, wird das kreuz zu 4
b_1			asl.b	#1,d4		;zu ueberpruefendes bis wird in status register geschoben
			bcs	b_3		;wenn es eine relevante stelle ist
			jmp	b_2		;ueberspringe addition
b_3			add.b	d1,0(a3,d3)	;addiere wert des spielers (1:kreis,4:kreuz)
b_2			add.b	#1,d3		;erhoehe zaehlvariable
			cmp.b	#9,d3		;schaue, ob alle felder ueberprueft
			beq	b_end		;wenn alle felder durch, springe zur naechsten linie	
			jmp	b_1		;wenn nicht, springe zurück zur innneren schleife
b_end			add.b	#1,d2		;waehle naechste linie aus
			cmp.b	#8,d2		;vergleiche, ob alle durch
			bgt	l_end		;wenn alle linie durch, ende der zaehlung
			jmp	l_sw		;wenn nicht, springe zurück zur aeusseren schleife
l_end			clr.l	d1		;loesche register
			clr.l	d2		;loesche register
			*-----------------------
			*finden der besten linie
			*-----------------------
l_eval			cmp.b	#8,0(a3,d1)	;schaue, ob linie eine 8 ist
			beq	b_acht		;wenn ja, springe
			cmp.b	#2,0(a3,d1)	;pruefe, ob linie eine 2 ist 
			beq	b_zwei		;wenn ja,springe
			cmp.b	#4,0(a3,d1)	;pruefe, ob 4
			beq	b_vier		;wenn ja, springe
			cmp.b	#1,0(a3,d1)	;pruefe, ob linie eine 1
			beq	b_eins		;wenn ja, springe
			cmp.b	#5,0(a3,d1)	;schaue, ob linie eine 5
			beq	b_fuenf		;wenn ja, springe
			jmp	l_eval_end	;springe zum ende der schleife
b_acht			move.b	d1,d2		;verschiebe linie in 
			jmp	l_eval_end	;springe zum ende der schleife
b_zwei			cmp.b	#8,0(a3,d2)	;vergleiche, ob es bessere linie gibt
			beq	l_eval_end	;wenn ja, springe zum ende
			move.b	d1,d2		;wenn nicht, setzte diese als beste
b_vier			cmp.b	#8,0(a3,d2)	;vergleiche, ob es bessere linie gibt
			beq	l_eval_end	;wenn ja, springe zum ende
			cmp.b	#2,0(a3,d2)	;vergleiche, ob es bessere linie gibt
			beq	l_eval_end	;wenn ja, springe zum ende
			move.b	d1,d2		;wenn nicht, setzte diese als beste
b_eins			cmp.b	#8,0(a3,d2)	;vergleiche, ob es bessere linie gibt
			beq	l_eval_end	;wenn ja, springe zum ende
			cmp.b	#2,0(a3,d2)	;vergleiche, ob es bessere linie gibt
			beq	l_eval_end	;wenn ja, springe zum ende
			cmp.b	#4,0(a3,d2)	;vergleiche, ob es bessere linie gibt
			beq	l_eval_end	;wenn ja, springe zum ende
			move.b	d1,d2		;wenn nicht, setzte diese als beste
b_fuenf			cmp.b	#8,0(a3,d2)	;vergleiche, ob es bessere linie gibt
			beq	l_eval_end	;wenn ja, springe zum ende
			cmp.b	#2,0(a3,d2)	;vergleiche, ob es bessere linie gibt
			beq	l_eval_end	;wenn ja, springe zum ende
			cmp.b	#4,0(a3,d2)	;vergleiche, ob es bessere linie gibt
			beq	l_eval_end	;wenn ja, springe zum ende
			cmp.b	#1,0(a3,d2)	;vergleiche, ob es bessere linie gibt
			beq	l_eval_end	;wenn ja, springe zum ende
			move.b	d1,d2		;wenn nicht, setzte diese als beste

l_eval_end		addq.b	#1,d1		;erhoehe zeahlvariable
			cmp.b	#8,d1		;pruefe, ob schleife zu ende
			beq	l_eval_exit	;wenn ja, springe zur suche der besten position
			jmp	l_eval		;rucksprung zum schleifen anfang
l_eval_exit		move.b	d2,best_line	;schreiben der besten linie in variable
			clr.l	d1		;loesche register
			lea	field,a1	;lade zeiger auf feld
			lea	line_code,a2	;lade zeiger auf linien codes
			asl.b	#1,d2		;verschiebung, um mit word zu arbeiten
			move.w	0(a2,d2),d5	;kopiere code der besten zeile 
l_shift			asl.w	#1,d5		;shift, sodass erste stelle in statusregister steht
			bcs	b_c_set		;ueberpruefe carry bit im sr, wenn gesetzt, dann pruefe weiter
			addq.b	#1,d1		;wenn nicht, addiere 1 zu zaehler
			cmp.w	#0,d5		;schaue, ob alle stellen geprueft
			bne	l_shift		;wenn nicht, laufe die schleife erneut durch
b_c_set			cmp.b	#0,0(a1,d1)	;schaue, ob das feld bereits besetzt ist
			beq	l_shift_found	;wenn nicht, dann beste pos gefunden
			addq.b	#1,d1		;wenn nicht, addiere 1 zum zaehler
			cmp.w	#0,d5		;schaue, ob alle stellen ueberprueft
			bne	l_shift		;wenn nicht, dann durchlaufe die schleife erneut
l_shift_found		move.b	d1,place_stone	;kopiere die beste stelle in variable
eval_end		
			movem.l (a7)+,d1-d5/a1-a3
			rts

    SIMHALT             




	
    END    START        






*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
