' Comprehensive File Format Round-Trip Test
' Creates known pattern, saves, loads, and verifies integrity

SUB InitLog
  DIM logFile AS INTEGER: logFile = FREEFILE
  OPEN "UNITTEST.LOG" FOR OUTPUT AS #logFile
    PRINT #logFile, "=== Comprehensive File Format Round-Trip Test ==="
  CLOSE #logFile
END SUB

SUB WriteLog(BYVAL message AS STRING)
  DIM logFile AS INTEGER: logFile = FREEFILE
  OPEN "UNITTEST.LOG" FOR APPEND AS #logFile
    PRINT #logFile, message
  CLOSE #logFile
END SUB

CALL InitLog

%TRUE = -1
%FALSE = 0

TYPE Sprite
    spriteWidth AS INTEGER
    spriteHeight AS INTEGER
    boundingBoxX1 AS INTEGER
    boundingBoxY1 AS INTEGER
    boundingBoxX2 AS INTEGER
    boundingBoxY2 AS INTEGER
END TYPE

' Initialize sprite dimensions and grid constants
%GRID_X_MAX = 534
%GRID_Y_MAX = 464
%GRID_X_STEP = 6
%GRID_Y_STEP = 6
%GRID_START_Y = 50

' Global shared variables
DIM originalSprite AS SHARED Sprite
originalSprite.spriteWidth = (%GRID_X_MAX / %GRID_X_STEP)
originalSprite.spriteHeight = (%GRID_Y_MAX - %GRID_START_Y) / %GRID_Y_STEP
DIM originalCanvas(0 TO originalSprite.spriteWidth, 0 TO originalSprite.spriteHeight) AS SHARED BYTE

DIM currentSprite AS SHARED Sprite
DIM currentCanvas(0 TO originalSprite.spriteWidth, 0 TO originalSprite.spriteHeight) AS SHARED BYTE

CALL WriteLog("Sprite dimensions: " + STR$(currentSprite.spriteWidth) + "x" + STR$(currentSprite.spriteHeight))

SUB CopyOriginalCanvas()
  DIM y AS INTEGER, minY AS INTEGER, maxY AS INTEGER, minX AS INTEGER, maxX AS INTEGER
  minY = LBOUND(originalCanvas, 2)
  maxY = UBOUND(originalCanvas, 2)
  minX = LBOUND(originalCanvas, 1)
  maxX = UBOUND(originalCanvas, 1)
  FOR y = minY TO maxY
    DIM x AS INTEGER
    FOR x = minX TO maxX
	    currentCanvas(x, y) = originalCanvas(x, y)
    NEXT
  NEXT
  currentSprite.boundingBoxX1 = originalSprite.boundingBoxX1
  currentSprite.boundingBoxY1 = originalSprite.boundingBoxY1
  currentSprite.boundingBoxX2 = originalSprite.boundingBoxX2
  currentSprite.boundingBoxY2 = originalSprite.boundingBoxY2
END SUB

SUB ClearCurrentCanvas()
  DIM y AS INTEGER, minY AS INTEGER, maxY AS INTEGER, minX AS INTEGER, maxX AS INTEGER
  minY = LBOUND(currentCanvas, 2)
  maxY = UBOUND(currentCanvas, 2)
  minX = LBOUND(currentCanvas, 1)
  maxX = UBOUND(currentCanvas, 1)

  FOR y = minY TO maxY
    DIM x AS INTEGER
    FOR x = minX TO maxX
      currentCanvas(x, y) = 0
    NEXT
  NEXT
END SUB

SUB ClearOriginalCanvas()
  DIM y AS INTEGER, minY AS INTEGER, maxY AS INTEGER, minX AS INTEGER, maxX AS INTEGER
  minY = LBOUND(originalCanvas, 2)
  maxY = UBOUND(originalCanvas, 2)
  minX = LBOUND(originalCanvas, 1)
  maxX = UBOUND(originalCanvas, 1)
  
  FOR y = minY TO maxY 
    DIM x AS INTEGER
    FOR x = minX TO maxX
      originalCanvas(x, y) = 0
    NEXT
  NEXT
END SUB

' Minimal stub function
SUB UpdateSpriteBoundingBoxShared()
END SUB


