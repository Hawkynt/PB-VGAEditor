' VGAMAUS.BAS - Final, Complete, and Corrected Refactoring
' Implements state/rendering separation, full documentation, and strict coding standards.
' Codepage 850

' --- Type Definitions ---
TYPE MouseInfo
    x AS INTEGER
    y AS INTEGER
    button AS INTEGER
END TYPE

' --- Constants ---
CONST TRUE = -1
CONST FALSE = 0

' Key Codes
CONST KEY_ESC = 27
CONST KEY_INSERT = 82
CONST KEY_C = 99
CONST KEY_L = 108
CONST KEY_N = 110
CONST KEY_S = 115

' Grid & Drawing
CONST GRID_X_MAX = 534
CONST GRID_Y_MAX = 464
CONST GRID_X_STEP = 6
CONST GRID_Y_STEP = 6
CONST GRID_COLOR = 8
CONST DEFAULT_DRAW_COLOR = 15
CONST GRID_START_Y = 50

' Canvas Dimensions (derived from grid)
CONST CANVAS_WIDTH = GRID_X_MAX / GRID_X_STEP
CONST CANVAS_HEIGHT = (GRID_Y_MAX - GRID_START_Y) / GRID_Y_STEP

' Preview Window
CONST PREVIEW_X = GRID_X_MAX + 10
CONST PREVIEW_Y = 150

DIM mouse AS MouseInfo
InitializeSystem mouse
ShowIntro
MainEditorLoop mouse

'******************************************************************************
'* SUB: MainEditorLoop
'* Purpose: The main event loop for the sprite editor.
'* Parameters: None
'******************************************************************************
SUB MainEditorLoop(BYREF mouse AS MouseInfo)
    DIM spriteCanvas(0 TO CANVAS_WIDTH, 0 TO CANVAS_HEIGHT) AS INTEGER
    DIM cursorBoxColorToggle AS INTEGER, cursorBoxColor AS INTEGER
    DIM drawingColor AS INTEGER
    DIM currentX AS INTEGER, currentY AS INTEGER
    DIM prevX AS INTEGER, prevY AS INTEGER
    DIM isSaved AS INTEGER, isLineMode AS INTEGER
    DIM currentFileName$ AS STRING

    isSaved = TRUE
    isLineMode = FALSE
    currentFileName$ = "UNBENANNT"
    drawingColor = DEFAULT_DRAW_COLOR
    currentX = 0
    currentY = GRID_START_Y
    cursorBoxColorToggle = 1
    
    CLS
    DrawGrid
    ClearCanvas spriteCanvas()

    DO
        IF cursorBoxColorToggle = 1 THEN cursorBoxColor = 4 ELSE cursorBoxColor = 14
        GetMouseState mouse
        prevX = currentX
        prevY = currentY
        currentX = INT(mouse.x / GRID_X_STEP) * GRID_X_STEP
        currentY = INT(mouse.y / GRID_Y_STEP) * GRID_Y_STEP + 2

        LINE (prevX, prevY)-STEP(GRID_X_STEP, GRID_Y_STEP), GRID_COLOR, B

        IF currentX > GRID_X_MAX - GRID_X_STEP THEN currentX = GRID_X_MAX - GRID_X_STEP
        IF currentX < 0 THEN currentX = 0
        IF currentY < GRID_START_Y THEN currentY = GRID_START_Y
        IF currentY > GRID_Y_MAX - GRID_Y_STEP THEN currentY = GRID_Y_MAX - GRID_Y_STEP

        HandleMouseInput mouse, spriteCanvas(), drawingColor, isLineMode, isSaved
        LINE (currentX, currentY)-STEP(GRID_X_STEP, GRID_Y_STEP), cursorBoxColor, B
        DrawUI drawingColor, currentFileName$
        HandleKeyboardInput drawingColor, isLineMode, isSaved, currentFileName$, spriteCanvas()

        IF cursorBoxColorToggle = 1 THEN cursorBoxColorToggle = 2 ELSE cursorBoxColorToggle = 1
    LOOP
