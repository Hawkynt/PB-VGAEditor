'Codepage 850
SHARED mausx%, mausy%, mausk%
call MausInit
SCREEN 12
col = 1
call mausset (320, 240)
mausx% = 320
mausy% = 240
xmax% = 534
ymax% = 464
ydiff% = 6: '10
xdiff% = 6: '10
scrx% = xmax% + 10
scry% = 150
rand% = 8
maxt = (ymax% - 50) / ydiff%
DIM t$(maxt + 1)
 LOCATE 12, 35
 COLOR 1
 PRINT ">>SynthelicZ<< presents"
 FOR t = 1 TO 4000
 NEXT
 CLS
 LOCATE 12, 35
 COLOR 2
 PRINT "a Hawkynt production"
 FOR t = 1 TO 4000
 NEXT
 CLS
 PRINT
 PRINT
 PRINT
 COLOR 2: PRINT SPC(14); "²²²²²² ²²  ²² ²²²²²²?        "; : COLOR 1: PRINT "²²  ²²   ±±±±    °°  "
 COLOR 2: PRINT SPC(14); "?²² ?²²  ²²  ²²   ?        "; : COLOR 1: PRINT "²²  ²²  ±±  ±±  °°°° "
 COLOR 2: PRINT SPC(14); "  ²²   ²²  ²²  ²² ?          "; : COLOR 1: PRINT "²²  ²² ±±      °°  °°"
 COLOR 2: PRINT SPC(14); "  ²²   ²²²²²²  ²²²²           "; : COLOR 1: PRINT "²²  ²² ±±      °°  °°"
 COLOR 2: PRINT SPC(14); "  ²²   ²²  ²²  ²² ?          "; : COLOR 1: PRINT "²²  ²² ±±  ±±?°°°°°°"
 COLOR 2: PRINT SPC(14); "  ²²   ²²  ²²  ²²   ?        "; : COLOR 1: PRINT " ²²²²  ±±   ±± °°  °°"
 COLOR 2: PRINT SPC(14); " ²²²²  ²²  ²² ²²²²²²?        "; : COLOR 1: PRINT "  ²²    ±±±±±± °°  °°"
 FOR t = 1 TO 5
  PRINT
 NEXT
 COLOR 4
 PRINT , "     ÛÛÛÛÛÛ?ÛÛÛÛ?  ÛÛÛÛÛÛ ÛÛÛÛÛÛ   ÛÛ?  ÛÛÛÛÛÛ "
 PRINT , "      ÛÛ   ? ÛÛ ÛÛ    ÛÛ   ?ÛÛ ? ÛÛ ÛÛ   ÛÛ  ÛÛ"
 PRINT , "      ÛÛ ?   ÛÛ  ÛÛ   ÛÛ     ÛÛ   ÛÛ   ÛÛ  ÛÛ  ÛÛ"
 PRINT , "      ÛÛÛÛ    ÛÛ  ÛÛ   ÛÛ     ÛÛ   ÛÛ   ÛÛ  ÛÛÛÛ?"
 PRINT , "      ÛÛ ?   ÛÛ  ÛÛ   ÛÛ     ÛÛ   ÛÛ   ÛÛ  ÛÛ ÛÛ "
 PRINT , "      ÛÛ   ? ÛÛ ÛÛ    ÛÛ     ÛÛ    ÛÛ ÛÛ   ÛÛ  ÛÛ"
 PRINT , "     ÛÛÛÛÛÛ?ÛÛÛÛ?  ÛÛÛÛÛÛ  ÛÛÛÛ    ÛÛ?  ÛÛ?  ?
