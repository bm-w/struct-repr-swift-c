// Copyright © 2021, Bastiaan van de Weerd


// MARK: Swift Inner

struct SwiftInner {
	let b: UInt64
	let c: UInt8
}

assertEqual(MemoryLayout<SwiftInner>.alignment, 8, name: "MemoryLayout<(Swift) …Inner>.alignment")
assertEqual(MemoryLayout<SwiftInner>.size, 9, name: "MemoryLayout<(Swift) …Inner>.size")
assertEqual(MemoryLayout<SwiftInner>.stride, 16, name: "MemoryLayout<(Swift) …Inner>.stride")

let swiftInner = SwiftInner(b: 0x0123456789abcdef, c: 0x01)
withUnsafeBytes(of: swiftInner) { innerBytes in
	let expectedBytes: [UInt8] = [
		0xef, 0xcd, 0xab, 0x89, 0x67, 0x45, 0x23, 0x01, // `b`; little-endian
		0x01 // `c`
	]
	assertElementsEqual(innerBytes, expectedBytes, name: "(Swift) inner…")
}


// MARK: Swift Outer

struct SwiftOuter {
	let a: UInt32
	let inner: SwiftInner
	let d: UInt16 // Unlike in standard C struct layout, `d` is placed inside the trailing stride padding of `inner`
}

assertEqual(MemoryLayout<SwiftOuter>.alignment, 8, name: "MemoryLayout<(Swift) …Outer>.alignment")
assertEqual(MemoryLayout<SwiftOuter>.size, 20, name: "MemoryLayout<(Swift) …Outer>.size")
assertEqual(MemoryLayout<SwiftOuter>.stride, 24, name: "MemoryLayout<(Swift) …Outer>.stride")

let swiftOuter = SwiftOuter(a: 0x13579bdf, inner: swiftInner, d: 0x37bf)
withUnsafeBytes(of: swiftOuter) { outerBytes in
	// NOTE: Values in padding are undefined (not necessarily zeroed-out)

	let rA = 0..<4, expectedBytesA: [UInt8] = [0xdf, 0x9b, 0x57, 0x13] // Little-endian
	assertElementsEqual(outerBytes[rA], expectedBytesA, name: "(Swift) outer…[rA: \(rA)]")

	let rB = 8..<16, expectedBytesB: [UInt8] = [0xef, 0xcd, 0xab, 0x89, 0x67, 0x45, 0x23, 0x01] // Little-endian
	assertElementsEqual(outerBytes[rB], expectedBytesB, name: "(Swift) outer…[rA: \(rB)]")

	let rC = 16..<17, expectedBytesC: [UInt8] = [0x01]
	assertElementsEqual(outerBytes[rC], expectedBytesC, name: "(Swift) outer…[rC: \(rC)]")

	let rD = 18..<20, expectedBytesD: [UInt8] = [0xbf, 0x37] // Little-endian
	assertElementsEqual(outerBytes[rD], expectedBytesD, name: "(Swift) outer…[rC: \(rD)]")
}


// MARK: - C

import crepr


// MARK: C Inner

typealias CInner = crepr.c_inner

assertEqual(MemoryLayout<CInner>.alignment, 8, name: "MemoryLayout<(C) …Inner>.alignment")
assertEqual(MemoryLayout<CInner>.size, 16, name: "MemoryLayout<(C) …Inner>.size")
assertEqual(MemoryLayout<CInner>.stride, 16, name: "MemoryLayout<(c) …Inner>.stride")

let cInner = CInner(b: 0x0123456789abcdef, c: 0x01)
withUnsafeBytes(of: cInner) { innerBytes in
	let expectedBytes: [UInt8] = [
		0xef, 0xcd, 0xab, 0x89, 0x67, 0x45, 0x23, 0x01, // `b`; little-endian
		0x01 // `c`
	]
	assertElementsEqual(innerBytes[..<9], expectedBytes, name: "(C) inner…")
}


// MARK: C Outer

/// This shows the difference between Swift (see `SwiftOuter`) & C layout:
///
/// > Note that this differs from C or LLVM's normal layout rules in that
/// > _size_ and _stride_ are distinct; whereas C layout requires that an
/// > embedded struct's size be padded out to its alignment and that nothing be
/// > laid out there, Swift layout allows an outer struct to lay out fields in
/// > the inner struct's tail padding, alignment permitting.
///
/// From: https://github.com/apple/swift/blob/687585e/docs/ABI/TypeLayout.rst
///
typealias COuter = crepr.c_outer

assertEqual(MemoryLayout<COuter>.alignment, 8, name: "MemoryLayout<(C) …Outer>.alignment")
assertEqual(MemoryLayout<COuter>.size, 32, name: "MemoryLayout<(C) …Outer>.size")
assertEqual(MemoryLayout<COuter>.stride, 32, name: "MemoryLayout<(C) …Outer>.stride")

let cOuter = COuter(a: 0x13579bdf, inner: cInner, d: 0x37bf)
withUnsafeBytes(of: cOuter) { outerBytes in
	// NOTE: Values in padding are undefined (not necessarily zeroed-out)

	let rA = 0..<4, expectedBytesA: [UInt8] = [0xdf, 0x9b, 0x57, 0x13] // Little-endian
	assertElementsEqual(outerBytes[rA], expectedBytesA, name: "(C) outer…[rA: \(rA)]")

	let rB = 8..<16, expectedBytesB: [UInt8] = [0xef, 0xcd, 0xab, 0x89, 0x67, 0x45, 0x23, 0x01] // Little-endian
	assertElementsEqual(outerBytes[rB], expectedBytesB, name: "(C) outer…[rA: \(rB)]")

	let rC = 16..<17, expectedBytesC: [UInt8] = [0x01]
	assertElementsEqual(outerBytes[rC], expectedBytesC, name: "(C) outer…[rC: \(rC)]")

	let rD = 24..<26, expectedBytesD: [UInt8] = [0xbf, 0x37] // Little-endian
	assertElementsEqual(outerBytes[rD], expectedBytesD, name: "(C) outer…[rC: \(rD)]")
}


print("OK!")


// MARK: - Util.

func assertEqual<T: Equatable>(_ actual: T, _ expected: T, name: String) {
	assert(actual == expected, {
		let unequalName = "\(name) != …"
		let padding = Array(repeating: " ", count: unequalName.count + 2).joined(separator: "")
		return "\n\(unequalName); actual:   \(actual)\n\(padding)expected: \(expected)"
	}())
}

func assertElementsEqual<CL, CR>(_ actual: CL, _ expected: CR, name: String)
where CL: Collection, CR: Collection, CL.Element == CR.Element, CL.Element: Equatable {
	assert(actual.elementsEqual(expected),
		"!\(name).elementsEqual(…);\n  actual:   \(Array(actual))\n  expected: \(Array(expected))")
}

