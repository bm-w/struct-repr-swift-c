// Copyright (c) 2021, Bastiaan van de Weerd


#include <stdint.h>


typedef struct {
	uint64_t b;
	uint8_t c;
} c_inner;

typedef struct {
	uint32_t a;
	c_inner inner;
	uint16_t d;
} c_outer;