call wartebewegung
aaa:
 CLS
 n$ = "UNBENANNT"
 FOR x% = 0 TO xmax% STEP xdiff%
  LINE (x%, 50)-(x%, ymax%), rand%
 NEXT x%
 FOR y% = 50 TO ymax% STEP ydiff%
  LINE (0, y%)-(xmax%, y%), rand%
 NEXT y%
 x% = 0
 y% = 50
 col = 1
 c = 15
 DO
  SELECT CASE col
   CASE 1
    cot = 4
   CASE 2
    cot = 14
  END SELECT
  call getmaus
  ox% = x%
  oy% = y%
  x% = INT(mausx% / xdiff%) * xdiff%
  y% = INT(mausy% / ydiff%) * ydiff% + 2
   LINE (ox%, oy%)-STEP(xdiff%, ydiff%), rand%, B
   IF x% > xmax% - xdiff% THEN x% = xmax% - xdiff%
   IF x% < 0 THEN x% = 0
   IF y% < 50 THEN y% = 50
   IF y% > ymax% - ydiff% THEN y% = ymax% - ydiff%
   IF mausk% = 1 THEN
    LINE (x%, y%)-STEP(xdiff%, ydiff%), c, BF
    PSET (x% / xdiff% + scrx% + 3, y% / ydiff% + scry% - 2), c
    save = 0
   ELSEIF mausk% = 2 THEN
    save = 0
    LINE (x%, y%)-STEP(xdiff%, ydiff%), 0, BF
    PSET (x% / xdiff% + scrx% + 3, y% / ydiff% + scry% - 2), 0
   END IF
   LINE (x%, y%)-STEP(xdiff%, ydiff%), cot, B
   LINE (15, 33)-STEP(xdiff%, ydiff%), c, BF
   LINE (scrx%, scry%)-STEP(xmax% / xdiff% + 5, maxt + 9), col, B
   IF modus = 1 THEN
    LINE (x%, y%)-STEP(xdiff%, ydiff%), c, BF
    PSET (x% / xdiff% + scrx% + 3, y% / ydiff% + scry% - 2), c
   END IF
  LOCATE 1, 70
  PRINT n$
  LOCATE 2, 1
  COLOR 5
  PRINT "ESC Programm verlassen  n  =New Graphic  l  =Load File EINFG=Line-Modus"
  COLOR c
  LOCATE 3, 6
  PRINT "Farbe"
  LOCATE 3, 14
  COLOR 1
  PRINT "c  =Farbe ";
  COLOR 2
  PRINT "Maus links       ";
  COLOR 4
  PRINT "Maus rechts        ";
  COLOR 14
  PRINT "s  =Speichern"
  t$ = INKEY$
  IF t$ = "" GOTO aag
  t = ASC(t$)
  IF LEN(t$) > 1 THEN t = ASC(RIGHT$(t$, 1))
  SELECT CASE t
   CASE 110
    IF save = 0 THEN
     LOCATE 1, 1
     COLOR 4
     BEEP
     PRINT "ACHTUNG Datei nicht gespeichert . Fortfahren ";
     INPUT "", z$
     LOCATE 1, 1
     PRINT STRING$(79, " ")
     IF LCASE$(z$) = "n" THEN GOTO aab
    END IF
    GOTO aaa
