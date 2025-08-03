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
$INCLUDE "ICONS.SUB"

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
CONST KEY_T = 116
CONST KEY_LEFT_ARROW = 75
CONST KEY_RIGHT_ARROW = 77
CONST KEY_UP_ARROW = 72
CONST KEY_DOWN_ARROW = 80

' Tool IDs
CONST TOOL_DRAW = 0
CONST TOOL_LINE = 1
CONST TOOL_RECTANGLE = 2
CONST TOOL_FILLED_RECTANGLE = 3
CONST TOOL_CIRCLE = 4
CONST TOOL_FILLED_CIRCLE = 5
CONST TOOL_MOVE_LEFT = 6
CONST TOOL_MOVE_RIGHT = 7
CONST TOOL_MOVE_UP = 8
CONST TOOL_MOVE_DOWN = 9
CONST NUM_TOOLS = 10

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

' Color Picker Grid
CONST COLOR_GRID_X = GRID_X_MAX + 10
CONST COLOR_GRID_Y = 10
CONST COLOR_GRID_STEP = 10
CONST COLOR_GRID_COLS = 4
CONST COLOR_GRID_ROWS = 4


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
    DIM isSaved AS INTEGER, isLineMode AS INTEGER, selectedTool AS INTEGER
    DIM currentFileName$ AS STRING
    DIM toolIcons(0 TO NUM_TOOLS - 1) AS STRING

    InitializeSprite mainSprite, spriteCanvas()
    LoadToolIcons toolIcons()

    isSaved = TRUE
    isLineMode = FALSE
    selectedTool = TOOL_DRAW
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

        HandleMouseInput mouse, mainSprite, spriteCanvas(), drawingColor, isLineMode, isSaved, selectedTool
        LINE (currentX, currentY)-STEP(GRID_X_STEP, GRID_Y_STEP), cursorBoxColor, B
        DrawUI drawingColor, currentFileName$, mainSprite, selectedTool, toolIcons()
        HandleKeyboardInput drawingColor, isLineMode, isSaved, currentFileName$, mainSprite, spriteCanvas(), selectedTool

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
SUB HandleMouseInput (BYREF mouse AS MouseInfo, BYREF spr AS Sprite, BYREF canvas() AS INTEGER, BYVAL drawingColor AS INTEGER, BYREF isLineMode AS INTEGER, BYREF isSaved AS INTEGER, BYVAL selectedTool AS INTEGER)
    DIM canvasX AS INTEGER, canvasY AS INTEGER, screenX AS INTEGER, screenY AS INTEGER, colorToUse AS INTEGER
    STATIC firstClickX AS INTEGER, firstClickY AS INTEGER, isFirstClick AS INTEGER

    canvasX = mouse.x / GRID_X_STEP
    canvasY = (mouse.y - GRID_START_Y) / GRID_Y_STEP

    IF canvasX < 0 OR canvasX > spr.width OR canvasY < 0 OR canvasY > spr.height THEN EXIT SUB

    colorToUse = -1
    IF mouse.button = 1 THEN colorToUse = drawingColor
    IF mouse.button = 2 THEN colorToUse = 0

    IF colorToUse <> -1 THEN
        SELECT CASE selectedTool
            CASE TOOL_DRAW
                IF canvas(canvasX, canvasY) <> colorToUse THEN
                    canvas(canvasX, canvasY) = colorToUse
                    isSaved = FALSE
                    UpdateSpriteBoundingBox spr, canvas()
                    CanvasToScreen canvasX, canvasY, screenX, screenY
                    LINE (screenX, screenY)-STEP(GRID_X_STEP, GRID_Y_STEP), colorToUse, BF
                    PSET (canvasX + PREVIEW_X + 3, canvasY + PREVIEW_Y), colorToUse
                END IF
            CASE TOOL_LINE
                ' Line drawing will be handled by a separate interactive mode
            CASE TOOL_RECTANGLE, TOOL_FILLED_RECTANGLE, TOOL_CIRCLE, TOOL_FILLED_CIRCLE
                IF mouse.button = 1 THEN
                    IF isFirstClick = FALSE THEN
                        firstClickX = canvasX
                        firstClickY = canvasY
                        isFirstClick = TRUE
                    ELSE
                        SELECT CASE selectedTool
                            CASE TOOL_RECTANGLE: DrawRectangle spr, canvas(), firstClickX, firstClickY, canvasX, canvasY, drawingColor
                            CASE TOOL_FILLED_RECTANGLE: DrawFilledRectangle spr, canvas(), firstClickX, firstClickY, canvasX, canvasY, drawingColor
                            CASE TOOL_CIRCLE: DrawCircle spr, canvas(), firstClickX, firstClickY, INT(SQR((canvasX - firstClickX)^2 + (canvasY - firstClickY)^2)), drawingColor
                            CASE TOOL_FILLED_CIRCLE: DrawFilledCircle spr, canvas(), firstClickX, firstClickY, INT(SQR((canvasX - firstClickX)^2 + (canvasY - firstClickY)^2)), drawingColor
                        END SELECT
                        isSaved = FALSE
                        isFirstClick = FALSE
                    END IF
                END IF
        END SELECT
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
SUB HandleKeyboardInput (BYREF drawingColor AS INTEGER, BYREF isLineMode AS INTEGER, BYREF isSaved AS INTEGER, BYREF currentFileName AS STRING, BYREF spr AS Sprite, BYREF canvas() AS INTEGER, BYREF selectedTool AS INTEGER)
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
        CASE KEY_T: HandleToolSelection selectedTool
        CASE KEY_ESC: HandleExit isSaved
        CASE 0 ' Extended key
            SELECT CASE keyCode
                CASE KEY_LEFT_ARROW: IF selectedTool = TOOL_MOVE_LEFT THEN MovePixelsLeft spr, canvas(): isSaved = FALSE
                CASE KEY_RIGHT_ARROW: IF selectedTool = TOOL_MOVE_RIGHT THEN MovePixelsRight spr, canvas(): isSaved = FALSE
                CASE KEY_UP_ARROW: IF selectedTool = TOOL_MOVE_UP THEN MovePixelsUp spr, canvas(): isSaved = FALSE
                CASE KEY_DOWN_ARROW: IF selectedTool = TOOL_MOVE_DOWN THEN MovePixelsDown spr, canvas(): isSaved = FALSE
            END SELECT
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
    DIM selectedColorX AS INTEGER, selectedColorY AS INTEGER
    DIM currentKey AS STRING
    DIM oldColor AS INTEGER

    oldColor = color
    selectedColorX = color MOD COLOR_GRID_COLS
    selectedColorY = color \ COLOR_GRID_COLS

    DO
        ' Clear previous selection highlight
        LINE (COLOR_GRID_X + selectedColorX * (COLOR_GRID_STEP + 2) - 1, COLOR_GRID_Y + selectedColorY * (COLOR_GRID_STEP + 2) - 1)-STEP(COLOR_GRID_STEP + 2, COLOR_GRID_STEP + 2), 0, B

        ' Draw new selection highlight
        LINE (COLOR_GRID_X + selectedColorX * (COLOR_GRID_STEP + 2) - 1, COLOR_GRID_Y + selectedColorY * (COLOR_GRID_STEP + 2) - 1)-STEP(COLOR_GRID_STEP + 2, COLOR_GRID_STEP + 2), 15, B

        currentKey = INKEY$
        SELECT CASE ASC(currentKey)
            CASE 0 ' Extended key
                SELECT CASE ASC(RIGHT$(currentKey, 1))
                    CASE KEY_LEFT_ARROW
                        selectedColorX = (selectedColorX - 1 + COLOR_GRID_COLS) MOD COLOR_GRID_COLS
                    CASE KEY_RIGHT_ARROW
                        selectedColorX = (selectedColorX + 1) MOD COLOR_GRID_COLS
                    CASE KEY_UP_ARROW
                        selectedColorY = (selectedColorY - 1 + COLOR_GRID_ROWS) MOD COLOR_GRID_ROWS
                    CASE KEY_DOWN_ARROW
                        selectedColorY = (selectedColorY + 1) MOD COLOR_GRID_ROWS
                END SELECT
            CASE 13 ' Enter
                color = (selectedColorY * COLOR_GRID_COLS) + selectedColorX
                EXIT DO
            CASE 27 ' ESC
                color = oldColor ' Revert to old color
                EXIT DO
        END SELECT
        SLEEP 1
    LOOP
    CLS
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
    DIM errorMessage AS STRING
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
        CASE "V": ReadVGAFile fullPath$ + ".VGA", spr, canvas(), errorMessage
        CASE "B": ReadBASFile fullPath$ + ".BAS", spr, canvas(), errorMessage
        CASE "P": ReadPCXFile fullPath$ + ".PCX", spr, canvas(), errorMessage
        CASE "M": ReadBMPFile fullPath$ + ".BMP", spr, canvas(), errorMessage
        CASE "I": ReadICOFile fullPath$ + ".ICO", spr, canvas(), errorMessage
        CASE "X": ReadXPMFile fullPath$ + ".XPM", spr, canvas(), errorMessage
    END SELECT

    IF errorMessage <> "" THEN
        BEEP: LOCATE 1, 1: COLOR 4: PRINT "Error: " + errorMessage
        SLEEP 2
        LOCATE 1, 1: PRINT STRING$(79, " ")
    END IF

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
    DIM errorMessage AS STRING
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
        CASE "v": WriteVGAFile fullPath$ + ".VGA", spr, canvas(), errorMessage
        CASE "b": WriteBASFile fullPath$ + ".BAS", spr, canvas(), errorMessage
        CASE "p": WritePCXFile fullPath$ + ".PCX", spr, canvas(), errorMessage
        CASE "m": WriteBMPFile fullPath$ + ".BMP", spr, canvas(), errorMessage
        CASE "i": WriteICOFile fullPath$ + ".ICO", spr, canvas(), errorMessage
        CASE "x": WriteXPMFile fullPath$ + ".XPM", spr, canvas(), errorMessage
    END SELECT

    IF errorMessage <> "" THEN
        BEEP: LOCATE 1, 1: COLOR 4: PRINT "Error: " + errorMessage
        SLEEP 2
        LOCATE 1, 1: PRINT STRING$(79, " ")
    ELSE
        isSaved = TRUE
    END IF
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
'* SUB: LoadToolIcons
'* Purpose: Loads tool icon data from ICONS.SUB into an array.
'******************************************************************************
SUB LoadToolIcons (BYREF toolIcons() AS STRING)
    DIM i AS INTEGER, j AS INTEGER, iconRow AS STRING
    FOR i = 0 TO NUM_TOOLS - 1
        toolIcons(i) = ""
        FOR j = 1 TO 8
            READ iconRow
            toolIcons(i) = toolIcons(i) + iconRow
        NEXT j
    NEXT i