END SUB

'******************************************************************************
'* SUB: InitializeSystem
'* Purpose: Initializes screen mode and mouse driver.
'* Parameters:
'*   mouse (BYREF MouseInfo): The mouse state variable to initialize.
'******************************************************************************
SUB InitializeSystem (BYREF mouse AS MouseInfo)
    InitializeMouse
    SCREEN 12
    mouse.x = 320
    mouse.y = 240
    SetMousePosition mouse.x, mouse.y
END SUB

'******************************************************************************
'* SUB: ShowIntro
'* Purpose: Displays the initial ASCII art intro screen.
'* Parameters: None
'******************************************************************************
SUB ShowIntro ()
    DIM t AS LONG
    LOCATE 12, 35: COLOR 1: PRINT ">>SynthelicZ<< presents"
    FOR t = 1 TO 4000: NEXT
    CLS
    LOCATE 12, 35: COLOR 2: PRINT "a Hawkynt production"
    FOR t = 1 TO 4000: NEXT
    CLS
    PRINT: PRINT: PRINT
    COLOR 2: PRINT SPC(14); "²²²²²² ²²  ²² ²²²²²²²         "; : COLOR 1: PRINT "²²  ²²   ±±±±    °°  "
    COLOR 2: PRINT SPC(14); "² ²² ² ²²  ²²  ²²   ²         "; : COLOR 1: PRINT "²²  ²²  ±±  ±±  °°°° "
    COLOR 2: PRINT SPC(14); "  ²²   ²²  ²²  ²² ²           "; : COLOR 1: PRINT "²²  ²² ±±      °°  °°"
    COLOR 2: PRINT SPC(14); "  ²²   ²²²²²²  ²²²²           "; : COLOR 1: PRINT "²²  ²² ±±      °°  °°"
    COLOR 2: PRINT SPC(14); "  ²²   ²²  ²²  ²² ²           "; : COLOR 1: PRINT "²²  ²² ±±  ±±± °°°°°°"
    COLOR 2: PRINT SPC(14); "  ²²   ²²  ²²  ²²   ²         "; : COLOR 1: PRINT " ²²²²  ±±   ±± °°  °°"
    COLOR 2: PRINT SPC(14); " ²²²²  ²²  ²² ²²²²²²²         "; : COLOR 1: PRINT "  ²²    ±±±±±± °°  °°"
    FOR t = 1 TO 5
     PRINT
    NEXT
    COLOR 4
    PRINT , "     ÛÛÛÛÛÛÛ ÛÛÛÛÛ   ÛÛÛÛÛÛ ÛÛÛÛÛÛ   ÛÛÛ   ÛÛÛÛÛÛ "
    PRINT , "      ÛÛ   Û  ÛÛ ÛÛ    ÛÛ   Û ÛÛ Û  ÛÛ ÛÛ   ÛÛ  ÛÛ"
    PRINT , "      ÛÛ Û    ÛÛ  ÛÛ   ÛÛ     ÛÛ   ÛÛ   ÛÛ  ÛÛ  ÛÛ"
    PRINT , "      ÛÛÛÛ    ÛÛ  ÛÛ   ÛÛ     ÛÛ   ÛÛ   ÛÛ  ÛÛÛÛÛ "
    PRINT , "      ÛÛ Û    ÛÛ  ÛÛ   ÛÛ     ÛÛ   ÛÛ   ÛÛ  ÛÛ ÛÛ "
    PRINT , "      ÛÛ   Û  ÛÛ ÛÛ    ÛÛ     ÛÛ    ÛÛ ÛÛ   ÛÛ  ÛÛ"
    PRINT , "     ÛÛÛÛÛÛÛ ÛÛÛÛÛ   ÛÛÛÛÛÛ  ÛÛÛÛ    ÛÛÛ   ÛÛÛ   Û"
    WaitForInput
