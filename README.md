# c64-tracker

### pattern data

byte | description
----:|----
0X | TODO: X=0..E: wait 0 to 14 (pattern compression)
0F | gate-off
1Y | Y=0..F: play instrument Y root-note
YN | TODO: Y=2..F, N=0..F: play instrument Y-2 at root-note + N + 1

### wave table

byte | description
----:|----
00 | end
01.. 8E| waveform
8F | TODO: waveform 81 with frequency $FFFF burst
