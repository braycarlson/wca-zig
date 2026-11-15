# wca-zig

A library for the Windows Core Audio API. The raw API requires COM interfaces, verbose boilerplate, and documentation that assumes prior COM knowledge, so the library wraps it in Zig. The library covers device enumeration, endpoint and session volume, peak meters, shared-mode playback and capture, loopback capture, and device change notifications, and the `examples` directory has a program for each of the main paths.
