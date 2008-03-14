CC=avr-gcc
CPPFLAGS += -mmcu=atmega8 -DF_CPU=8000000UL 
CFLAGS += -std=gnu99 -Os -g
# CFLAGS += -mcall-prologues
LDFLAGS += $(CFLAGS)

funkloader: funkloader.o rfm12_trans.o rfm12_wait_read.o

clean:
	rm -f funkloader *.o