END SUB

'******************************************************************************
'* SUB: ClearCanvas
'* Purpose: Fills the sprite data array with 0 (transparent).
'* Parameters:
'*   canvas() (BYREF INTEGER): The sprite data array to clear.
'******************************************************************************
SUB ClearCanvas (BYREF canvas() AS INTEGER)
    DIM x AS INTEGER, y AS INTEGER
    FOR y = 0 TO CANVAS_HEIGHT
        FOR x = 0 TO CANVAS_WIDTH
            canvas(x, y) = 0
        NEXT x
    NEXT y
END SUB

'******************************************************************************
'* SUB: RenderCanvas
'* Purpose: Draws the entire contents of the canvas array to the screen.
'* Parameters:
'*   canvas() (BYREF INTEGER): The sprite data array to render.
'******************************************************************************
SUB RenderCanvas (BYREF canvas() AS INTEGER)
    DIM x AS INTEGER, y AS INTEGER, screenX AS INTEGER, screenY AS INTEGER
    CLS
    DrawGrid
    FOR y = 0 TO CANVAS_HEIGHT
        FOR x = 0 TO CANVAS_WIDTH
            IF canvas(x, y) <> 0 THEN
                CanvasToScreen x, y, screenX, screenY
                LINE (screenX, screenY)-STEP(GRID_X_STEP, GRID_Y_STEP), canvas(x, y), BF
                PSET (x + PREVIEW_X + 3, y + PREVIEW_Y), canvas(x, y)
            END IF
        NEXT x
    NEXT y
END SUB

'******************************************************************************
'* SUB: CanvasToScreen
'* Purpose: Converts canvas array coordinates to screen pixel coordinates.
'* Parameters:
'*   canvasX (BYVAL INTEGER): The X index of the canvas array.
'*   canvasY (BYVAL INTEGER): The Y index of the canvas array.
'*   screenX (BYREF INTEGER): The resulting X pixel coordinate on screen.
'*   screenY (BYREF INTEGER): The resulting Y pixel coordinate on screen.
'******************************************************************************
SUB CanvasToScreen (BYVAL canvasX AS INTEGER, BYVAL canvasY AS INTEGER, BYREF screenX AS INTEGER, BYREF screenY AS INTEGER)
    screenX = canvasX * GRID_X_STEP
    screenY = (canvasY * GRID_Y_STEP) + GRID_START_Y
END SUB

'******************************************************************************
'* SUB: DrawGrid
'* Purpose: Draws the editor grid on the screen.
'* Parameters: None
'******************************************************************************
SUB DrawGrid ()
    DIM x AS INTEGER, y AS INTEGER
    FOR x = 0 TO GRID_X_MAX STEP GRID_X_STEP
        LINE (x, GRID_START_Y)-(x, GRID_Y_MAX), GRID_COLOR
    NEXT x
    FOR y = GRID_START_Y TO GRID_Y_MAX STEP GRID_Y_STEP
        LINE (0, y)-(GRID_X_MAX, y), GRID_COLOR
    NEXT y
END SUB

'******************************************************************************
'* SUB: DrawUI
'* Purpose: Draws the user interface elements like text and color preview.
'* Parameters:
'*   drawingColor (BYVAL INTEGER): The currently selected drawing color.
'*   currentFileName (BYVAL STRING): The name of the current file.
'******************************************************************************
SUB DrawUI (BYVAL drawingColor AS INTEGER, BYVAL currentFileName AS STRING)
    LOCATE 1, 70: PRINT currentFileName$
    LOCATE 2, 1: COLOR 5
    PRINT "ESC=Exit  N=New  L=Load  S=Save  INS=Line-Mode"
    LOCATE 3, 6: COLOR drawingColor: PRINT "Color"
    LINE (15, 33)-STEP(GRID_X_STEP, GRID_Y_STEP), drawingColor, BF
    LOCATE 3, 14: COLOR 1: PRINT "C=Color"
    LOCATE 3, 28: COLOR 2: PRINT "L-Mouse=Draw"
    LOCATE 3, 45: COLOR 4: PRINT "R-Mouse=Erase"
    LINE (PREVIEW_X, PREVIEW_Y)-STEP(CANVAS_WIDTH + 5, CANVAS_HEIGHT + 9), 1, B
