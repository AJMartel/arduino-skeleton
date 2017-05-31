/*
 * SerialDebug.c
 *
 *  Created on: Mar 14, 2017
 *      Author: dat
 */

#include <avr/io.h>
#include <stdio.h>
#include "SerialDebug.h"

#define BAUD 9600              // Baud rate used by the LCD
#define MYUBRR F_CPU/16/BAUD-1   // Value for UBRR0 register

/*
 serial_in - Read a byte from the USART0 and return it
 */
char SerialDebugGetChar()
{
	loop_until_bit_is_set(UCSR0A, RXC0); /* Wait until data exists. */
	return UDR0;
}

/*
 sci_out - Output a byte to SCI port
 */
void sci_out(char ch)
{
	loop_until_bit_is_set(UCSR0A, UDRE0); /* Wait until data register empty. */
	UDR0 = ch;
}

/*
 sci_outs - Print the contents of the character string "s" out the SCI
 port. The string must be terminated by a zero byte.
 */
void sci_outs(const char *s)
{
	unsigned char ch;

	while ((ch = *s++) != (char) '\0')
	{
		sci_out(ch);
	}
}

void SerialDebugInit()
{
	UBRR0 = MYUBRR;          // Set baud rate
	UCSR0B |= (1 << TXEN0);  // Turn on transmitter
	UCSR0B |= (1 << RXEN0); // Turn on receiver
	UCSR0A &= ~(_BV(U2X0));
	UCSR0C = _BV(UCSZ01) | _BV(UCSZ00); /* 8-bit data */

	SerialDebugPrint("Serial Debug activated");
	SerialDebugPrint("Compiled on : %s %s", __DATE__, __TIME__);
}

/*
 * Printf to serial port
 */
void _SerialDebugPrint1(const char* message)
{
	sci_outs(message);
	sci_outs("\n\r");
}

void _SerialDebugPrintNoEndl(const char* message)
{
	sci_outs(message);
}

void SerialDebugGetLine(char* buffer, char echo)
{
	uint8_t i = 0;
	while (1)
	{
		buffer[i] = SerialDebugGetChar();
		if (echo)
		{
			sci_out(buffer[i]); // echo
		}
		if (buffer[i] == '\n' || buffer[i] == '\r')
			break;
		++i;
	}
	buffer[i] = '\0';

	if (echo)
	{
		sci_outs("\n\r");
	}
}
