# Struct representations in Swift & C

This shows the difference between Swift & C struct layout (see [Swift ABI doc.][doc]).

[doc]: https://github.com/apple/swift/blob/687585e/docs/ABI/TypeLayout.rst "Swift BI: Type Layout"

To build & run:

```
mkdir ./.build
clang repr.c -o .build/repr && .build/repr
swiftc Repr.swift -I . -o .build/Repr && .build/Repr
```
