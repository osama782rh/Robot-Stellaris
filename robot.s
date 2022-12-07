	
	;; RK - Evalbot (Cortex M3 de Texas Instrument)
   	
		AREA    |.text|, CODE, READONLY
 
; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_GPIOF EQU		0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf)

; The GPIODATA register is the data register
GPIO_PORTF_BASE		EQU		0x40025000	; GPIO Port F (APB) base: 0x4002.5000 (p416 datasheet de lm3s9B92.pdf)
GPIO_PORTD_BASE		EQU		0x40007000	; GPIO Port D
GPIO_PORTE_BASE		EQU		0x40024000	; GPIO Port E
	
PWM_BASE			EQU		0x040028000	;BASE des Block PWM p.1138
PWM0CMPA			EQU		PWM_BASE+0x058
PWM1CMPA			EQU		PWM_BASE+0x098


; configure the corresponding pin to be an output
; all GPIO pins are inputs by default
GPIO_O_DIR   		EQU 	0x00000400  ; GPIO Direction (p417 datasheet de lm3s9B92.pdf)

; The GPIODR2R register is the 2-mA drive control register
; By default, all GPIO pins have 2-mA drive.
GPIO_O_DR2R   		EQU 	0x00000500  ; GPIO 2-mA Drive Select (p428 datasheet de lm3s9B92.pdf)

; Digital enable register
; To use the pin as a digital input or output, the corresponding GPIODEN bit must be set.
GPIO_O_DEN   		EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)

GPIO_O_PUR			EQU		0x00000510

; PINs
PIN4				EQU		0x10	; LED1
PIN5				EQU		0x20	; LED2
PIN4_5				EQU		0x30	; LEDs
PIN6_7				EQU		0xC0	; Switchs
PIN0_1				EQU		0x03	; Bumpers
	
; Compteur pour reculer
COMPTEUR_RECULE		EQU		0x1
; Compteur pour un changement de direction
COMPTEUR_90TURN		EQU		0x3
; Compteur pour un demi tour
COMPTEUR_180TURN	EQU		0x6		

; DUREE POUR LA FREQUENCE DE CLIGNOTEMENT
DUREE   			EQU     0x002FFFFF
; DUREE POUR LA TEMPORISATION
DUREE_TEMPO			EQU 	0x00BFFFF
	
VITESSE_RAPIDE		EQU		0x152
VITESSE				EQU		0x19F
	
	  	ENTRY
		EXPORT	__main
			
		;; The IMPORT command specifies that a symbol is defined in a shared object at runtime.
		IMPORT	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arrière
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arrière
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche
		
__main	

		; ;; Enable the Port F peripheral clock by setting bit 5 (0x20 == 0b100000)		(p291 datasheet de lm3s9B96.pdf)
		; ;;														 (GPIO::FEDCBA)
		LDR r6, = SYSCTL_PERIPH_GPIOF  			;; RCGC2
        MOV r0, #0x00000038  					;; Enable clock sur GPIO F où sont branchés les leds (0x20 == 0b100000)
		; ;;														 									 (GPIO::FEDCBA)
        STR r0, [r6]
		
		; ;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
		NOP	   									;; tres tres important....
		NOP
		NOP	   									;; pas necessaire en simu ou en debbug step by step...
	
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION SWITCH
		LDR r7, = GPIO_PORTD_BASE+GPIO_O_PUR
		LDR r0, = PIN6_7
		STR r0, [r7]
		
		LDR r7, = GPIO_PORTD_BASE+GPIO_O_DEN	;; Enable Digital Function 
        LDR r0, = PIN6_7 		
        STR r0, [r7]
 
		LDR r7, = GPIO_PORTD_BASE + (PIN6_7<<2)
		
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION BUMPERS
		LDR r8, = GPIO_PORTE_BASE+GPIO_O_PUR
		LDR r0, = PIN0_1
		STR r0, [r8]
		
		LDR r8, = GPIO_PORTE_BASE+GPIO_O_DEN	;; Enable Digital Function 
        LDR r0, = PIN0_1
        STR r0, [r8]
 
		LDR r8, = GPIO_PORTE_BASE + (PIN0_1<<2)
		
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION LED
        LDR r9, = GPIO_PORTF_BASE+GPIO_O_DIR
        LDR r0, = PIN4_5
        STR r0, [r9]
		
        LDR r9, = GPIO_PORTF_BASE+GPIO_O_DEN	;; Enable Digital Function 
        LDR r0, = PIN4_5
        STR r0, [r9]
 
		LDR r9, = GPIO_PORTF_BASE+GPIO_O_DR2R	;; Choix de l'intensité de sortie (2mA)
        LDR r0, = PIN4_5
        STR r0, [r9]

		MOV r2, #PIN4
		MOV r3, #PIN5
		MOV r11, #PIN4_5
		MOV r5, #0x00	;; LEDs eteintes
		
		MOV r4, #PIN4_5       					;; Allume portF broche 4 et 5 : 00110000
		LDR r9, = GPIO_PORTF_BASE + (PIN4_5<<2) ;; @data Register = @base + (mask<<2) ==> LED1

		; Configure les PWM + GPIO
		BL	MOTEUR_INIT
		
		; Activer les deux moteurs droit et gauche
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON

