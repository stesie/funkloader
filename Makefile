CC=avr-gcc
OBJCOPY=avr-objcopy
STRIP=avr-strip

CPPFLAGS += -mmcu=atmega8 -DF_CPU=8000000UL 
CFLAGS += -std=gnu99 -Os -g -Wall -W
LDFLAGS += $(CFLAGS)

#
# in order to get rid of .bss and .data initialization code,
# don't link in stdlibs but just crts8515 (for stack initialization)
#
LDFLAGS += -nostdlib `avr-gcc -print-file-name=crts8515.o`

all: funkloader.hex

funkloader: funkloader.o rfm12_trans.o rfm12_wait_read.o exit.o \
	funkloader_tx_reply.o
	$(CC) -o $@ $(LDFLAGS) $^

clean:
	rm -f funkloader *.o

%.hex: %
	$(OBJCOPY) -O ihex -R .eeprom $< $@
