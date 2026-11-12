; The run-time code of page $66: the bytes of PageTail66 ($6FCA-$703E in src/game, row 9 of the page tails)
; decoded at the addresses BuildPageTails copies them to ($6682-$66F6). Not part of the game build: this file only
; gives the code panel of an animation (kit/routine_anim.py --listing) the instructions the image holds as data.
;
;   sjasmplus --nologo --lst=build/runtime66.lst --raw=build/runtime66.bin tools/runtime66.asm
;   cmp build/runtime66.bin <(dd if=build/game.bin bs=1 skip=$((0x13CA)) count=117 2>/dev/null)   ; identical
;
; docs/05-controls.md 5.7 (PauseGame) and docs/07-objects.md 7.10 (the message banner).

EndFlags        EQU $6652
PauseFlag       EQU $664C
BannerSegments  EQU $6640               ; +$40 of page $66: the banner's path segments left
MessageRequest  EQU $79FF
MessageNumber   EQU $7B63
BannerTemplate  EQU $65A6               ; template 30, the message banner (PathControl)
NewGame         EQU $5C4D
ShowGameOverWait EQU $831A
PauseLong       EQU $8330
DelayBC         EQU $8333
ReadInput       EQU $8529
ActorUpdate     EQU $8E2B
ExpireActor     EQU $97A3
InitActor       EQU $A65D

        ORG $6682
PauseGame:
        LD A,(EndFlags)
        OR A
        JR NZ,PauseDone                 ; the end: no pause
        CALL ReadInput
        EI
        JR NZ,PauseShow                 ; no fire: pause
        CALL ShowGameOverWait           ; fire: the quit
        JP NewGame
PauseShow:
        LD A,$03                        ; PAUSE GAME
        CALL ShowMessage
        CALL RunBanner                  ; the banner flies out
PausePoll:
        LD BC,$DFFE                     ; P again? (every 5 frames)
        IN A,(C)
        AND $01
        EI
        LD B,$05
PauseHalt:
        HALT
        DJNZ PauseHalt
        JR NZ,PausePoll
        LD BC,$4000
        CALL DelayBC
PauseDone:
        XOR A
        LD (PauseFlag),A
        RET
PendingMessage:
        CALL ShowMessage                ; A = the request
        XOR A
        LD (MessageRequest),A
RunBanner:
        LD HL,$6602                     ; the banner, to its end
RunBannerLoop:
        CALL ActorUpdate
        LD A,(HL)
        RRA
        JR C,RunBannerLoop
        RET
ShowMessage:
        PUSH AF
        LD HL,$6602                     ; a weapon out? run it out
        LD A,(HL)
        RRA
        JR NC,ShowMessageStart
        CALL ExpireActor
        CALL RunBanner
ShowMessageStart:
        POP AF
        DEC A
        LD (MessageNumber),A            ; message A - 1
        LD BC,$48F0                     ; X $48, Y $F0 (above)
        LD DE,BannerTemplate
        XOR A
        CALL InitActor
        EX DE,HL
        LD L,$02
        LD (HL),$81                     ; active; bit 7: alone
ShowMessageLoop:
        CALL ActorUpdate
        LD A,(BannerSegments)
        CP $02                          ; until it holds
        JR NZ,ShowMessageLoop
        JP PauseLong
