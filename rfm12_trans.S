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

#include <avr/io.h>
#include "pinconfig.h"

	.file	"rfm12_trans.S"
	.text
	
.global rfm12_trans
	.type	rfm12_trans, @function
rfm12_trans:

	/* SPI_CS_RFM12_PORT &= ~_BV(SPI_CS_RFM12); */
	cbi 	SPI_CS_RFM12_PORT - 0x20, SPI_CS_RFM12

	/* send high byte first */
	out 	SPDR - 0x20, r25

.L1:
	sbis 	SPSR - 0x20, SPIF
	rjmp	.L1

	in	r25, SPDR - 0x20

	/* send low byte */
	out 	SPDR - 0x20, r24

.L2:
	sbis 	SPSR - 0x20, SPIF
	rjmp	.L2

	in	r24, SPDR - 0x20

	/* SPI_CS_RFM12_PORT |= _BV(SPI_CS_RFM12); */
	sbi	SPI_CS_RFM12_PORT - 0x20, SPI_CS_RFM12
	
	ret