SUB CreateTestPattern()
  CALL ClearOriginalCanvas()
  DIM x AS INTEGER, y AS INTEGER
     
  ' Create recognizable test pattern
  ' 11x11 box with different colors and patterns
  
  ' Outer border (white - color 15)
  FOR x = 10 TO 20
    originalCanvas(x, 10) = 15  ' Top
    originalCanvas(x, 20) = 15  ' Bottom
  NEXT x
  FOR y = 10 TO 20
    originalCanvas(10, y) = 15  ' Left
    originalCanvas(20, y) = 15  ' Right
  NEXT y
  
  ' Diagonal line  
  DIM i AS INTEGER
  FOR i = 13 TO 17
    originalCanvas(i, i) = 8  ' Dark gray diagonal
  NEXT i

  ' Inner pattern with specific colors for verification
  originalCanvas(12, 12) = 1   ' Blue
  originalCanvas(18, 12) = 2   ' Green
  originalCanvas(15, 12) = 3   ' Cyan
  originalCanvas(12, 18) = 4   ' Red
  originalCanvas(15, 18) = 5   ' Pink
  originalCanvas(18, 18) = 14  ' Yellow
  originalCanvas(15, 15) = 15  ' White center

  originalSprite.boundingBoxX1 = 10
  originalSprite.boundingBoxY1 = 10
  originalSprite.boundingBoxX2 = 20
  originalSprite.boundingBoxY2 = 20

  CALL WriteLog("Test pattern created: 11x11 box with border, corners, center, and diagonal")
END SUB

FUNCTION CompareCanvases() AS INTEGER

  'Note: while the originalCanvas has the test image somewhere inside of it, the currentCanvas is always loaded at 0,0
  
  DIM differences AS INTEGER
  DIM totalPixels AS INTEGER
  
  differences = 0
  totalPixels = (currentSprite.boundingBoxX2 - currentSprite.boundingBoxX1 + 1) * (currentSprite.boundingBoxY2 - currentSprite.boundingBoxY1 + 1)
  
  DIM ox AS INTEGER, oy AS INTEGER
  DIM cx AS INTEGER, cy AS INTEGER
  FOR cy = currentSprite.boundingBoxY1 TO currentSprite.boundingBoxY2
    oy = cy - currentSprite.boundingBoxY1 + originalSprite.boundingBoxY1
    FOR cx = currentSprite.boundingBoxX1 TO currentSprite.boundingBoxX2
      ox = cx - currentSprite.boundingBoxX1 + originalSprite.boundingBoxX1
      IF originalCanvas(ox, oy) <> currentCanvas(cx, cy) THEN
        differences = differences + 1
        ' Log first few critical differences
        IF differences <= 5 THEN CALL WriteLog("  Diff at (" + STR$(cx) + "," + STR$(cy) + "): expected " + STR$(originalCanvas(ox, oy)) + ", got " + STR$(currentCanvas(cx, cy)))
      END IF
    NEXT
  NEXT
  
  IF differences = 0 THEN
    CompareCanvases = %TRUE
    CALL WriteLog("  Canvas comparison: PERFECT MATCH (" + STR$(totalPixels) + " pixels)")
  ELSE
    CompareCanvases = %FALSE
    CALL WriteLog("  Canvas comparison: " + STR$(differences) + " differences out of " + STR$(totalPixels) + " pixels")
  END IF
END FUNCTION

FUNCTION WriteFormat(BYVAL formatName AS STRING, BYVAL fileName AS STRING) AS STRING
  DIM errorMessage AS STRING
  CALL WriteLog("  Writing " + fileName + "...")
  CALL WriteLog("    BB before format write: (" + STR$(currentSprite.boundingBoxX1) + "," + STR$(currentSprite.boundingBoxY1) + ") to (" + STR$(currentSprite.boundingBoxX2) + "," + STR$(currentSprite.boundingBoxY2) + ")")
  IF formatName = "VGA" THEN
    CALL FileVga_Write(fileName, errorMessage)
  ELSEIF formatName = "PCX" THEN
    CALL FilePcx_Write(fileName, errorMessage)
  ELSEIF formatName = "BMP" THEN
    CALL FileBmp_Write(fileName, errorMessage)
  ELSEIF formatName = "ICO" THEN
    CALL FileIco_Write(fileName, errorMessage)
  ELSEIF formatName = "TGA" THEN
    CALL FileTga_Write(fileName, errorMessage)
  ELSEIF formatName = "GIF" THEN
    CALL FileGif_Write(fileName, errorMessage)
  ELSEIF formatName = "TIF" THEN
    CALL FileTif_Write(fileName, errorMessage)
  ELSEIF formatName = "XPM" THEN
    CALL FileXpm_Write(fileName, errorMessage)
  END IF
  WriteFormat = errorMessage
END FUNCTION

FUNCTION ReadFormat(BYVAL formatName AS STRING, BYVAL fileName AS STRING) AS STRING
  DIM errorMessage AS STRING
  CALL WriteLog("  Reading " + fileName + "...")
    IF formatName = "VGA" THEN
    CALL FileVga_Read(fileName, errorMessage)
  ELSEIF formatName = "PCX" THEN
    CALL FilePcx_Read(fileName, errorMessage)
  ELSEIF formatName = "BMP" THEN
    CALL FileBmp_Read(fileName, errorMessage)
  ELSEIF formatName = "ICO" THEN
    CALL FileIco_Read(fileName, errorMessage)
  ELSEIF formatName = "TGA" THEN
    CALL FileTga_Read(fileName, errorMessage)
  ELSEIF formatName = "GIF" THEN
    CALL FileGif_Read(fileName, errorMessage)
  ELSEIF formatName = "TIF" THEN
    CALL FileTif_Read(fileName, errorMessage)
  ELSEIF formatName = "XPM" THEN
    CALL FileXpm_Read(fileName, errorMessage)
  END IF
  ReadFormat = errorMessage