aab:
   CASE 99
    COLOR 15
    LOCATE 1, 1
    INPUT "Farbe :"; c
    LOCATE 1, 1
    PRINT STRING$(79, 0)
   CASE 108
    IF save = 0 THEN
     LOCATE 1, 1
     COLOR 4
     BEEP
     PRINT "ACHTUNG Datei nicht gespeichert . Fortfahren ";
     INPUT "", z$
     LOCATE 1, 1
     PRINT STRING$(79, " ")
     IF LCASE$(z$) = "n" THEN GOTO aac
    END IF
    p$ = ""
    f$ = ""
    z$ = ""
    COLOR 15
    LOCATE 1, 1
    INPUT "Pfad , wenn n”tig :", p$
    IF p$ <> "" THEN p$ = p$ + "\"
    LOCATE 1, 1
    PRINT STRING$(79, 32)
    LOCATE 1, 1
    INPUT "File-Name :", f$
    LOCATE 1, 1
    PRINT STRING$(79, 32)
    LOCATE 1, 1
    INPUT "[O]BJ oder [B]AS :", t$
    LOCATE 1, 1
    PRINT STRING$(79, 32)
    n$ = f$
    SELECT CASE UCASE$(t$)
     CASE "O"
      LOCATE 1, 1
      OPEN p$ + LEFT$(f$, 8) + ".VGA" FOR INPUT AS #1
       FOR yt = 50 + ydiff% / 2 TO ymax% - ydiff% / 2 STEP ydiff%
        FOR xt = xdiff% / 2 TO xmax% - xdiff% / 2 STEP xdiff%
         LOCATE 1, 1
         COLOR 15
         PRINT "Spalte :"; (xt - xdiff% / 2) / xdiff% + 1
         LOCATE 1, 30
         PRINT "Zeile  :"; (maxt) - (yt - 50 + ydiff% / 2) / ydiff% + 1
         t = ASC(INPUT$(1, 1) + CHR$(0))
         LINE (xt - xdiff% / 2, yt - ydiff% / 2)-STEP(xdiff%, ydiff%), t, BF
         LINE (xt - xdiff% / 2, yt - ydiff% / 2)-STEP(xdiff%, ydiff%), rand%, B
         PSET (INT(scrx% + 3 + xt / xdiff%), INT(scry% - 2 + yt / ydiff%)), POINT(xt, yt)
        NEXT xt
       NEXT yt
      CLOSE 1
      LOCATE 1, 1
      PRINT STRING$(79, " ")
     CASE "B"
      OPEN p$ + LEFT$(f$, 8) + ".BAS" FOR INPUT AS #1
       xt = xdiff% / 2
       yt = 50 + ydiff% / 2
       DO WHILE NOT EOF(1)
        INPUT #1, p$
        DO WHILE LEFT$(p$, 5) = "DATA "
         p$ = RIGHT$(p$, LEN(p$) - 6)
         p$ = LEFT$(p$, LEN(p$) - 1)
         FOR t = 1 TO LEN(p$) STEP 2
          p = VAL(MID$(p$, t, 2))
          IF p = 99 THEN GOTO aam
          LINE (xt - xdiff% / 2, yt - ydiff% / 2)-STEP(xdiff%, ydiff%), p, BF
          LINE (xt - xdiff% / 2, yt - ydiff% / 2)-STEP(xdiff%, ydiff%), rand%, B
          PSET (INT(scrx% + 3 + xt / xdiff%), INT(scry% - 2 + yt / ydiff%)), POINT(xt, yt)
          xt = xt + xdiff%
         NEXT
aam:
         p$ = ""
         xt = xdiff% / 2
         yt = yt + ydiff%
        LOOP
       LOOP
      CLOSE 1
    END SELECT
