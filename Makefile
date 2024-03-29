CC=avr-gcc
OBJCOPY=avr-objcopy
STRIP=avr-strip
SIZE=avr-size
AVRDUDE=avrdude

CPPFLAGS += -mmcu=atmega8 -DF_CPU=8000000UL 
CFLAGS += -std=gnu99 -Os -g -Wall -W
LDFLAGS += $(CFLAGS) -nostdlib -Wl,--section-start=.text=0x1E00

all: funkloader.hex funkloader.bin

funkloader: funkloader.o rfm12_trans.o rfm12_wait_read.o \
	funkloader_tx_reply.o avr_init.o
	$(CC) -o $@ $(LDFLAGS) $^
	$(SIZE) $@

clean:
	rm -f funkloader *.o *.s funkloader.hex funkloader.bin *~

%.hex: %
	$(OBJCOPY) -O ihex -R .eeprom $< $@

%.bin: %
	$(OBJCOPY) -O binary -R .eeprom $< $@

load: funkloader.hex
	$(AVRDUDE) -p m8 -U flash:w:$<

fuse:
	$(AVRDUDE) -p m8 -U lfuse:w:0xa4:m
	$(AVRDUDE) -p m8 -U hfuse:w:0xdc:m

funkloader.o: funkloader.c pinconfig.h
funkloader_tx_reply.o: funkloader_tx_reply.S pinconfig.h
rfm12_trans.o: rfm12_trans.S pinconfig.h
rfm12_wait_read.o: rfm12_wait_read.S pinconfig.h

.PHONY:	fuse load clean
