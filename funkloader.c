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

#include <avr/pgmspace.h>
#include <avr/boot.h>
#include <avr/io.h>

#include <util/delay.h>

#include "pinconfig.h"

#define noinline __attribute__((noinline))

extern unsigned short rfm12_trans (unsigned short);
extern unsigned char  rfm12_wait_read (void);
extern void funkloader_tx_reply (void);

/* We need to store magic byte + page-number + a whole page + crc */
#define BUFSZ (SPM_PAGESIZE + 3)
unsigned char funkloader_buf[BUFSZ];

#define MAGIC_FLASH_PAGE 0x23
#define MAGIC_LAUNCH_APP 0x42


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
  /* Wait for POR to finish. */
  while (INT_PORT & _BV (INT_PIN));

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
flash_page (void)
{
#if SPM_PAGESIZE < 256
  uint8_t i;
#else
  uint16_t i;
#endif

  uint16_t page = funkloader_buf[1] * SPM_PAGESIZE;

  eeprom_busy_wait();

  boot_page_erase(page);
  boot_spm_busy_wait();

  for(i = 0; i < SPM_PAGESIZE; i += 2) {
    /* Set up little-endian word. */
    uint16_t w = funkloader_buf[2 + i];
    w += funkloader_buf[3 + i] << 8;
        
    boot_page_fill (page + i, w);
  }

  boot_page_write (page);
  boot_spm_busy_wait();

  /* Reenable RWW-section again. */
  boot_rww_enable ();
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


static void
crc_update (unsigned char *crc, uint8_t data)
{
  for (uint8_t j = 0; j < 8; j ++)
    {
      if ((*crc ^ data) & 1)
	*crc = (*crc >> 1) ^ 0x8c;
      else
        *crc = (*crc >> 1);

      data = data >> 1;
    }
}


static uint8_t
crc_check (void)
{
  unsigned char crc_chk = 0;
  unsigned char *ptr = funkloader_buf + 2;

  for (uint8_t i = 0; i < SPM_PAGESIZE; i ++)
    crc_update (&crc_chk, *(ptr ++));

  /* subtract one from the other, this is far cheaper than comparation */
  crc_chk -= *ptr;
  return crc_chk;
}

int
main (void)
{
  spi_init ();
  rfm12_init ();

  for (;;) 
    {
      /* try to receive a packet */
      funkloader_rx ();

      /* check packet validity */
      if (funkloader_buf[0] == MAGIC_LAUNCH_APP)
	break;			/* FIXME this doesn't send a reply */

      if (funkloader_buf[0] != MAGIC_FLASH_PAGE)
	continue;		/* unknown magic, ignore. */

      if (crc_check ())
	continue;		/* crc invalid */

      /* flash page */
      flash_page ();

      /* transmit reply */
      rfm12_trans(0x8238);	/* TX on */
      funkloader_tx_reply ();
      rfm12_trans(0x8208);	/* TX off */
    }
}