aac:
   CASE 115
    p$ = ""
    f$ = ""
    z$ = ""
    COLOR 15
    LOCATE 1, 1
    INPUT "Pfad , wenn n”tig :", p$
    LOCATE 1, 1
    PRINT STRING$(79, 32)
    LOCATE 1, 1
    INPUT "File-Name :", f$
    LOCATE 1, 1
    PRINT STRING$(79, 32)
    LOCATE 1, 1
    INPUT "[O]BJ oder [B]AS :", z$
    LOCATE 1, 1
    PRINT STRING$(79, 32)
    save = 1
    IF p$ <> "" THEN p$ = p$ + "\"
    n$ = f$
    SELECT CASE LCASE$(z$)
     CASE "b"
      FOR t = 0 TO maxt
       t$(t) = ""
      NEXT
      OPEN p$ + LEFT$(f$, 8) + ".BAS" FOR OUTPUT AS #1
       PRINT #1, "SCREEN 12"
       PRINT #1, "x=320"
       PRINT #1, "y=240"
       PRINT #1, "CLS"
       PRINT #1, "RESTORE"
       PRINT #1, "oldx = x"
       PRINT #1, "oldy = y"
       PRINT #1, "DO"
       PRINT #1, " READ t$"
       PRINT #1, " FOR t = 1 TO LEN(t$) STEP 2"
       PRINT #1, "  IF MID$(t$, t, 2) = "; CHR$(34); "99"; CHR$(34); " THEN EXIT DO"
       PRINT #1, "  IF MID$(t$, t, 2) = "; CHR$(34); "hg"; CHR$(34); " THEN GOTO brk"
       PRINT #1, "  PSET (x, y), VAL(MID$(t$, t, 2))"
       PRINT #1, "brk:"
       PRINT #1, "  x = x + 1"
       PRINT #1, " NEXT"
       PRINT #1, " y = y + 1"
       PRINT #1, " x = oldx"
       PRINT #1, "LOOP UNTIL RIGHT$(t$, 2) = "; CHR$(34); "99"; CHR$(34)
       PRINT #1, "SLEEP"
       PRINT #1, "SCREEN 0"
       PRINT #1, "SYSTEM"
       j = 0
       FOR yt = 50 + ydiff% / 2 TO ymax% - ydiff% / 2 STEP ydiff%
        j = j + 1
        FOR xt = xdiff% / 2 TO xmax% - xdiff% / 2 STEP xdiff%
         LOCATE 1, 1
         COLOR 15
         PRINT "Spalte :"; (xt - xdiff% / 2) / xdiff% + 1
         LOCATE 1, 30
         PRINT "Zeile  :"; (maxt) - (yt - 50 + ydiff% / 2) / ydiff% + 1
         t = POINT(xt, yt)
         IF t = 0 THEN t$(j) = t$(j) + "hg": GOTO aad
         t$(j) = t$(j) + RIGHT$("00" + RIGHT$(STR$(t), LEN(STR$(t)) - 1), 2)
aad:
        NEXT xt
       NEXT yt
       LOCATE 1, 1
       PRINT STRING$(79, " ")
       LOCATE 1, 1
       PRINT "Zusammenfassen"
       DO
        FOR t = 1 TO maxt
	 IF LEFT$(t$(t), 2) <> "hg" THEN EXIT loop
        NEXT
        FOR t = 1 TO maxt
         t$(t) = RIGHT$(t$(t), LEN(t$(t)) - 2)
        NEXT
       LOOP
       LOCATE 1, 1
       PRINT STRING$(79, " ")
       LOCATE 1, 1
       PRINT "Ordnen"
       DO
        FOR t = 1 TO maxt
	 IF RIGHT$(t$(t), 2) <> "hg" THEN EXIT loop
        NEXT
        FOR t = 1 TO maxt
         t$(t) = LEFT$(t$(t), LEN(t$(t)) - 2)
        NEXT
       LOOP
       LOCATE 1, 1
       PRINT STRING$(79, " ")
       LOCATE 1, 1
       PRINT "Komprimieren"
       FOR t = 1 TO maxt
        IF INSTR(t$(t), "01") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "02") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "03") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "04") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "05") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "06") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "07") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "08") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "09") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "10") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "11") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "12") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "13") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "14") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "15") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "16") <> 0 THEN EXIT FOR
        t$(t) = ""
       NEXT
       LOCATE 1, 1
       PRINT STRING$(79, " ")
       LOCATE 1, 1
       PRINT "Combilieren"
       FOR t = maxt TO 1 STEP -1
        IF INSTR(t$(t), "01") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "02") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "03") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "04") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "05") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "06") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "07") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "08") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "09") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "10") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "11") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "12") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "13") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "14") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "15") <> 0 THEN EXIT FOR
        IF INSTR(t$(t), "16") <> 0 THEN EXIT FOR
        t$(t) = ""
       NEXT
       LOCATE 1, 1
       PRINT STRING$(79, " ")
       LOCATE 1, 1
       PRINT "Speichern"
       FOR t = 1 TO maxt
        IF t$(t) = "" THEN GOTO aae
        PRINT #1, "DATA "; CHR$(34); t$(t); CHR$(34)
