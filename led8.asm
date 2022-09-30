
.nolist
.include "m2560def.inc"
.list

.equ	DD_MOSI	= DDB2
.equ	DD_SCK	= DDB1
.equ	DD_SS	= DDB0
.equ	DDR_SPI	= DDRB

.cseg

	cli

	in	r0, SPL
	in	r1, SPH

	ldi	r16, high (RAMEND)
	out	SPH, r16
	ldi	r16, low  (RAMEND)
	out	SPL, r16

	rcall	uart_trans_init
	ldi	r16, $55
	rcall	uart_send
	mov	r16, r0
	rcall	uart_send
	mov	r16, r1
	rcall	uart_send
	rcall	uart_wait_send
	rcall	uart_deinit

; SPI init
	sbi	PORTB, PORTB0
	ldi	r17, (1<<DD_MOSI)|(1<<DD_SCK)|(1<<DD_SS)
	out	DDR_SPI, r17
	ldi	r17, (1<<SPE)|(0<<DORD)|(1<<MSTR)|(0<<CPOL)|(0<<CPHA)|(1<<SPR1)|(1<<SPR0)
	out	SPCR, r17

	rcall	uart_txrx_init
lp:	rcall	uart_recv
	mov	r18, r16
	rcall	uart_send
	rcall	uart_recv
	mov	r19, r16
	rcall	uart_send
	cbi	PORTB, PORTB0
	mov	r16, r18
	rcall	sp_send
	mov	r16, r19
	rcall	sp_send
	sbi	PORTB, PORTB0
	rjmp	lp

sp_send:
	out	SPDR, r16
spwt:	in	r16, SPSR
	sbrs	r16, SPIF
	rjmp	spwt
	ret

;.equ	uart_ubrrl =	16	; XTAL 16 MHz U2X=1 115200 kbps
;.equ	uart_u2x = 1
;.equ	uart_tx_timeout = 300	; 8 [presc. div, U2X=1] * 17 [uart_ubrr + 1] * 9 [baud bits] / 5 [loop tcks]
; XTAL = 15887515,15 Hz  BAUD = 116820 kbps

.equ	uart_ubrrl =	206	; XTAL 16 MHz U2X=1 9600 kbps
.equ	uart_u2x = 1
.equ	uart_tx_timeout = 3000	; 8 [presc. div, U2X=1] * 206 [uart_ubrr + 1] * 9 [baud bits] / 5 [loop tcks]
; XTAL = 15887515,15 Hz  BAUD = 9594 kbps

uart_trans_init:
	clr	r16
	sts	UBRR0H, r16
	ldi	r16, uart_ubrrl
	sts	UBRR0L, r16
	ldi	r16, (uart_u2x<<U2X0)
	sts	UCSR0A, r16
	ldi	r16, (1<<TXEN0)
	sts	UCSR0B, r16
	ldi	r16, (1<<UCSZ01)|(1<<UCSZ00)
	sts	UCSR0C, r16
	ret

uart_send:
wtdr:	lds	r17, UCSR0A
	sbrs	r17, UDRE0
	rjmp	wtdr
	sbr	r17, TXC0
	sts	UCSR0A, r17
	sts	UDR0, r16
	ret

uart_wait_send:
	ldi	XH, high (uart_tx_timeout)
	ldi	XL, low (uart_tx_timeout)
wttr:	sbiw	X, 1
	breq	wtrt
	lds	r17, UCSR0A
	sbrs	r17, TXC0
	rjmp	wttr
wtrt:	ret

uart_deinit:
	clr	r16
	sts	UCSR0A, r16
	sts	UCSR0B, r16
	ldi	r16, (1<<UCSZ01)|(1<<UCSZ00)
	sts	UCSR0C, r16
	ret

uart_recv_init:
	clr	r16
	sts	UBRR0H, r16
	ldi	r16, uart_ubrrl
	sts	UBRR0L, r16
	ldi	r16, (uart_u2x<<U2X0)
	sts	UCSR0A, r16
	ldi	r16, (1<<RXEN0)
	sts	UCSR0B, r16
	ldi	r16, (1<<UCSZ01)|(1<<UCSZ00)
	sts	UCSR0C, r16
	ret

uart_recv:
wtrc:	lds	r16, UCSR0A
	sbrs	r16, RXC0
	rjmp	wtrc
	lds	r16, UDR0
	ret

uart_txrx_init:
	clr	r16
	sts	UBRR0H, r16
	ldi	r16, uart_ubrrl
	sts	UBRR0L, r16
	ldi	r16, (uart_u2x<<U2X0)
	sts	UCSR0A, r16
	ldi	r16, (1<<RXEN0)|(1<<TXEN0)
	sts	UCSR0B, r16
	ldi	r16, (1<<UCSZ01)|(1<<UCSZ00)
	sts	UCSR0C, r16
	ret
