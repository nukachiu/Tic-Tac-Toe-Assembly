.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
numar_maxim_miscari DD 9; pe o tabla de 3x3 se pot face 9 miscari

vector_miscari dd 0,0,0,
				  0,0,0,
				  0,0,0 			; faci ca si la x si 0 pe clasa a 10a, un vector care e echivalent cu tabla
									; 0 - casuta libera, 1 - ocupata de x, 2 - ocupata de 0
window_title DB "Tic Tac Toe",0
area_width EQU 510
area_height EQU 570
area DD 0
f db '%d',0ah,0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

x_0_width equ 100
x_0_height equ 100

symbol_width EQU 10
symbol_height EQU 20

include digits.inc
include letters.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha

	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
	make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
	make_space: 
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters

	draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
	bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
	bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
	simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
	simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y

deseneaza_linie_verticala macro x, y
LOCAL bucla
	pusha
	mov edi, area
	mov eax,x
	mov edx, area_width
	mul edx
	add eax, y
	shl eax, 2
	
	mov ecx, 570 ; linia va avea lungimea de 100 pixeli
	mov esi, area_width
	shl esi, 2
	
	mov edx,9874E2
	bucla:
	mov ebx, eax
	add ebx, edi
	mov dword ptr[ebx],edx ; linia are culoarea neagra
	add edx, 100
	add eax, esi
	loop bucla
	
	popa
endm

deseneaza_linie_orizontala macro x, y
LOCAL bucla
	pusha
	mov edi, area
	mov eax,x
	mov edx, area_width
	mul edx
	add eax, y
	shl eax, 2
	
	mov ecx, 510; linia va avea lungimea de 1340 pixeli
	
	mov edx,06E37DBh
	bucla:
	mov ebx, eax
	add ebx, edi
	mov dword ptr[ebx],edx ; linia are culoarea neagra
	add edx, 100
	add eax, 4
	loop bucla
	
	popa
endm

deseneaza_x macro x,y
LOCAL bucla, bucla2
	pusha
	mov edi, area
	mov eax, x
	mov edx, area_width
	mul edx
	add eax, y
	shl eax, 2
	push eax; pun valoarea lui eax pe stiva ca sa nu o mai calculez
	
	mov esi,area_width
	shl esi,2
	
	mov ecx, 170
	bucla:
		mov ebx, eax
		add ebx, edi
		mov dword ptr[ebx], edx
		add eax, esi
		add eax, 4
	loop bucla
	
	pop eax
	mov ecx, 170 ; lungimea liniei
	add eax, 680 ; ma mut practic 170 de pixeli mai la dreapta dar pt ca area este DD atunci vine x4
	bucla2:
		mov ebx, eax
		add ebx, edi
		mov dword ptr[ebx], edx
		add eax, esi
		sub eax, 4
	loop bucla2
endm

deseneaza_0 proc
	push ebp
	mov ebp,esp
	pusha
	
	mov edi, area
	mov eax, [ebp + arg2] ; x
	add eax, 30
	mov edx, area_width
	mul edx
	add eax, [ebp + arg1] ; y
	add eax, 35
	shl eax, 2
	
	mov esi, area_width
	shl esi, 2
	
	mov ecx, 100
	
	push eax; punem pe stiva valoarea lui eax pt ca avem nevoie de ea si cand facem liniile orizontale si nu vrem sa o mai calculam
	;diferenta dintre cele 2 linii paralele ( | | ) este 100 pixeli
	bucla: ; bucla asta deseneaza 2 linii verticale paralele
		mov ebx, eax
		add ebx, edi
		mov dword ptr[ebx], 0
		add ebx, 400
		mov dword ptr[ebx], 0
		sub ebx, 400
		
		add eax, esi
	loop bucla
	
	mov ecx, 100 ;reprezinta lungimea liniilor orizontale
	mov edx, 100 ;reprezinta dinstanta dintre cele 2 linii orizontale
	pop eax
	bucla2:
		mov ebx,eax
		add ebx,edi
		mov dword ptr[ebx], 0
		push ecx ; punem ecx pe stiva pentru a nu l strica
		mov ecx, edx ; vreau sa ajung la capatul de jos a liniei verticale
		bucla3:
			add ebx, esi
		loop bucla3 
		pop ecx
		mov dword ptr[ebx], 0
		push ecx ; punem ecx pe stiva pentru a nu l strica
		mov ecx, edx ; vreau sa ajung la capatul de sus a liniei verticale
		bucla4:
			sub ebx, esi
		loop bucla4
		pop ecx
		add eax, 4 ; acum am colorat pixelii de sus si de jos si ma duc in dreapta cu un pixel reprezentat pe 4 bytes
	loop bucla2
	
	popa
	mov esp, ebp
	pop ebp
	
	ret 8