END SUB

'******************************************************************************
'* SUB: HandleMouseInput
'* Purpose: Processes mouse clicks to modify the sprite canvas.
'* Parameters:
'*   mouse (BYREF MouseInfo): The current state of the mouse.
'*   canvas() (BYREF INTEGER): The sprite data array.
'*   drawingColor (BYVAL INTEGER): The current color to draw with.
'*   isLineMode (BYVAL INTEGER): Flag for line drawing mode.
'*   isSaved (BYREF INTEGER): Flag indicating if the file has unsaved changes.
'******************************************************************************
SUB HandleMouseInput (BYREF mouse AS MouseInfo, BYREF canvas() AS INTEGER, BYVAL drawingColor AS INTEGER, BYVAL isLineMode AS INTEGER, BYREF isSaved AS INTEGER)
    DIM canvasX AS INTEGER, canvasY AS INTEGER, screenX AS INTEGER, screenY AS INTEGER, colorToUse AS INTEGER

    canvasX = mouse.x / GRID_X_STEP
    canvasY = (mouse.y - GRID_START_Y) / GRID_Y_STEP

    IF canvasX < 0 OR canvasX > CANVAS_WIDTH OR canvasY < 0 OR canvasY > CANVAS_HEIGHT THEN EXIT SUB

    colorToUse = -1
    IF mouse.button = 1 THEN colorToUse = drawingColor
    IF mouse.button = 2 THEN colorToUse = 0
    IF isLineMode THEN colorToUse = drawingColor

    IF colorToUse <> -1 AND canvas(canvasX, canvasY) <> colorToUse THEN
        canvas(canvasX, canvasY) = colorToUse
        isSaved = FALSE
        CanvasToScreen canvasX, canvasY, screenX, screenY
        LINE (screenX, screenY)-STEP(GRID_X_STEP, GRID_Y_STEP), colorToUse, BF
        PSET (canvasX + PREVIEW_X + 3, canvasY + PREVIEW_Y), colorToUse
    END IF
END SUB

'******************************************************************************
'* SUB: HandleKeyboardInput
'* Purpose: Processes keyboard presses for editor commands.
'* Parameters:
'*   drawingColor (BYREF INTEGER): The current drawing color.
'*   isLineMode (BYREF INTEGER): Flag for line drawing mode.
'*   isSaved (BYREF INTEGER): Flag for unsaved changes.
'*   currentFileName (BYREF STRING): The current name of the file.
'*   canvas() (BYREF INTEGER): The sprite data array.
'******************************************************************************
SUB HandleKeyboardInput (BYREF drawingColor AS INTEGER, BYREF isLineMode AS INTEGER, BYREF isSaved AS INTEGER, BYREF currentFileName AS STRING, BYREF canvas() AS INTEGER)
    DIM inputKey$ AS STRING, keyCode AS INTEGER
    inputKey$ = INKEY$
    IF inputKey$ = "" THEN EXIT SUB
    keyCode = ASC(inputKey$)
    IF LEN(inputKey$) > 1 THEN keyCode = ASC(RIGHT$(inputKey$, 1))

    SELECT CASE keyCode
        CASE KEY_N: HandleNewFile isSaved, isLineMode, currentFileName, canvas()
        CASE KEY_C: HandleChangeColor drawingColor
        CASE KEY_L: HandleLoadFile isSaved, currentFileName, canvas()
        CASE KEY_S: HandleSaveFile currentFileName, isSaved, canvas()
        CASE KEY_INSERT: isLineMode = NOT isLineMode
        CASE KEY_ESC: HandleExit isSaved
    END SELECT
