# Loader

The SpeedLock second stage's data: zeros, the first block table and the countdown digits 0-9 (8 bytes each).

Format: bytes.

| File | Entry | Address | Bytes | What |
| --- | --- | --- | --- | --- |
| `stage2-data.bin` (bytes) | Stage2Data (`src/loader/stage2.ann`) | `$FF17` | 185 | Zeros, the first block table at $FF4A (5-byte records: address, length, the $7FFD bank) and the countdown digits 0-9 (8 bytes each from $FF60) |