aae:
       NEXT
       PRINT #1, "DATA "; CHR$(34); "99"; CHR$(34)
      CLOSE 1
      LOCATE 1, 1
      PRINT STRING$(79, " ")
     CASE "o"
      OPEN p$ + LEFT$(f$, 8) + ".VGA" FOR OUTPUT AS #1
       j = 0
       FOR yt = 50 + ydiff% / 2 TO ymax% - ydiff% / 2 STEP ydiff%
        j = j + 1
        FOR xt = xdiff% / 2 TO xmax% - xdiff% / 2 STEP xdiff%
         LOCATE 1, 1
         COLOR 15
         PRINT "Spalte :"; (xt - xdiff% / 2) / xdiff% + 1
         LOCATE 1, 30
         PRINT "Zeile  :"; (maxt) - (yt - 50 + ydiff% / 2) / ydiff% + 1
         t = POINT(xt, yt)
         PRINT #1, CHR$(t);
        NEXT xt
       NEXT yt
       PRINT #1, ""
      CLOSE 1
      LOCATE 1, 1
      PRINT STRING$(79, " ")
    END SELECT
   CASE 82
    save = 0
    IF modus = 1 THEN modus = 0: GOTO aai
    modus = 1
aai:
   CASE 27
    IF save = 0 THEN
     LOCATE 1, 1
     COLOR 4
     BEEP
     PRINT "ACHTUNG Datei nicht gespeichert . Fortfahren ";
     INPUT "", z$
     LOCATE 1, 1
     PRINT STRING$(79, " ")
     IF LCASE$(z$) = "n" THEN GOTO aaf
    END IF
    EXIT loop
aaf:
  END SELECT
aag:
  IF col = 1 THEN col = 2: GOTO aah
  col = 1
aah:
 LOOP UNTIL INKEY$ = CHR$(27)
call maus (0)
SCREEN 0
END

MS.Data:
DATA 55,8b,ec,56,57
DATA 8b,76,0c,8b,04       
DATA 8b,76,0a,8b,1c
DATA 8b,76,08,8b,0c
DATA 8b,76,06,8b,14
DATA cd,21               
DATA 8b,76,0c,89,04       
DATA 8b,76,0a,89,1c
DATA 8b,76,08,89,0c
DATA 8b,76,06,89,14
DATA 5f,5e,5d             
DATA ca,08,00             
DATA #

SUB getmaus
 R% = Interr%(&H33, 3, BX%, CX%, DX%)
 mausk% = BX%
 mausx% = CX%
 mausy% = DX%
END SUB

FUNCTION Interr% (Num%, AX%, BX%, CX%, DX%)
 reg 1,ax%
 reg 2,bx%
 reg 3,cx%
 reg 4,dx%
 call interrupt Num%
 ax%=reg(1)
 bx%=reg(2)
 cx%=reg(3)
 dx%=reg(4)
 Interr% = AX%
END FUNCTION

SUB maus (OnOff%)
 IF OnOff% = 0 THEN OnOff% = 2 ELSE OnOff% = 1
 R% = Interr%(&H33, OnOff%, BX%, CX%, DX%)
END SUB

SUB MausInit
 R% = Interr%(&H33, 0, BX%, CX%, DX%)
 R% = Interr%(&H33, 10, 0, &HFFFF, &HFF00)
END SUB

SUB mausset (x%, y%)
 R% = Interr%(&H33, 4, BX%, x%, y%)
END SUB

SUB MausTempo (Speed%)
 R% = Interr%(&H33, 15, BX%, Speed%, Speed% * 2)
END SUB

SUB MausXBereich (X1%, X2%)
 R% = Interr%(&H33, 7, 0, X1%, X2%)
END SUB

SUB MausYBereich (Y1%, Y2%)
 R% = Interr%(&H33, 8, BX%, Y1%, Y2%)
END SUB

SUB wartebewegung
 call getmaus
 x% = mausx%: y% = mausy%: k% = mausk%
 DO
  call getmaus
 LOOP UNTIL x% <> mausx% OR y% <> mausy% OR k% <> mausk%
END SUB

SUB warteknopflos
 WHILE mausk%
  call getmaus
 WEND
END SUB

