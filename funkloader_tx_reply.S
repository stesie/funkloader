/*
 * Copyright(C) 2008 Stefan Siegl <stesie@brokenpipe.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 */

#define  __SFR_OFFSET 0
#include <avr/io.h>

#include "pinconfig.h"

	.file	"funkloader_tx_reply.S"
	.text
	
.global funkloader_tx_reply
	.type	funkloader_tx_reply, @function
funkloader_tx_reply:

	ldi	r25, 0xB8	; tx data byte
	
	;; send preamble: AA, AA, AA, 2D, D4
	ldi	r24, 0xAA
	rcall	rfm12_wait_tx
	rcall	rfm12_wait_tx
	rcall	rfm12_wait_tx

	ldi	r24, 0x2D
	rcall	rfm12_wait_tx
	
	ldi	r24, 0xD4
	rcall	rfm12_wait_tx

	;; first data byte: 0x23
	ldi	r24, 0x23
	rcall 	rfm12_wait_tx

	;; second data byte: checksum
	lds	r24, funkloader_buf + SPM_PAGESIZE + 2
	rcall	rfm12_wait_tx

	;; postable: AA, AA
	ldi	r24, 0xAA
	rcall	rfm12_wait_tx
	rcall	rfm12_wait_tx

	ret




	
.global rfm12_wait_tx
	.type	rfm12_wait_tx, @function
rfm12_wait_tx:

	/* Wait for the interrupt pin to become active. */
.L0:
	sbis	INT_PORT, INT_PIN
	rjmp	.L0

	/* SPI_CS_RFM12_PORT &= ~_BV(SPI_CS_RFM12); */
	cbi 	SPI_CS_RFM12_PORT, SPI_CS_RFM12

	/* send high byte first */
	out 	SPDR, r25

.L1:
	sbis 	SPSR, SPIF
	rjmp	.L1

	/* send low byte */
	out 	SPDR, r24

.L2:
	sbis 	SPSR, SPIF
	rjmp	.L2

	/* SPI_CS_RFM12_PORT |= _BV(SPI_CS_RFM12); */
	sbi	SPI_CS_RFM12_PORT, SPI_CS_RFM12
	
	ret
