// Copyright (c) 2021, Bastiaan van de Weerd


#include <stdalign.h>
#include <stdio.h>

#include "repr.h"


#define ASSERT_EQUAL(actual, expected, frmt, name) \
	if (actual != expected) { \
		fprintf(stderr, "Assertion failure: %s != …; actual: "frmt", expected: "frmt"\n", name, actual, expected); \
		return 1; \
	}

#define ASSERT_BYTES_EQUAL(actual, actual_offset, expected, n, actual_name) \
	for (size_t i = 0; i < n; ++i) { \
		char indexed_name[256]; \
		sprintf(indexed_name, "%s[%lu]", actual_name, actual_offset + i); \
		ASSERT_EQUAL(((uint8_t *)actual + actual_offset)[i], ((uint8_t *)expected)[i], "%u", indexed_name); \
	}


int main(void) {

#pragma mark Inner

	ASSERT_EQUAL(sizeof(c_inner), 16ul, "%lu", "sizeof(c_inner)");
	ASSERT_EQUAL(alignof(c_inner), 8ul, "%lu", "alignof(c_inner)");

	const c_inner inner = (c_inner){ .b = 0x0123456789abcdef, .c = 0x01 };

	const uint8_t inner_expected_bytes[] = { 0xef, 0xcd, 0xab, 0x89, 0x67, 0x45, 0x23, 0x01, 0x01 }; // Little-endian
	ASSERT_BYTES_EQUAL(&inner, 0, inner_expected_bytes, 9, "outer");


#pragma mark Outer

	ASSERT_EQUAL(sizeof(c_outer), 32ul, "%lu", "sizeof(c_outer)");
	ASSERT_EQUAL(alignof(c_outer), 8ul, "%lu", "alignof(c_outer)");

	const c_outer outer = (c_outer){ .a = 0x13579bdf, .inner = inner, .d = 0x37bf };

	const uint8_t outer_expected_bytes_a[] = { 0xdf, 0x9b, 0x57, 0x13 }; // Little-endian
	ASSERT_BYTES_EQUAL(&outer, 0, outer_expected_bytes_a, 4, "outer");

	const uint8_t outer_expected_bytes_b[] = { 0xef, 0xcd, 0xab, 0x89, 0x67, 0x45, 0x23, 0x01 }; // Little-endian
	ASSERT_BYTES_EQUAL(&outer, 8, outer_expected_bytes_b, 8, "outer");

	const uint8_t outer_expected_bytes_c[] = { 0x01 };
	ASSERT_BYTES_EQUAL(&outer, 16, outer_expected_bytes_c, 1, "outer");

	const uint8_t outer_expected_bytes_d[] = { 0xbf, 0x37 }; // Little-endian
	ASSERT_BYTES_EQUAL(&outer, 24, outer_expected_bytes_d, 2, "outer");


	printf("OK!\n");

	return 0;
}