END FUNCTION

' Test individual format
SUB TestFormat(BYVAL formatName AS STRING, BYVAL fileName AS STRING)
  CALL WriteLog("")
  CALL WriteLog("=== Testing " + formatName + " Format ===")
  CALL WriteLog("  Result in " + fileName)
  
  CALL CopyOriginalCanvas()
  
  ' Log the bounding box before writing
  CALL WriteLog("  Bounding box before write: (" + STR$(currentSprite.boundingBoxX1) + "," + STR$(currentSprite.boundingBoxY1) + ") to (" + STR$(currentSprite.boundingBoxX2) + "," + STR$(currentSprite.boundingBoxY2) + ")")
  
  DIM errorMessage AS STRING
  DIM compareResult AS INTEGER
    
  ' Write test
  errorMessage = WriteFormat(formatName, fileName)
  IF errorMessage <> "" THEN
    CALL WriteLog("  WRITE FAILED: " + errorMessage)
    CALL WriteLog("  " + formatName + ": FAILED (Write Error)")
    EXIT SUB
  ELSE
    CALL WriteLog("  Write successful")
  END IF
  
  ' Verify file was created
  IF DIR$(fileName) = "" THEN
    CALL WriteLog("  ERROR: File not created")
    CALL WriteLog("  " + formatName + ": FAILED (No File)")
    EXIT SUB
  END IF
  
  ' Clear canvas and read test
  CALL ClearCurrentCanvas
  
  errorMessage = ReadFormat(formatName, fileName)
    
  IF errorMessage <> "" THEN
    CALL WriteLog("  READ FAILED: " + errorMessage)
    CALL WriteLog("  " + formatName + ": FAILED (Read Error)")
    EXIT SUB
  ELSE
    CALL WriteLog("  Read successful")
  END IF
    
  ' Log the bounding box after reading
  CALL WriteLog("  Bounding box after read: (" + STR$(currentSprite.boundingBoxX1) + "," + STR$(currentSprite.boundingBoxY1) + ") to (" + STR$(currentSprite.boundingBoxX2) + "," + STR$(currentSprite.boundingBoxY2) + ")")
  
  CALL UpdateSpriteBoundingBoxShared
  
  ' Compare data integrity
  compareResult = CompareCanvases()
  IF compareResult = %FALSE THEN
    CALL WriteLog("  " + formatName + ": FAILED - Data corruption detected")
  ELSE
    CALL WriteLog("  " + formatName + ": SUCCESS - Perfect round-trip")
  END IF
  
END SUB

' Include all format handlers
$INCLUDE "FILE_VGA.SUB"
$INCLUDE "FILE_PCX.SUB"
$INCLUDE "FILE_BMP.SUB"
$INCLUDE "FILE_ICO.SUB"
$INCLUDE "FILE_TGA.SUB"
$INCLUDE "FILE_GIF.SUB"
$INCLUDE "FILE_TIF.SUB"
$INCLUDE "FILE_XPM.SUB"

' Main test execution
'ON ERROR GOTO ErrorHandler

CALL WriteLog("Initializing test pattern...")
CALL ClearOriginalCanvas()
CALL CreateTestPattern()

' Test all supported formats
CALL TestFormat("VGA", "RTTEST.VGA")
CALL TestFormat("PCX", "RTTEST.PCX")
CALL TestFormat("BMP", "RTTEST.BMP")
CALL TestFormat("ICO", "RTTEST.ICO")
CALL TestFormat("TGA", "RTTEST.TGA")
CALL TestFormat("GIF", "RTTEST.GIF")
CALL TestFormat("TIF", "RTTEST.TIF")
CALL TestFormat("XPM", "RTTEST.XPM")

CALL WriteLog("")
CALL WriteLog("=== ROUND-TRIP TEST SUMMARY ===")
CALL WriteLog("Test completed for all formats")
CALL WriteLog("Check individual format results above")
CALL WriteLog("Files created: RTTEST.VGA, RTTEST.PCX, RTTEST.BMP, RTTEST.ICO, RTTEST.TGA, RTTEST.GIF, RTTEST.TIF, RTTEST.XMP")
CALL WriteLog("=====================================")
END

ErrorHandler:
CALL WriteLog("CRITICAL ERROR: " + STR$(ERR))
END