END SUB

'******************************************************************************
'* FUNCTION: CheckUnsavedChanges
'* Purpose: Asks user to confirm if they want to discard unsaved changes.
'* Parameters:
'*   isSaved (BYVAL INTEGER): Flag indicating if there are unsaved changes.
'* Returns: (INTEGER) TRUE if okay to proceed, FALSE to cancel.
'******************************************************************************
FUNCTION CheckUnsavedChanges (BYVAL isSaved AS INTEGER) AS INTEGER
    DIM confirm$ AS STRING
    CheckUnsavedChanges = TRUE
    IF isSaved = FALSE THEN
        LOCATE 1, 1: COLOR 4: BEEP
        PRINT "WARNING: File not saved. Continue? (y/n) ";
        INPUT "", confirm$
        LOCATE 1, 1: PRINT STRING$(79, " ")
        IF LCASE$(confirm$) <> "y" THEN CheckUnsavedChanges = FALSE
    END IF
END FUNCTION

'******************************************************************************
'* SUB: HandleNewFile
'* Purpose: Clears the canvas for a new file after checking for unsaved changes.
'* Parameters:
'*   isSaved (BYREF INTEGER): Unsaved changes flag.
'*   isLineMode (BYREF INTEGER): Line mode flag.
'*   currentFileName (BYREF STRING): The current file name.
'*   canvas() (BYREF INTEGER): The sprite data array.
'******************************************************************************
SUB HandleNewFile (BYREF isSaved AS INTEGER, BYREF isLineMode AS INTEGER, BYREF currentFileName AS STRING, BYREF canvas() AS INTEGER)
    IF CheckUnsavedChanges(isSaved) = FALSE THEN EXIT SUB
    isSaved = TRUE
    isLineMode = FALSE
    currentFileName = "UNBENANNT"
    ClearCanvas canvas()
    RenderCanvas canvas()
END SUB

'******************************************************************************
'* SUB: HandleChangeColor
'* Purpose: Prompts the user to select a new drawing color.
'* Parameters:
'*   color (BYREF INTEGER): The current drawing color variable to update.
'******************************************************************************
SUB HandleChangeColor (BYREF color AS INTEGER)
    DIM newColorStr$ AS STRING, newColorVal AS INTEGER
    COLOR 15: LOCATE 1, 1
    INPUT "New Color (0-15): ", newColorStr$
    LOCATE 1, 1: PRINT STRING$(79, " ")
    newColorVal = VAL(newColorStr$)
    IF newColorVal >= 0 AND newColorVal <= 15 THEN color = newColorVal
END SUB

'******************************************************************************
'* SUB: HandleLoadFile
'* Purpose: Prompts for and loads a sprite file into the canvas.
'* Parameters:
'*   isSaved (BYREF INTEGER): Unsaved changes flag.
'*   currentFileName (BYREF STRING): The current file name.
'*   canvas() (BYREF INTEGER): The sprite data array.
'******************************************************************************
SUB HandleLoadFile (BYREF isSaved AS INTEGER, BYREF currentFileName AS STRING, BYREF canvas() AS INTEGER)
    DIM path$ AS STRING, fileName$ AS STRING, fileType$ AS STRING, fullPath$ AS STRING
    IF CheckUnsavedChanges(isSaved) = FALSE THEN EXIT SUB

    COLOR 15
    LOCATE 1, 1: INPUT "Path (if needed): ", path$
    LOCATE 1, 1: PRINT STRING$(79, 32)
    IF path$ <> "" THEN path$ = path$ + "\"
    LOCATE 1, 1: INPUT "File-Name: ", fileName$
    LOCATE 1, 1: PRINT STRING$(79, 32)
    LOCATE 1, 1: INPUT "[O]BJ or [B]AS: ", fileType$
    LOCATE 1, 1: PRINT STRING$(79, 32)
    
    currentFileName = fileName$
    fullPath$ = path$ + LEFT$(fileName$, 8)
    ClearCanvas canvas()

    SELECT CASE UCASE$(fileType$)
        CASE "O": ReadVGAFile fullPath$ + ".VGA", canvas()
        CASE "B": ReadBASFile fullPath$ + ".BAS", canvas()
    END SELECT
    RenderCanvas canvas()
    isSaved = TRUE
