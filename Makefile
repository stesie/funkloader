CC=avr-gcc
OBJCOPY=avr-objcopy

CPPFLAGS += -mmcu=atmega8 -DF_CPU=8000000UL 
CFLAGS += -std=gnu99 -Os -g
LDFLAGS += $(CFLAGS)

all: funkloader.hex

funkloader: funkloader.o rfm12_trans.o rfm12_wait_read.o

clean:
	rm -f funkloader *.o

%.hex: %
	$(OBJCOPY) -O ihex -R .eeprom $< $@
