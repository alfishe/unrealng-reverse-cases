; --------------------------------------------------------------------------------------------------------------------
; physicstables.asm: The physics tables: contact, jaw radius, friction, collision records
;
; Four tables of the physics, all read only: ContactTable $DBFA (ball against ball), Table8x8 $DCFA (ball against a
; jaw point), FrictionTable $DD3A, CollisionRecords $DE3A. Their values fit a construction by d = SQR (dx*dx + dy*dy),
; see each entry and the notes.
; --------------------------------------------------------------------------------------------------------------------

; Ball against ball by |dx| (column) and |dy| (row), whole pixels: $80 overlap,
; 1-31 the contact ring, 0 apart
;
; Read by BallContacts $87EF at 16 |dy| + |dx| (|dx|, |dy| < 16): 157 of 256
; bytes read (w1, f1, p2, v1, m1; never in game). $80 for every cell with dx*dx
; + dy*dy <= 212, a record number 1-31 for the 31 cells with 218..250 (d from
; 14.8 to 15.8: two balls of 15 pixels touching), 0 for 260 and more. The ring
; numbers run by angle from the x axis: 1 = (15, 0), 16 = (11, 11), 31 = (0,
; 15); the cell (dx, dy) and (dy, dx) have n and 32 - n.
ContactTable:
  INCBIN "res/tables/ContactTable.bin",$0000,256

; Ball against a jaw point by |dx| (column) and |dy| (row): $80 overlap, 1
; touching, 0 apart
;
; Read by PointJaw $8CF8 at 8 |dy| + |dx| (twice: $8D1C and the back-off loop
; $8D41): 16 of 64 bytes read (w1, v1, m1). $80 for dx*dx + dy*dy <= 37, 1 for
; 40..53 (d 6.3 to 7.3: the ball's radius about 7), 0 for 58 and more. PointJaw
; also rejects |dx| = |dy| >= 5 before the read, so the cell (5, 5) = 1 is
; never used.
Table8x8:
  INCBIN "res/tables/Table8x8.bin",$0000,64

; Friction steps by the direction: row = |vy| nibble, column = |vx| nibble;
; high nibble y step, low nibble x step
;
; Read by FrictionSteps $90F5 at 16 ny + nx: 211 of 256 bytes read in all
; builds (the unread are mostly small-speed cells; (0, 0), a stopped ball,
; never). Every entry but (0, 0) = $44 is (round (5 ny / n), round (5 nx / n))
; with n = SQR (nx*nx + ny*ny) within 0.5 (row 0: $05, column 0: $50, the
; diagonal $44): a deceleration of 4.5 to 5.7, about 5, in 1/256 pixel a tick
; per tick, along the motion.
FrictionTable:
  INCBIN "res/tables/FrictionTable.bin",$0000,256

; 31 records of three words: nx^2, ny^2, |nx ny| for one contact-ring cell
; (0.8, $0100 = 1.0)
;
; Record n is ContactTable's ring cell n (dx, dy): w0 = 256 dx*dx / 225, w1 =
; 256 dy*dy / 225, w2 = 256 dx dy / 225, truncated (29 of 31; records 8 and 24
; have 41 for 40.96): the line of centres taken as if the distance were always
; 15. So w0 + w1 is 1.0 on the axes and 1.075 at 45 degrees (record 16: $89,
; $89, $89): a diagonal hit gives back up to 7.5 % more than an exact
; projection. Read by BallContacts $87EF through ContactRecordPtr $89B7
; (ScaleVelocity $89C4): 27 of the 31 read (w1, f1, p2, v1, m1); 6, 16, 18, 26
; not hit in any recording.
CollisionRecords:
  INCBIN "res/tables/CollisionRecords.bin",$0000,186