END SUB

'******************************************************************************
'* SUB: HandleToolSelection
'* Purpose: Allows the user to select a drawing tool interactively.
'******************************************************************************
SUB HandleToolSelection (BYREF selectedTool AS INTEGER)
    DIM currentKey AS STRING
    DIM oldTool AS INTEGER
    oldTool = selectedTool

    DO
        ' Show tool selection prompt
        LOCATE 1, 1: COLOR 15
        PRINT "Select Tool: [0=Draw 1=Line 2=Rect 3=FillRect 4=Circle 5=FillCircle 6-9=Move] Tool=" + STR$(selectedTool) + " ";

        currentKey = INKEY$
        SELECT CASE ASC(currentKey)
            CASE 0 ' Extended key
                SELECT CASE ASC(RIGHT$(currentKey, 1))
                    CASE KEY_LEFT_ARROW
                        selectedTool = (selectedTool - 1 + NUM_TOOLS) MOD NUM_TOOLS
                    CASE KEY_RIGHT_ARROW
                        selectedTool = (selectedTool + 1) MOD NUM_TOOLS
                END SELECT
            CASE 13 ' Enter
                EXIT DO
            CASE 27 ' ESC
                selectedTool = oldTool ' Revert to old tool
                EXIT DO
        END SELECT
        SLEEP 1
    LOOP
    LOCATE 1, 1: PRINT STRING$(79, " ")
END SUB