;; COMPORTEMENT 1 : Tourne et clignote en fonction des activations des bumpers
comportement1							;; boucle du premier comportement

		; Evalbot avance droit devant
		BL	MOTEUR_DROIT_AVANT
		BL	MOTEUR_GAUCHE_AVANT
        STR r4, [r9] 					;; LEDs allumés
		
		LDR r0, [r8]
		CMP r0, #0x02					;; check si le bumper droit est activé
		LDR r1, = DUREE_TEMPO			;; met en place une tempo au cas ou si les 2 bumpers sont activés pour le demi tour
		BEQ tempo_turn_left				;; lance la tempo
		
		LDR r0, [r8]
		CMP r0, #0x01					;; check si le bumper gauche est activé
		LDR r1, = DUREE_TEMPO			;; met en place une tempo au cas ou si les 2 bumpers sont activés pour le demi tour
		BEQ tempo_turn_right			;; lance la tempo
		
		LDR r0, [r7]
		CMP r0, #0x80					;; check si le SWITCH1 est activé
		BEQ comportement2				;; si vrai lance va dans la boucle du deuxieme comportement (comportement2)
		
        B comportement1
		
		
tempo_turn_left
		; le robot va reculer le temps de la temporisation pour faciliter le changement de direction
		BL MOTEUR_DROIT_ARRIERE			;; moteur droit arriere
		BL MOTEUR_GAUCHE_ARRIERE 		;; moteur gauche arriere
		LDR r0, [r8]
		CMP r0, #0x00					;; check si les deux bumpers sont activés
		BEQ demi_tour					;; si vrai faire le demi tour
		SUBS r1, #1						;; temporisation
		BNE tempo_turn_left
		BL	MOTEUR_DROIT_AVANT			;; remet les moteurs dans l'etat ou ils avancent (pour faire correctement le turn_left)
		BL	MOTEUR_GAUCHE_AVANT			;; remet les moteurs dans l'etat ou ils avancent (pour faire correctement le turn_left)
		B turn_left						;; fin de la temporisation (seulement bumper droit activé donc tourne a gauche)
	
	
tempo_turn_right
		; le robot va reculer le temps de la temporisation pour faciliter le changement de direction
		BL MOTEUR_DROIT_ARRIERE			;; moteur droit arriere
		BL MOTEUR_GAUCHE_ARRIERE 		;; moteur gauche arriere
		LDR r0, [r8]
		CMP r0, #0x00					;; check si les deux bumpers sont activés
		BEQ demi_tour					;; si vrai faire le demi tour
		SUBS r1, #1						;; temporisation
		BNE tempo_turn_right
		BL	MOTEUR_DROIT_AVANT			;; remet les moteurs dans l'etat ou ils avancent (pour faire correctement le turn_right)
		BL	MOTEUR_GAUCHE_AVANT			;; remet les moteurs dans l'etat ou ils avancent (pour faire correctement le turn_right)
		B turn_right					;; fin de la temporisation (seulement bumper droit activé donc tourne a gauche)


turn_left								;; TOURNE A GAUCHE
		LDR r10, = COMPTEUR_90TURN		;; met en place un compteur de boucle globale wait_left
		B wait_left						;; commence a tourner a gauche


turn_right								;; TOURNE A DROITE
		LDR r10, = COMPTEUR_90TURN		;; met en place un compteur de boucle globale wait_right
		B wait_right					;; commence a tourner a droit
		

demi_tour								;; FAIT UN DEMI TOUR (RECULE ET TOURNE A DROITE DE 180 degré)
		LDR r10, = COMPTEUR_RECULE		;; met en place un compteur de boucle globale wait_demi_tour qui fait reculer le robot
		B wait_demi_tour				;; commence a faire le demi tour


wait_left								;; début du changement de direction vers la gauche
		STR r3, [r9]					;; allume la LED gauche (pour clignotement)
		BL MOTEUR_GAUCHE_ARRIERE		;; moteur gauche arriere
		LDR r1, = DUREE					;; compteur DUREE pour les clignotements
wait_left1
		SUBS r1, #1						;; temporisation
		BNE wait_left1
		LDR r1, = DUREE					;; compteur DUREE pour les clignotements
wait_left2
		SUBS r1, #1						;; temporisation
		STR r5, [r9]					;; LEDs eteintes (pour clignotement)
		BNE wait_left2
		
		SUBS r10, #1					;; decrementation du compteur COMPTEUR_90TURN (le robot tourne a gauche)
		BNE wait_left
		B comportement1					;; fin du changement de direction vers la gauche -> retour dans la boucle du comportement1
		
		
wait_right								;; début du changement de direction vers la droite
		STR r2, [r9]					;; allume la LED droite (pour clignotement)
		BL MOTEUR_DROIT_ARRIERE			;; moteur droit arriere
		LDR r1, = DUREE					;; compteur DUREE pour les clignotements
wait_right1
		SUBS r1, #1						;; temporisation
		BNE wait_right1
		LDR r1, = DUREE					;; compteur DUREE pour les clignotements
