' VGAMAUS.BAS - Main Application File
' Acts as the View/Controller, binding all modules together.

$INCLUDE "INTRO.SUB"
$INCLUDE "MOUSE.SUB"
$INCLUDE "SPRITE_OPS.SUB"
$INCLUDE "FILE_VGA.SUB"
$INCLUDE "FILE_BAS.SUB"
$INCLUDE "FILE_BMP.SUB"
$INCLUDE "FILE_PCX.SUB"
$INCLUDE "FILE_ICO.SUB"
$INCLUDE "FILE_XPM.SUB"

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

' Grid & Drawing - These are now for screen layout only
CONST GRID_X_MAX = 534
CONST GRID_Y_MAX = 464
CONST GRID_X_STEP = 6
CONST GRID_Y_STEP = 6
CONST GRID_COLOR = 8
CONST DEFAULT_DRAW_COLOR = 15
CONST GRID_START_Y = 50

' Preview Window
CONST PREVIEW_X = GRID_X_MAX + 10
CONST PREVIEW_Y = 150


DIM mouse AS MouseInfo
InitializeSystem mouse
ShowIntro
WaitForInput
MainEditorLoop

'******************************************************************************
'* SUB: MainEditorLoop
'* Purpose: The main event loop for the sprite editor.
'* Parameters: None
'******************************************************************************
SUB MainEditorLoop
    DIM mouse AS MouseInfo
    DIM mainSprite AS Sprite
    DIM spriteCanvas() AS INTEGER
    DIM cursorBoxColorToggle AS INTEGER, cursorBoxColor AS INTEGER
    DIM drawingColor AS INTEGER
    DIM currentX AS INTEGER, currentY AS INTEGER
    DIM prevX AS INTEGER, prevY AS INTEGER
    DIM isSaved AS INTEGER, isLineMode AS INTEGER
    DIM currentFileName$ AS STRING

    InitializeSprite mainSprite, spriteCanvas()

    isSaved = TRUE
    isLineMode = FALSE
    currentFileName$ = "UNBENANNT"
    drawingColor = DEFAULT_DRAW_COLOR
    currentX = 0
    currentY = GRID_START_Y
    cursorBoxColorToggle = 1
    
    CLS
    DrawGrid

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

        HandleMouseInput mouse, mainSprite, spriteCanvas(), drawingColor, isLineMode, isSaved
        LINE (currentX, currentY)-STEP(GRID_X_STEP, GRID_Y_STEP), cursorBoxColor, B
        DrawUI drawingColor, currentFileName$, mainSprite
        HandleKeyboardInput drawingColor, isLineMode, isSaved, currentFileName$, mainSprite, spriteCanvas()

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
'* SUB: HandleMouseInput
'* Purpose: Processes mouse clicks to modify the sprite canvas.
'* Parameters:
'*   mouse (BYREF MouseInfo): The current state of the mouse.
'*   spr (BYREF Sprite): The sprite metadata.
'*   canvas() (BYREF INTEGER): The sprite data array.
'*   drawingColor (BYVAL INTEGER): The current color to draw with.
'*   isLineMode (BYVAL INTEGER): Flag for line drawing mode.
'*   isSaved (BYREF INTEGER): Flag indicating if the file has unsaved changes.
'******************************************************************************
SUB HandleMouseInput (BYREF mouse AS MouseInfo, BYREF spr AS Sprite, BYREF canvas() AS INTEGER, BYVAL drawingColor AS INTEGER, BYVAL isLineMode AS INTEGER, BYREF isSaved AS INTEGER)
    DIM canvasX AS INTEGER, canvasY AS INTEGER, screenX AS INTEGER, screenY AS INTEGER, colorToUse AS INTEGER

    canvasX = mouse.x / GRID_X_STEP
    canvasY = (mouse.y - GRID_START_Y) / GRID_Y_STEP

    IF canvasX < 0 OR canvasX > spr.width OR canvasY < 0 OR canvasY > spr.height THEN EXIT SUB

    colorToUse = -1
    IF mouse.button = 1 THEN colorToUse = drawingColor
    IF mouse.button = 2 THEN colorToUse = 0
    IF isLineMode THEN colorToUse = drawingColor

    IF colorToUse <> -1 AND canvas(canvasX, canvasY) <> colorToUse THEN
        canvas(canvasX, canvasY) = colorToUse
        isSaved = FALSE
        UpdateSpriteBoundingBox spr, canvas()
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
'*   spr (BYREF Sprite): The sprite metadata.
'*   canvas() (BYREF INTEGER): The sprite data array.
'******************************************************************************
SUB HandleKeyboardInput (BYREF drawingColor AS INTEGER, BYREF isLineMode AS INTEGER, BYREF isSaved AS INTEGER, BYREF currentFileName AS STRING, BYREF spr AS Sprite, BYREF canvas() AS INTEGER)
    DIM inputKey$ AS STRING, keyCode AS INTEGER
    inputKey$ = INKEY$
    IF inputKey$ = "" THEN EXIT SUB
    keyCode = ASC(inputKey$)
    IF LEN(inputKey$) > 1 THEN keyCode = ASC(RIGHT$(inputKey$, 1))

    SELECT CASE keyCode
        CASE KEY_N: HandleNewFile isSaved, isLineMode, currentFileName, spr, canvas()
        CASE KEY_C: HandleChangeColor drawingColor
        CASE KEY_L: HandleLoadFile isSaved, currentFileName, spr, canvas()
        CASE KEY_S: HandleSaveFile currentFileName, isSaved, spr, canvas()
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
'*   spr (BYREF Sprite): The sprite metadata.
'*   canvas() (BYREF INTEGER): The sprite data array.
'******************************************************************************
SUB HandleNewFile (BYREF isSaved AS INTEGER, BYREF isLineMode AS INTEGER, BYREF currentFileName AS STRING, BYREF spr AS Sprite, BYREF canvas() AS INTEGER)
    IF CheckUnsavedChanges(isSaved) = FALSE THEN EXIT SUB
    isSaved = TRUE
    isLineMode = FALSE
    currentFileName = "UNBENANNT"
    ClearCanvas spr, canvas()
    RenderCanvas spr, canvas()
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
'*   spr (BYREF Sprite): The sprite metadata.
'*   canvas() (BYREF INTEGER): The sprite data array.
'******************************************************************************
SUB HandleLoadFile (BYREF isSaved AS INTEGER, BYREF currentFileName AS STRING, BYREF spr AS Sprite, BYREF canvas() AS INTEGER)
    DIM path$ AS STRING, fileName$ AS STRING, fileType$ AS STRING, fullPath$ AS STRING
    IF CheckUnsavedChanges(isSaved) = FALSE THEN EXIT SUB

    COLOR 15
    LOCATE 1, 1: INPUT "Path (if needed): ", path$
    LOCATE 1, 1: PRINT STRING$(79, 32)
    IF path$ <> "" THEN path$ = path$ + "\"
    LOCATE 1, 1: INPUT "File-Name: ", fileName$
    LOCATE 1, 1: PRINT STRING$(79, 32)
    LOCATE 1, 1: INPUT "[V]GA, [B]AS, [P]CX, B[M]P, [I]CO, [X]PM: ", fileType$
    LOCATE 1, 1: PRINT STRING$(79, 32)
    
    currentFileName = fileName$
    fullPath$ = path$ + LEFT$(fileName$, 8)
    ClearCanvas spr, canvas()

    SELECT CASE UCASE$(fileType$)
        CASE "V": ReadVGAFile fullPath$ + ".VGA", spr, canvas()
        CASE "B": ReadBASFile fullPath$ + ".BAS", spr, canvas()
        CASE "P": ReadPCXFile fullPath$ + ".PCX", spr, canvas()
        CASE "M": ReadBMPFile fullPath$ + ".BMP", spr, canvas()
        CASE "I": ReadICOFile fullPath$ + ".ICO", spr, canvas()
        CASE "X": ReadXPMFile fullPath$ + ".XPM", spr, canvas()
    END SELECT
    UpdateSpriteBoundingBox spr, canvas()
    RenderCanvas spr, canvas()
    isSaved = TRUE
