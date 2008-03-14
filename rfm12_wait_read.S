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

	.file	"rfm12_wait_read.S"
	.text
	
.global rfm12_wait_read
	.type	rfm12_wait_read, @function
rfm12_wait_read:

	/* Wait for the interrupt pin to become active. */
.L0:
	sbis	INT_PORT - 0x20, INT_PIN
	rjmp	.L0

	ldi	r25, 0xb0
	clr	r24
	rcall	rfm12_trans
	clr	r25
	
	ret