END SUB

'******************************************************************************
'* SUB: ReadVGAFile
'* Purpose: Reads a raw .VGA file into the canvas.
'* Parameters:
'*   fullPath (BYVAL STRING): The full path to the .VGA file.
'*   canvas() (BYREF INTEGER): The sprite data array to fill.
'******************************************************************************
SUB ReadVGAFile (BYVAL fullPath AS STRING, BYREF canvas() AS INTEGER)
    DIM fileNum AS INTEGER, x AS INTEGER, y AS INTEGER
    fileNum = FREEFILE
    OPEN fullPath FOR BINARY AS #fileNum
    FOR y = 0 TO CANVAS_HEIGHT
        FOR x = 0 TO CANVAS_WIDTH
            canvas(x, y) = ASC(INPUT$(1, #fileNum))
        NEXT x
    NEXT y
    CLOSE #fileNum
END SUB

'******************************************************************************
'* SUB: ReadBASFile
'* Purpose: Reads a .BAS sprite file into the canvas.
'* Parameters:
'*   fullPath (BYVAL STRING): The full path to the .BAS file.
'*   canvas() (BYREF INTEGER): The sprite data array to fill.
'******************************************************************************
SUB ReadBASFile (BYVAL fullPath AS STRING, BYREF canvas() AS INTEGER)
    DIM fileNum AS INTEGER, lineData$ AS STRING, y AS INTEGER, x AS INTEGER, i AS INTEGER
    fileNum = FREEFILE
    y = 0
    OPEN fullPath FOR INPUT AS #fileNum
    DO WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineData$
        IF LEFT$(UCASE$(lineData$), 5) = "DATA " THEN
            lineData$ = MID$(lineData$, 7, LEN(lineData$) - 8)
            IF lineData$ = "99" THEN EXIT DO
            FOR i = 1 TO LEN(lineData$) STEP 2
                x = (i - 1) / 2
                IF x <= CANVAS_WIDTH THEN
                    IF MID$(lineData$, i, 2) = "hg" THEN
                        canvas(x, y) = 0
                    ELSE
                        canvas(x, y) = VAL(MID$(lineData$, i, 2))
                    END IF
                END IF
            NEXT i
            y = y + 1
            IF y > CANVAS_HEIGHT THEN EXIT DO
        END IF
    LOOP
    CLOSE #fileNum
END SUB

'******************************************************************************
'* SUB: HandleSaveFile
'* Purpose: Prompts for and saves the canvas to a file.
'* Parameters:
'*   currentFileName (BYREF STRING): The current file name.
'*   isSaved (BYREF INTEGER): Unsaved changes flag.
'*   canvas() (BYREF INTEGER): The sprite data array.
'******************************************************************************
SUB HandleSaveFile (BYREF currentFileName AS STRING, BYREF isSaved AS INTEGER, BYREF canvas() AS INTEGER)
    DIM path$ AS STRING, fileName$ AS STRING, fileType$ AS STRING, fullPath$ AS STRING
    COLOR 15
    LOCATE 1, 1: INPUT "Path (if needed): ", path$
    LOCATE 1, 1: PRINT STRING$(79, 32)
    IF path$ <> "" THEN path$ = path$ + "\"
    LOCATE 1, 1: INPUT "File-Name: ", fileName$
    LOCATE 1, 1: PRINT STRING$(79, 32)
    LOCATE 1, 1: INPUT "[O]BJ or [B]AS: ", fileType$
    LOCATE 1, 1: PRINT STRING$(79, 32)
    
    currentFileName = fileName$
    fullPath$ = path$ + LEFT$(fileName$, 8)
    
    SELECT CASE LCASE$(fileType$)
        CASE "o": WriteVGAFile fullPath$ + ".VGA", canvas()
        CASE "b": WriteBASFile fullPath$ + ".BAS", canvas()
    END SELECT
    isSaved = TRUE
END SUB

'******************************************************************************
'* SUB: WriteVGAFile
'* Purpose: Writes the canvas to a raw .VGA file.
'* Parameters:
'*   fullPath (BYVAL STRING): The full path for the new file.
'*   canvas() (BYREF INTEGER): The sprite data array to save.
'******************************************************************************
SUB WriteVGAFile (BYVAL fullPath AS STRING, BYREF canvas() AS INTEGER)
    DIM fileNum AS INTEGER, x AS INTEGER, y AS INTEGER
    fileNum = FREEFILE
    OPEN fullPath FOR BINARY AS #fileNum
    FOR y = 0 TO CANVAS_HEIGHT
        FOR x = 0 TO CANVAS_WIDTH
            PUT #fileNum, , CHR$(canvas(x, y))
        NEXT x
    NEXT y
    CLOSE #fileNum
END SUB

'******************************************************************************
'* SUB: WriteBASFile
'* Purpose: Writes the canvas to a compressed .BAS file.
'* Parameters:
'*   fullPath (BYVAL STRING): The full path for the new file.
'*   canvas() (BYREF INTEGER): The sprite data array to save.
'******************************************************************************
SUB WriteBASFile (BYVAL fullPath AS STRING, BYREF canvas() AS INTEGER)
    DIM fileNum AS INTEGER, x AS INTEGER, y AS INTEGER
    DIM firstDataRow AS INTEGER, lastDataRow AS INTEGER
    DIM minDataCol AS INTEGER, maxDataCol AS INTEGER
    DIM rowData$ AS STRING
    
    firstDataRow = -1: lastDataRow = -1
    minDataCol = CANVAS_WIDTH + 1: maxDataCol = -1
    FOR y = 0 TO CANVAS_HEIGHT
        FOR x = 0 TO CANVAS_WIDTH
            IF canvas(x, y) <> 0 THEN
                IF firstDataRow = -1 THEN firstDataRow = y
                lastDataRow = y
                IF x < minDataCol THEN minDataCol = x
                IF x > maxDataCol THEN maxDataCol = x
            END IF
        NEXT x
    NEXT y

    fileNum = FREEFILE
    OPEN fullPath FOR OUTPUT AS #fileNum
    PRINT #fileNum, "' PowerBASIC Sprite Data"
    PRINT #fileNum, "' Generated by PB-VGAEditor"
    PRINT #fileNum, "SpriteLabel:"
    
    IF firstDataRow <> -1 THEN
        FOR y = firstDataRow TO lastDataRow
            rowData$ = ""
            FOR x = minDataCol TO maxDataCol
                IF canvas(x, y) = 0 THEN
                    rowData$ = rowData$ + "hg"
                ELSE
                    rowData$ = rowData$ + RIGHT$("00" + LTRIM$(STR$(canvas(x, y))), 2)
                END IF
            NEXT x
            PRINT #fileNum, "DATA " + CHR$(34) + rowData$ + CHR$(34)
        NEXT y
    END IF

    PRINT #fileNum, "DATA " + CHR$(34) + "99" + CHR$(34)
    CLOSE #fileNum
END SUB

'******************************************************************************
'* SUB: HandleExit
'* Purpose: Exits the program after checking for unsaved changes.
'* Parameters:
'*   isSaved (BYVAL INTEGER): Unsaved changes flag.
'******************************************************************************
SUB HandleExit (BYVAL isSaved AS INTEGER)
    IF CheckUnsavedChanges(isSaved) = FALSE THEN EXIT SUB
    SetMouseVisibility 0
    SCREEN 0
    END
END SUB

'******************************************************************************
'* SUB: GetMouseState
'* Purpose: Gets the current mouse position and button status.
'* Parameters:
'*   mouse (BYREF MouseInfo): A structure to hold the mouse state.
'******************************************************************************
SUB GetMouseState (BYREF mouse AS MouseInfo)
    DIM AX AS INTEGER, BX AS INTEGER, CX AS INTEGER, DX AS INTEGER
    AX = 3
    InterruptWrapper &H33, AX, BX, CX, DX
    mouse.button = BX
    mouse.x = CX
    mouse.y = DX
END SUB

'******************************************************************************
'* FUNCTION: InterruptWrapper%
'* Purpose: A generic wrapper for executing a software interrupt.
'* Parameters:
'*   intNum (BYVAL INTEGER): The interrupt number.
'*   AX, BX, CX, DX (BYVAL INTEGER): Values for the registers.
'* Returns: (INTEGER) The value of the AX register after the interrupt.
'******************************************************************************
FUNCTION InterruptWrapper% (BYVAL intNum AS INTEGER, BYVAL AX AS INTEGER, BYVAL BX AS INTEGER, BYVAL CX AS INTEGER, BYVAL DX AS INTEGER)
    REG 1, AX: REG 2, BX: REG 3, CX: REG 4, DX
    CALL INTERRUPT intNum
    AX = REG(1): BX = REG(2): CX = REG(3): DX = REG(4)
    InterruptWrapper% = AX
END FUNCTION

'******************************************************************************
'* SUB: SetMouseVisibility
'* Purpose: Shows or hides the mouse cursor.
'* Parameters:
'*   visible (BYVAL INTEGER): TRUE to show, FALSE to hide.
'******************************************************************************
SUB SetMouseVisibility (BYVAL visible AS INTEGER)
    DIM AX AS INTEGER, BX AS INTEGER, CX AS INTEGER, DX AS INTEGER
    IF visible = 0 THEN AX = 2 ELSE AX = 1
    InterruptWrapper &H33, AX, BX, CX, DX
END SUB

'******************************************************************************
'* SUB: InitializeMouse
'* Purpose: Initializes the mouse driver.
'* Parameters: None
'******************************************************************************
SUB InitializeMouse ()
    DIM AX AS INTEGER, BX AS INTEGER, CX AS INTEGER, DX AS INTEGER
    AX = 0
    InterruptWrapper &H33, AX, BX, CX, DX
    AX = 1
    InterruptWrapper &H33, AX, BX, CX, DX
END SUB

'******************************************************************************
'* SUB: SetMousePosition
'* Purpose: Sets the mouse cursor position.
'* Parameters:
'*   x (BYVAL INTEGER): The new X coordinate.
'*   y (BYVAL INTEGER): The new Y coordinate.
'******************************************************************************
SUB SetMousePosition (BYVAL x AS INTEGER, BYVAL y AS INTEGER)
    DIM AX AS INTEGER, BX AS INTEGER, CX AS INTEGER, DX AS INTEGER
    AX = 4
    CX = x
    DX = y
    InterruptWrapper &H33, AX, BX, CX, DX
END SUB

'******************************************************************************
'* SUB: WaitForInput
'* Purpose: Pauses execution until the mouse is moved or a button is clicked.
'* Parameters: None
'******************************************************************************
SUB WaitForInput ()
    DIM mouse AS MouseInfo, startX AS INTEGER, startY AS INTEGER, startButton AS INTEGER
    GetMouseState mouse
    startX = mouse.x: startY = mouse.y: startButton = mouse.button
    DO
        GetMouseState mouse
    LOOP UNTIL startX <> mouse.x OR startY <> mouse.y OR startButton <> mouse.button
END SUB