wait_right2
		SUBS r1, #1						;; temporisation
		STR r5, [r9]					;; LEDs eteintes (pour clignotement)
		BNE wait_right2
		
		SUBS r10, #1					;; decrementation du compteur global de la boucle COMPTEUR_90TURN ou COMPTEUR_180TURN (le robot tourne a droite)
		BNE wait_right
		B comportement1					;; fin du changement de direction vers la droite -> retour dans la boucle du comportement1
	
	
wait_demi_tour							;; début du demi tour (le robot recule dabord puis fait le demi tour)
		STR r11, [r9]					;; allume les LEDs (pour clignotement)
		BL MOTEUR_DROIT_ARRIERE			;; moteur droit arriere
		BL MOTEUR_GAUCHE_ARRIERE 		;; moteur gauche arriere
		LDR r1, = DUREE					;; compteur DUREE pour les clignotements
wait_demi_tour1
		SUBS r1, #1						;; temporisation
		BNE wait_demi_tour1
		LDR r1, = DUREE					;; compteur DUREE pour les clignotements
wait_demi_tour2
		SUBS r1, #1						;; temporisation
		STR r5, [r9]					;; LEDs eteintes (pour clignotement)
		BNE wait_demi_tour2
		
		SUBS r10, #1					;; decrementation du compteur COMPTEUR_RECULE (le robot recule)
		BNE wait_demi_tour
		
		LDR r10, = COMPTEUR_180TURN     ;; mise en place du compteur COMPTEUR_180TURN (2 fois plus long que COMPTEUR_90TURN pour pouvoir le demi-tour)
		BL	MOTEUR_DROIT_AVANT			;; remet les moteurs dans l'etat ou ils avancent (pour faire correctement le wait_right)
		BL	MOTEUR_GAUCHE_AVANT			;; remet les moteurs dans l'etat ou ils avancent (pour faire correctement le wait_right)
		B wait_right					;; commence a faire un demi tour (qui est en réalité un wait_right, 2 fois plus long que la normale)
		
		
;; COMPORTEMENT 2 : MODE TOUPIE ACTIVABLE SUR LE SWITCH2 puis les bumpers pour gérer la vitesse (bumper droit -> vitesse rapide; bumper gauche -> vitesse initial)
comportement2
		BL MOTEUR_DROIT_OFF				;; Désactive les deux moteurs droit et gauche
		BL MOTEUR_GAUCHE_OFF
loop_comportement2
		LDR r0, [r7]					
		CMP r0, #0x40					;; check le SWITCH2 est activé
		BEQ mode_toupie					;; si c'est vrai entre dans le mode toupie
		
		B loop_comportement2
		
;; MODE TOUPIE (tourne sur lui même)
mode_toupie
		BL MOTEUR_DROIT_ON				;; Active les deux moteurs droit et gauche
		BL MOTEUR_GAUCHE_ON
		BL MOTEUR_DROIT_AVANT			;; moteur droit avant
		BL MOTEUR_GAUCHE_ARRIERE		;; moteur gauche arriere pour le faire tourner
loop_toupie								;; boucle du mode toupie
		LDR r0, [r7]
		CMP r0, #0x40					;; check si le SWITCH2 est activé
		BEQ reset						;; si vrai revient dans le comportement2
		
		LDR r0, [r8]
		CMP r0, #0x02					;; check si le bumper droit est activé
		BEQ mode_turbo					;; si vrai augmente la vitesse des moteurs avec le mode turbo
		
		LDR r0, [r8]
		CMP r0, #0x01					;; check si le bumper gauche est activé
		BEQ vitesse_normal				;; si vrai remet la vitesse des moteurs avec les valeurs initiales
		
		B loop_toupie

mode_turbo
		LDR	r6, =PWM0CMPA
		MOV	r0, #VITESSE_RAPIDE
		STR	r0, [r6]					;; augmente la valeur de la vitesse des moteurs
		
		LDR	r6, =PWM1CMPA
		MOV	r0,	#VITESSE_RAPIDE
		STR	r0, [r6]					;; augmente la valeur de la vitesse des moteurs

		B loop_toupie
		
vitesse_normal
		LDR	r6, =PWM0CMPA
		MOV	r0, #VITESSE
		STR	r0, [r6]					;; remet la vitesse du moteur a ces valeurs initiales
		
		LDR	r6, =PWM1CMPA
		MOV	r0,	#VITESSE
		STR	r0, [r6]					;; remet la vitesse du moteur a ces valeurs initiales

		B loop_toupie

reset
		BL MOTEUR_DROIT_OFF				;; Désactive les deux moteurs droit et gauche
		BL MOTEUR_GAUCHE_OFF
		LDR	r6, =PWM0CMPA
		MOV	r0, #VITESSE
		STR	r0, [r6]					;; remet la vitesse du moteur a ces valeurs initiales
		
		LDR	r6, =PWM1CMPA
		MOV	r0,	#VITESSE
		STR	r0, [r6]					;; remet la vitesse du moteur a ces valeurs initiales
		B loop_comportement2					;; revient dans le comportement2

		NOP		
        END 