FREQ=8000000UL

CC=avr-gcc
OBJCOPY=avr-objcopy
STRIP=avr-strip
SIZE=avr-size
AVRDUDE=avrdude

CPPFLAGS += -mmcu=atmega88 -DF_CPU=$(FREQ)
CFLAGS += -std=gnu99 -Os -g -Wall -W
LDFLAGS += $(CFLAGS) -nostdlib -Wl,--section-start=.text=0x1E00

ifeq ($(FREQ),8000000UL)
  lfuse=0xe2
else ifeq ($(FREQ),1000000UL)
  lfuse=0x62
endif

all: funkloader.hex

funkloader: funkloader.o rfm12_trans.o rfm12_wait_read.o \
	funkloader_tx_reply.o avr_init.o
	$(CC) -o $@ $(LDFLAGS) $^
	$(SIZE) $@

clean:
	rm -f funkloader *.o *.s *.hex *~

%.hex: %
	$(OBJCOPY) -O ihex -R .eeprom $< $@

load: funkloader.hex
	$(AVRDUDE) -p m88 -U flash:w:$<

fuse:
ifeq ($(lfuse),)
	@echo "don't know what to fuse, unsupported frequency."
else
	$(AVRDUDE) -p m88 -U lfuse:w:$(lfuse):m
	$(AVRDUDE) -p m88 -U hfuse:w:0xdd:m
	$(AVRDUDE) -p m88 -U efuse:w:0x04:m
endif

funkloader.o: funkloader.c pinconfig.h
funkloader_tx_reply.o: funkloader_tx_reply.S pinconfig.h
rfm12_trans.o: rfm12_trans.S pinconfig.h
rfm12_wait_read.o: rfm12_wait_read.S pinconfig.h

.PHONY:	fuse load clean