END SUB

'******************************************************************************
'* SUB: HandleSaveFile
'* Purpose: Prompts for and saves the canvas to a file.
'* Parameters:
'*   currentFileName (BYREF STRING): The current file name.
'*   isSaved (BYREF INTEGER): Unsaved changes flag.
'*   spr (BYREF Sprite): The sprite metadata.
'*   canvas() (BYREF INTEGER): The sprite data array.
'******************************************************************************
SUB HandleSaveFile (BYREF currentFileName AS STRING, BYREF isSaved AS INTEGER, BYREF spr AS Sprite, BYREF canvas() AS INTEGER)
    DIM path$ AS STRING, fileName$ AS STRING, fileType$ AS STRING, fullPath$ AS STRING
    COLOR 15
    LOCATE 1, 1: INPUT "Path (if needed): ", path$
    LOCATE 1, 1: PRINT STRING$(79, 32)
    IF path$ <> "" THEN path$ = path$ + "\"
    LOCATE 1, 1: INPUT "File-Name: ", fileName$
    LOCATE 1, 1: PRINT STRING$(79, 32)
    LOCATE 1, 1: INPUT "[V]GA, [B]AS, [P]CX, B[M]P, [I]CO, [X]PM: ", fileType$
    LOCATE 1, 1: PRINT STRING$(79, 32)
    
    currentFileName = fileName$
    fullPath$ = path$ + LEFT$(fileName$, 8)
    
    SELECT CASE LCASE$(fileType$)
        CASE "v": WriteVGAFile fullPath$ + ".VGA", spr, canvas()
        CASE "b": WriteBASFile fullPath$ + ".BAS", spr, canvas()
        CASE "p": WritePCXFile fullPath$ + ".PCX", spr, canvas()
        CASE "m": WriteBMPFile fullPath$ + ".BMP", spr, canvas()
        CASE "i": WriteICOFile fullPath$ + ".ICO", spr, canvas()
        CASE "x": WriteXPMFile fullPath$ + ".XPM", spr, canvas()
    END SELECT
    isSaved = TRUE
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
