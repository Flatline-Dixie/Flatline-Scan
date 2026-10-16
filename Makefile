CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c99
LDFLAGS =

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    LDFLAGS += -lpthread
endif
ifeq ($(UNAME_S),Darwin)
    LDFLAGS += -lpthread
endif

SOURCES = main.c scanner.c
OBJECTS = $(SOURCES:.c=.o)
TARGET = flatline-scan
TEST_TARGET = port_parser_test

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(TEST_TARGET): port_parser_test.c main.c scanner.c scanner.h
	$(CC) $(CFLAGS) -o $@ port_parser_test.c scanner.c $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $<

test-c: $(TEST_TARGET)
	./$(TEST_TARGET)

test-haskell:
	ghc -i. -o port_spec_test PortSpecTest.hs
	./port_spec_test

test: test-c test-haskell

clean:
	rm -f $(OBJECTS) $(TARGET) $(TEST_TARGET) port_spec_test PortSpec.o PortSpec.hi PortSpecTest.o PortSpecTest.hi PortSpec_stub.h

.PHONY: all clean test test-c test-haskell