deseneaza_0 endp

deseneaza_0_macro macro x, y
	push x
	push y
	call deseneaza_0
endm

x_loc_potrivit proc ; functie care face ca x sa inceapa dintr o casuta din locul care trebe
	push ebp
	mov ebp,esp
	pusha
	
	mov edx, [ebp + arg1] ; x
	mov ebx, [ebp + arg2] ; y
	
	cmp ebx, 170;verifica daca trebe sa fie pe prima linie
	jl prima_linie
	
	cmp ebx, 340 ; asta ma duce pe linia a 3a
	jg linia_3
	
	; daca am ajuns aici trebe sa pun x sau 0 pe linia a 2a
	cmp edx, 170
	jl patratica_4
	
	cmp edx, 340
	jg patratica_6
	
	;daca am ajuns aici inseamna ca trebe sa punem simbolul in patratica din mijloc
	cmp [vector_miscari + 16],0
	jne miscare_invalida
	deseneaza_x 170,170
	mov [vector_miscari + 16],1 
	
	jmp finaaal
	
	patratica_4:
		cmp [vector_miscari + 12],0
		jne miscare_invalida
		deseneaza_x 170,0
		mov [vector_miscari + 12],1 
	jmp finaaal
	patratica_6:
		cmp [vector_miscari + 20],0
		jne miscare_invalida
		deseneaza_x 170,340
		mov [vector_miscari + 20],1 
	jmp finaaal
	
	prima_linie:
		cmp edx,170
		jl prima_patratica
		;jmp finaaal
		
		cmp edx, 340
		jg patratica_3
		;dca am ajuns aici atunci trebe sa fie x sau 0 in casuga de pe prima linie in mijloc
		cmp [vector_miscari + 4],0
		jne miscare_invalida
		deseneaza_x 0,170
		mov [vector_miscari + 4],1
		
	jmp finaaal
	
	prima_patratica:
		cmp [vector_miscari + 0],0
		jne miscare_invalida
		deseneaza_x 0,0
		mov [vector_miscari + 0],1 
	jmp finaaal
	patratica_3:
		cmp [vector_miscari + 8],0
		jne miscare_invalida
		deseneaza_x 0,340
		mov [vector_miscari + 8],1
	jmp finaaal
	
	linia_3:
		cmp edx, 170
		jl patratica_7
		
		cmp edx, 340 
		jg patratica_9
		
		cmp [vector_miscari + 28],0
		jne miscare_invalida
		deseneaza_x 340,170
		mov [vector_miscari + 28],1 
		jmp finaaal
	
	patratica_7:
		cmp [vector_miscari + 24],0
		jne miscare_invalida
		deseneaza_x 340,0
		mov [vector_miscari + 24],1
	jmp finaaal
	patratica_9:
		cmp [vector_miscari + 32],0
		jne miscare_invalida
		deseneaza_x 340,340
		mov [vector_miscari + 32],1
	jmp finaaal
	
	miscare_invalida:
		
		add numar_maxim_miscari, 1
	
	finaaal: 
	popa
	mov esp, ebp
	pop ebp
	ret 8
x_loc_potrivit endp


