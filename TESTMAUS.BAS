' TESTMAUS.BAS - Automated Test Application

$INCLUDE "SPRITE_OPS.SUB"
$INCLUDE "FILE_VGA.SUB"
$INCLUDE "FILE_BAS.SUB"
$INCLUDE "FILE_BMP.SUB"
$INCLUDE "FILE_PCX.SUB"
$INCLUDE "FILE_ICO.SUB"
$INCLUDE "FILE_XPM.SUB"

' --- Constants ---
CONST TEST_WIDTH = 32
CONST TEST_HEIGHT = 32

' --- Main Test Routine ---
DIM mainSprite AS Sprite
DIM originalCanvas(0 TO TEST_WIDTH, 0 TO TEST_HEIGHT) AS INTEGER
DIM loadedCanvas(0 TO TEST_WIDTH, 0 TO TEST_HEIGHT) AS INTEGER
DIM testResult AS INTEGER

SCREEN 0
CLS
PRINT "Starting file format tests..."

' --- Initialize Sprites and Canvases ---
mainSprite.width = TEST_WIDTH
mainSprite.height = TEST_HEIGHT
REDIM originalCanvas(0 TO mainSprite.width, 0 TO mainSprite.height) AS INTEGER
REDIM loadedCanvas(0 TO mainSprite.width, 0 TO mainSprite.height) AS INTEGER

' --- Create Test Pattern ---
CreateTestPattern mainSprite, originalCanvas()
UpdateSpriteBoundingBox mainSprite, originalCanvas()

' --- Test Each File Format ---
TestFileFormat "VGA", mainSprite, originalCanvas(), loadedCanvas()
TestFileFormat "BAS", mainSprite, originalCanvas(), loadedCanvas()
TestFileFormat "PCX", mainSprite, originalCanvas(), loadedCanvas()
TestFileFormat "BMP", mainSprite, originalCanvas(), loadedCanvas()
TestFileFormat "ICO", mainSprite, originalCanvas(), loadedCanvas()
TestFileFormat "XPM", mainSprite, originalCanvas(), loadedCanvas()

PRINT "
All tests complete."
END

'******************************************************************************
'* SUB: CreateTestPattern
'* Purpose: Creates a predictable pattern on the canvas for testing.
'******************************************************************************
SUB CreateTestPattern (spr AS Sprite, canvas() AS INTEGER)
    DIM x AS INTEGER, y AS INTEGER
    FOR y = 0 TO spr.height
        FOR x = 0 TO spr.width
            canvas(x, y) = (x + y) MOD 16
        NEXT x
    NEXT y
END SUB

'******************************************************************************
'* SUB: TestFileFormat
'* Purpose: Saves and loads a single file format, then compares the result.
'******************************************************************************
SUB TestFileFormat (BYVAL formatName AS STRING, spr AS Sprite, original() AS INTEGER, loaded() AS INTEGER)
    DIM fileName AS STRING
    DIM errorMessage AS STRING
    fileName = "TEST." + formatName

    PRINT "Testing " + formatName + " format...";

    ' --- Save the file ---
    SELECT CASE UCASE$(formatName)
        CASE "VGA": WriteVGAFile fileName, spr, original(), errorMessage
        CASE "BAS": WriteBASFile fileName, spr, original(), errorMessage
        CASE "PCX": WritePCXFile fileName, spr, original(), errorMessage
        CASE "BMP": WriteBMPFile fileName, spr, original(), errorMessage
        CASE "ICO": WriteICOFile fileName, spr, original(), errorMessage
        CASE "XPM": WriteXPMFile fileName, spr, original(), errorMessage
    END SELECT

    IF errorMessage <> "" THEN
        PRINT "  [SAVE FAIL] " + errorMessage
        KILL fileName
        EXIT SUB
    END IF

    ' --- Clear the loaded canvas ---
    ClearCanvas spr, loaded()

    ' --- Load the file back ---
    SELECT CASE UCASE$(formatName)
        CASE "VGA": ReadVGAFile fileName, spr, loaded(), errorMessage
        CASE "BAS": ReadBASFile fileName, spr, loaded(), errorMessage
        CASE "PCX": ReadPCXFile fileName, spr, loaded(), errorMessage
        CASE "BMP": ReadBMPFile fileName, spr, loaded(), errorMessage
        CASE "ICO": ReadICOFile fileName, spr, loaded(), errorMessage
        CASE "XPM": ReadXPMFile fileName, spr, loaded(), errorMessage
    END SELECT

    IF errorMessage <> "" THEN
        PRINT "  [LOAD FAIL] " + errorMessage
        KILL fileName
        EXIT SUB
    END IF

    ' --- Compare the canvases ---
    IF CompareCanvases(spr, original(), loaded()) THEN
        PRINT "  [PASS]"
    ELSE
        PRINT "  [COMPARE FAIL]"
    END IF

    KILL fileName
END SUB

'******************************************************************************
'* FUNCTION: CompareCanvases
'* Purpose: Compares two canvases to see if they are identical.
'******************************************************************************
FUNCTION CompareCanvases (spr AS Sprite, canvas1() AS INTEGER, canvas2() AS INTEGER) AS INTEGER
    DIM x AS INTEGER, y AS INTEGER
    CompareCanvases = 1 ' TRUE
    FOR y = 0 TO spr.height
        FOR x = 0 TO spr.width
            IF canvas1(x, y) <> canvas2(x, y) THEN
                CompareCanvases = 0 ' FALSE
                EXIT FUNCTION
            END IF
        NEXT x
    NEXT y
END FUNCTION
