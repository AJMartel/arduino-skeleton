# arduino-skeleton
This is the first embarkment of my learning experience & side projects. Let's see how far I could go :)

Skeleton framework for Arduino with/without RTOS, uses avr gcc/ g++

Currently works with Unix system
Note: this repo doesn't support Arduino IDE. Everything must be run from Makefile, because of reason

# Directory Structure
        +---test/                               - all component testers go here, test code uses no os
        +---os/                                 - optional RTOS (currently ChibiOS)
        |       +---ChibiOS/                    - 
        +---c-project/                          - skeleton  for C based projects using avr-gcc
        |       +---with-os/                    -
        |	+---without-os/                 -
        +---cpp-project/                        - skeleton  for C++ based projects using avr-g++
        |	+---with-os/                    -
        |	+---without-os/                 -
        +---doc                                 - documentations
        +---common/                             - includes common/unit test makefiles for all projects
        |       +---utils/                      - common protocols such as soft serial, i2c, debugging
	
# UnitTest framework (Software)
        This repo supports cxxtest framework, run make check will invoke testgen and run the test binary
        Put all test headers in test directory of project directory, see test/GPS-breakout-board for example

# Usage
        go to c*-project/with*-os/ directory and use its makefile
        go to test/ to checkout individual module test code, all code here must be in C
	
# Question & Bug fix?
	Please email author tdpham1105@yahoo.com
	Or file issue via github

