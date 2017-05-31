/*
 * SerialDebug.h
 *
 *  Created on: Mar 14, 2017
 *      Author: dat
 */

#ifndef SERIALDEBUG_H_
#define SERIALDEBUG_H_

#include <stdio.h>
#include <string.h>

#include "MemoryFree.h"

#define SERIALDEBUG_DEFAULT_BAUD	9600 // default baud rate when calling SerialDebugInit()

#ifdef DEBUG
#ifndef CXXTEST
char __msg[128];
#define LOG(msg, arg...) \
	{  \
	snprintf(__msg, 128, msg, ##arg);\
	SerialDebugPrint("%s:%d - (%d) %s", __FILE__, __LINE__, freeMemory(), __msg); \
	}
#else
#define LOG(msg, arg...) \
	{ char __msg[128]; \
	sprintf(__msg, msg, ##arg);\
	printf("%s:%d - %s \n", __FILE__, __LINE__, __msg); \
	}
#endif
#else
#define LOG(...) ;
#endif

#define TRACE() LOG(" ");
#define TRACE_INT(var) LOG("[%s] = %d", #var, var);
#define TRACE_STRING(var) LOG("[%s] = %s", #var, var);

/*
 * Init serial port, use default baud rate
 */
void SerialDebugInit(void);

/**
 * Set baud rate for serial port and reinit it
 */
void SerialDebugInitWithBaudRate(unsigned baudrate);

/*
 * Printf to serial port
 */
char _msg[128];
#define SerialDebugPrint(arg...) \
{ 	\
	snprintf(_msg, 128, ##arg); \
	_SerialDebugPrint1(_msg); \
}
#define SerialDebugPrintNoEndl(arg...) \
{ 	\
	snprintf(_msg, 128, ##arg); \
	_SerialDebugPrintNoEndl(_msg); \
}
void _SerialDebugPrint1(const char* message);
void _SerialDebugPrintNoEndl(const char* message);


/*
 * Fetches byte from receive buffer
 */
char SerialDebugGetChar(void);

/**
 * Get line from serial input
 * This will wait until \n is entered, so not async compatible
 *
 * @param buffer - line will be stored in here, make sure buffer is allocated
 * 					before calling this function
 * @param echo - 1 will echo character to console
 */
void SerialDebugGetLine(char* buffer, char echo);

#endif /* SERIALDEBUG_H_ */