zero_loc_potrivit proc ; functie care face ca 0 sa inceapa dintr o casuta din locul care trebe
	push ebp
	mov ebp,esp
	pusha
	
	mov edx, [ebp + arg1] ; x
	mov ebx, [ebp + arg2] ; y
	
	cmp ebx, 170;verifica daca trebe sa fie pe prima linie
	jl prima_linie
	
	cmp ebx, 340 ; asta ma duce pe linia a 3a
	jg linia_3
	
	; daca am ajuns aici trebe sa pun x sau 0 pe linia a 2a
	cmp edx, 170
	jl patratica_4
	
	cmp edx, 340
	jg patratica_6
	
	;daca am ajuns aici inseamna ca trebe sa punem simbolul in patratica din mijloc
	cmp [vector_miscari + 16],0
	jne miscare_invalida_2
	deseneaza_0_macro 170,170
	mov [vector_miscari + 16],2
	jmp finaaal
	
	patratica_4:
		cmp [vector_miscari + 12],0
		jne miscare_invalida_2
		deseneaza_0_macro 170,0
		mov [vector_miscari + 12],2
	jmp finaaal
	patratica_6:
		cmp [vector_miscari + 20],0
		jne miscare_invalida_2
		deseneaza_0_macro 170,340
		mov [vector_miscari + 20],2
	jmp finaaal
	
	prima_linie:
		cmp edx,170
		jl prima_patratica
		;jmp finaaal
		
		cmp edx, 340
		jg patratica_3
		;dca am ajuns aici atunci trebe sa fie x sau 0 in casuga de pe prima linie in mijloc
		cmp [vector_miscari + 4],0
		jne miscare_invalida_2
		deseneaza_0_macro 0,170
		mov [vector_miscari + 4],2
		
	jmp finaaal
	
	prima_patratica:
		cmp [vector_miscari + 0],0
		jne miscare_invalida_2
		deseneaza_0_macro 0,0
		mov [vector_miscari + 0],2 
	jmp finaaal
	patratica_3:
		cmp [vector_miscari + 8],0
		jne miscare_invalida_2
		deseneaza_0_macro 0,340
		mov [vector_miscari + 8],2
	jmp finaaal
	
	linia_3:
		cmp edx, 170
		jl patratica_7
		
		cmp edx, 340 
		jg patratica_9
		
		cmp [vector_miscari + 28],0
		jne miscare_invalida_2
		deseneaza_0_macro 340,170
		mov [vector_miscari + 28],2
		jmp finaaal
	
	patratica_7:
		cmp [vector_miscari + 24],0
		jne miscare_invalida_2
		deseneaza_0_macro 340,0
		mov [vector_miscari + 24],2
	jmp finaaal
	patratica_9:
		cmp [vector_miscari + 32],0
		jne miscare_invalida_2
		deseneaza_0_macro 340,340
		mov [vector_miscari + 32],2
	jmp finaaal
	
	miscare_invalida_2:
		add numar_maxim_miscari, 1
	
	finaaal: 
	popa
	mov esp, ebp
	pop ebp
	ret 8
	
zero_loc_potrivit endp


tabla macro

	deseneaza_linie_verticala 0,170
	deseneaza_linie_verticala 0,340
	deseneaza_linie_orizontala 170,0
	deseneaza_linie_orizontala 340,0

endm

