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


void __attribute__ ((naked, section(".init3"))) init_avr (void);

void 
init_avr (void)
{
  /* clear zero-register */
  __asm volatile ("eor r1, r1 \n\t");

  /* clear sreg */
  __asm volatile ("out __SREG__, r1 \n\t");

  /* initialize stack pointer */
  __asm volatile ("ldi r28, lo8(%0) \n\t"
		  "ldi r29, hi8(%0) \n\t"
		  "out __SP_H__, r29     \n\t"
		  "out __SP_L__, r28     \n\t"
		  :
		  : "i" (RAMEND));
}
