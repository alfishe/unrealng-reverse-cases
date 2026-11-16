# track

The stage list, the track's patterns and the track: `TrackTables` `$EB00-$F0AF` (1456 bytes), copied by Init to
`$5E80`; all addresses in the text are the copy's. Every stage plays the same track one after another.

| File | Holds |
| --- | --- |
| `stage1.txt` ... `stage5.txt` | the stage's segments (StageList `$5E80`, 140 in all), then its part of the track (Track `$60D0`) with the distance at each command; stage 5 ends with the 5 leftover bytes `$F0AB-$F0AF` |
| `patterns.txt` | the patterns (`$5F0C-$60CF`) the track calls; the format of the commands is in its header |
| `course1.png` ... `course5.png` | views drawn by `tools/course.py` (not read by the build) |

A segment is 128 distance units (SegmentLeft); its byte gives the bend (bits 0-1), the crest (2-3), the bend's
side (4), the stage's end (5) and bits 6-7 (always `$80`, the segment's length code). The track splits into the
stages by distance (32, 23, 26, 27 and 32 segments); the split is a comment for the reader, the bytes run on.
Unreferenced: the first pattern bytes `$5F0C-$5F0F` (no call or jump reaches them) and the zeros `$60C6-$60CF`.
