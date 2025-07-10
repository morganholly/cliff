# Cliff <sub><sup><sub>*Configurable Like-IFF*</sub></sup></sub>
##### A framework for writing file IO for files with IFF-like structure

---
> [!WARNING] 
> **!!! unfinished and not yet functional !!!**

IFF uses a chunk structure for parsing files as they are read, converting them into an internal representation. This differs from other types, like TTF, which have a header that stores offsets and lengths which can be jumped to as needed for using the file.

IFF, RIFF, AIFF, PNG, JPEG`(.*)`, and likely GIF, should all be compatible, along with many other similar file types. Cliff is designed for maximum flexibility, even weird formats made on machines with a non-monotonic endianness are possible to read and write using the custom byte remapping functionality in cliff.

The goal of Cliff is to be the backbone of file IO for any IFF-like file format, so that you simply assign or define the parser settings, and define `proc`s for converting binary data to meaningful objects, and the rest is handled by Cliff.

MIT Licensed.
