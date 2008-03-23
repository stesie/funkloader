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

	.file "flash_page.S"
	.text

.global flash_page
	.type flash_page, @function

	;; store data from funkloader_buf[2..65] to flash area
	;; the page number is available at funkloader_buf[1]
flash_page:

	;; set up data pointer in Y
	ldi	r28, funkloader_buf + 1
	clr	r29
	
	;; set up page pointer in Z
	ld	r30, Y+		 ; page number
	mov	r31, r30

	;; r30 <<= 6
	swap	r30
	lsl	r30
	lsl	r30
	andi	r30, 0xc0

	;; r31 >>= 2
	lsr	r31
	lsr	r31

	movw	r26, r30	; keep copy of flash adress in X
	
	;; current state:
	;; ----------------------------
	;; Y = funkloader_buf + 2
	;; Z = funkloader_buf[1] * 64  (copy in X)

	;; erase page
	ldi	r19, _BV (SPMEN) | _BV (PGERS)
	sts	SPMCR, r19
	spm

	;; busy wait
.L1:
	in	r0, SPMCR
	sbrc	r0, SPMEN
	rjmp	.L1

	;; fill page
	ldi	r18, _BV (SPMEN)
.L2:
	ld	r0, Y+
	ld	r1, Y+
	sts	SPMCR, r18	; _BV (SPMEN)
	spm

	subi	r30, -2		; this doesn't handle overflows, shouldn't hurt

	;; compare lsb 6 bits against zero
	;; if zero -> page full, loop otherwise
	mov	r23, r30
	andi 	r23, 0x3f
	brne	.L2		; fill page loop.

	;; page full, write now
	movw	r30, r26
	ldi	r20, _BV (SPMEN) | _BV (PGWRT)
	sts	SPMCR, r20
	spm

	;; busy wait
.L3:
	in	r0, SPMCR
	sbrc	r0, SPMEN
	rjmp	.L3

	;; rww enable
	ldi	r20, _BV (SPMEN) | _BV (RWWSRE)
	sts	SPMCR, r20
	spm
	
	clr 	r1
	ret
	
	.size	flash_page, .-flash_page

