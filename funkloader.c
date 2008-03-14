/*
 * Copyright(C) Benedikt K.
 * Copyright(C) Juergen Eckert
 * Copyright(C) 2007 Ulrich Radig <mail@ulrichradig.de>
 * Copyright(C) 2007 Jochen Roessner <jochen@lugrot.de>
 * Copyright(C) 2007,2008 Stefan Siegl <stesie@brokenpipe.de>

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
#include <util/delay.h>

#include "pinconfig.h"

#define noinline __attribute__((noinline))

extern unsigned short rfm12_trans (unsigned short);
extern unsigned char  rfm12_wait_read (void);

/* We need to store a whole page + page-number + crc */
#define BUFSZ (SPM_PAGESIZE + 2)
unsigned char funkloader_buf[BUFSZ];

static void
spi_init (void)
{
  /* configure MOSI, SCK, lines as outputs */
  SPI_DDR |= _BV(SPI_MOSI) | _BV(SPI_SCK);
  SPI_DDR &= ~_BV(SPI_MISO);

  /* initialize spi link to rfm12 module */
  SPI_CS_RFM12_DDR |= _BV(SPI_CS_RFM12);

  /* Enable the pullup */
  SPI_CS_RFM12_PORT |= _BV(SPI_CS_RFM12);

  /* enable spi, set master and clock modes (f/2) */
  SPCR = _BV(SPE) | _BV(MSTR);
  SPSR = _BV(SPI2X);
}


static void
rfm12_init (void)
{
  uint8_t i;

  for (i = 0; i < 10; i ++)
    _delay_ms (10);		/* wait until POR done */

  rfm12_trans (0xC0E0);		/* AVR CLK: 10MHz */
  rfm12_trans (0x80D7);		/* Enable FIFO */
  rfm12_trans (0xC2AB);		/* Data Filter: internal */
  rfm12_trans (0xCA81);		/* Set FIFO mode */
  rfm12_trans (0xE000);		/* disable wakeuptimer */
  rfm12_trans (0xC800);		/* disable low duty cycle */
  rfm12_trans (0xC4F7);	        /* autotuning: -10kHz...+7,5kHz */
  rfm12_trans (0x0000);

  rfm12_trans (0xa620);		/* rfm12_setfreq(RFM12FREQ(433.92)) */
  rfm12_trans (0x94ac);		/* rfm12_setbandwidth(5, 1, 4); */
  rfm12_trans (0xc609);		/* rfm12_setbaud(34482); */
  rfm12_trans (0x9820);		/* rfm12_setpower(0, 2); */
}


static void
funkloader_rx ()
{
  rfm12_trans(0x82C8);		/* RX on */
  rfm12_trans(0xCA81);		/* set FIFO mode */
  rfm12_trans(0xCA83);		/* enable FIFO */

  for (uint8_t i = 0; i < BUFSZ; i ++)
    funkloader_buf[i] = rfm12_wait_read ();

  rfm12_trans(0x8208);		/* RX off */
}

int
main (void)
{
  rfm12_init ();

  for (;;) 
    {
      /* try to receive a packet */
      funkloader_rx ();

      /* check packet validity */

      /* flash page */

      /* transmit reply */
    }

}