verificare_castigator proc
	mov eax, -1
	
	mov ebx, [vector_miscari + 32]
	cmp ebx, [vector_miscari + 20] 
		je linie_3_verticala
	
	cmp ebx, [vector_miscari + 28]
		je linie_3_orizontala
	
	
	mov ebx,[vector_miscari + 16]
	cmp ebx, [vector_miscari + 12]; verificam a 2 a linie orizontala
		je linie_2_orizontala 
	
	cmp ebx,[vector_miscari + 4] ; verificam a 2-a linie verticala
		je linie_2_verticala 
	
	cmp ebx,[vector_miscari + 8]
		je diagonala_secundara
	
	mov ebx, [vector_miscari + 0] 
	cmp ebx, [vector_miscari + 4] ; e pe dd si de aia trebe  + 4 
		je prima_linie_orizontala ; verific prima linie orizontala
	
	cmp ebx, [vector_miscari + 12] ; acum verificam prima linie verticala
		je prima_linie_verticala
		
	cmp ebx, [vector_miscari + 16]
		je diagonala_principala
	
	
	
	jmp gata_verificare
	
	
	prima_linie_orizontala:
		cmp ebx, [vector_miscari + 8]
			je castigator_1
	jmp gata_verificare
	
	prima_linie_verticala:
		cmp ebx, [vector_miscari + 24]
			je castigator_1
	jmp gata_verificare

	diagonala_principala:
		cmp ebx,[vector_miscari + 32]
			je castigator_1
	jmp gata_verificare
	
	linie_2_orizontala:
		cmp ebx, [vector_miscari + 20]
			je castigator_2
	jmp gata_verificare
	
	linie_2_verticala:
		cmp ebx, [vector_miscari + 28]
			je castigator_2
	jmp gata_verificare
	
	diagonala_secundara:
		cmp ebx, [vector_miscari + 24]
			je castigator_2
	jmp gata_verificare
	
	linie_3_verticala:
		cmp ebx, [vector_miscari + 8]
			je castigator_3
	jmp gata_verificare
	
	linie_3_orizontala:
		cmp ebx, [vector_miscari + 24]
			je castigator_3
	jmp gata_verificare
	
	castigator_1: ; asta inseamna ca s a facut linie pe prima linie orizontala
		mov eax,[vector_miscari + 0]
	jmp gata_verificare
	
	castigator_2:
		mov eax, [vector_miscari + 16]
	jmp gata_verificare
	
	castigator_3:
		mov eax, [vector_miscari + 32]
	
	gata_verificare:
	ret
verificare_castigator endp

verificare_2 proc ; pentru diagonala secundara, linia_2_orizont si verticala
	mov ebx,[vector_miscari + 16]
	cmp ebx, [vector_miscari + 12]; verificam a 2 a linie orizontala
		je linie_2_orizontala 
	
	cmp ebx,[vector_miscari + 4] ; verificam a 2-a linie verticala
		je linie_2_verticala 
	
	cmp ebx,[vector_miscari + 8]
		je diagonala_secundara
	
	jmp gata_verif
	linie_2_orizontala:
		cmp ebx, [vector_miscari + 20]
			je castigator_2
	jmp gata_verif
	
	linie_2_verticala:
		cmp ebx, [vector_miscari + 28]
			je castigator_2
	jmp gata_verif
	
	diagonala_secundara:
		cmp ebx, [vector_miscari + 24]
			je castigator_2
	jmp gata_verif
	
	castigator_2:
		mov eax,[vector_miscari + 16]
	
	gata_verif:
	ret
verificare_2 endp

verificare_3 proc ; pt prima linie veritcala si orizontala si pt diagonala princ
	
	mov ebx, [vector_miscari + 0] 
	cmp ebx, [vector_miscari + 4] ; e pe dd si de aia trebe  + 4 
		je prima_linie_orizontala ; verific prima linie orizontala
	
	cmp ebx, [vector_miscari + 12] ; acum verificam prima linie verticala
		je prima_linie_verticala
		
	cmp ebx, [vector_miscari + 16]
		je diagonala_principala
	
	jmp gata_verificare_1
	
	prima_linie_orizontala:
		cmp ebx, [vector_miscari + 8]
			je castigator_1
	jmp gata_verificare_1
	
	prima_linie_verticala:
		cmp ebx, [vector_miscari + 24]
			je castigator_1
	jmp gata_verificare_1

	diagonala_principala:
		cmp ebx,[vector_miscari + 32]
			je castigator_1
	jmp gata_verificare_1
	
	castigator_1: 
		mov eax, [vector_miscari + 0]
	
	gata_verificare_1:
	ret
verificare_3 endp

joc proc
	push ebp
	mov ebp, esp
	pusha 
	
	;call verificare_castigator
	;cmp eax, 1
	;je castigator_x
	
	
	cmp numar_maxim_miscari, -1
	je gata
	
	cmp numar_maxim_miscari, 0
	je egalitate
	
	mov edx, 0
	mov eax, numar_maxim_miscari
	mov ebx, 2
	div ebx
	cmp edx, 0
	je muta_0
	push [ebp + 12] ; daca nu s a facut jump inseamna ca deseneaza x
	push [ebp + 8]
	call x_loc_potrivit
	jmp gata
	
	muta_0:
		push [ebp + 12]
		push [ebp + 8]
		call zero_loc_potrivit
	
	gata:
	
	dec numar_maxim_miscari
	
	
	jmp eticheta
	
	egalitate:
		make_text_macro "T", area, 100,100
		make_text_macro "I", area, 200,100
		make_text_macro "E", area, 300,100
		
	eticheta:
	popa
	mov esp, ebp
	pop ebp
	
	ret 8
joc endp

draw proc
	push ebp
	mov ebp, esp
	pusha

	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0ffffffffh
	push area
	call memset
	add esp, 12
	
	tabla ; macro care deseneaza tabla de joc
	
	jmp final_draw
    
	evt_click:
	
	
	push eax ; pun eax aici pentru ca daca pun inainte de call verificare fut stiva
	push [ebp + arg3] ; punem cooronatele mouse ului pe stiva pt a putea x_apela loc_potrivit
	push [ebp + arg2]
	;call zero_loc_potrivit ; TARGET PE MAINE : FACI SA SE SCHIMBE JUCATORUL !!!! 
	;push [ebp + arg3]
	;push [ebp + arg2]
	
	
	call joc
	;bucla:
	
	call verificare_castigator
	cmp eax, 1
	je x_castigator
	cmp eax,2
	je zero_castigator
	
	call verificare_2
	cmp eax, 1
	je x_castigator
	cmp eax,2
	je zero_castigator
	
	call verificare_3
	cmp eax, 1
	je x_castigator
	cmp eax,2
	je zero_castigator
	
	JMP final_draw 
	evt_timer:
	
	jmp final_draw
	egalitate:
		make_text_macro "E",area,690,520
		make_text_macro "G",area,690,520
		make_text_macro "A",area,690,520
		make_text_macro "L",area,690,520
		make_text_macro "I",area,690,520
		make_text_macro "T",area,690,520
		make_text_macro "A",area,690,520
		make_text_macro "T",area,690,520
		make_text_macro "E",area,690,520
		mov numar_maxim_miscari,-1 ; ca sa nu mai fac miscari dupa ce s a castigat
		pop eax
	jmp final_draw
	x_castigator:
		make_text_macro "X",area,690,520

		make_text_macro "C",area,710,520
		make_text_macro "A",area,720,520
		make_text_macro "S",area,730,520
		make_text_macro "T",area,740,520
		make_text_macro "I",area,750,520
		make_text_macro "G",area,760,520
		make_text_macro "A",area,770,520
		make_text_macro "T",area,780,520
		make_text_macro "O",area,790,520
		make_text_macro "R",area,800,520
		mov numar_maxim_miscari,-1 ; ca sa nu mai fac miscari dupa ce s a castigat
		pop eax
	jmp final_draw
	zero_castigator:
		make_text_macro "0",area,690,520

		make_text_macro "C",area,710,520
		make_text_macro "A",area,720,520
		make_text_macro "S",area,730,520
		make_text_macro "T",area,740,520
		make_text_macro "I",area,750,520
		make_text_macro "G",area,760,520
		make_text_macro "A",area,770,520
		make_text_macro "T",area,780,520
		make_text_macro "O",area,790,520
		make_text_macro "R",area,800,520
		mov numar_maxim_miscari,-1 ; ; ca sa nu mai fac miscari dupa ce s a castigat
		pop eax
	final_draw:
	pop eax
	
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
;alocam memorie pentru zona de desenat
mov eax, area_width
mov ebx, area_height
mul ebx
shl eax, 2
push eax
call malloc
add esp, 4
mov area, eax
;apelam functia de desenare a ferestrei
; typedef void (*DrawFunc)(int evt, int x, int y);
; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
push offset draw
push area
push area_height
push area_width
push offset window_title
call BeginDrawing
add esp, 20

;terminarea programului
push 0
call exit
end start