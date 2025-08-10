' VGAMAUS.BAS - Main Application File
' Acts as the View/Controller, binding all modules together.

' --- Constants ---
%TRUE = -1
%FALSE = 0

' Key Codes
%KEY_ESC = 27
%KEY_INSERT = 82
%KEY_C = 99
%KEY_L = 108
%KEY_N = 110
%KEY_S = 115
%KEY_T = 116
%KEY_LEFT_ARROW = 75
%KEY_RIGHT_ARROW = 77
%KEY_UP_ARROW = 72
%KEY_DOWN_ARROW = 80

' Tool IDs
%TOOL_DRAW = 0
%TOOL_LINE = 1
%TOOL_RECTANGLE = 2
%TOOL_FILLED_RECTANGLE = 3
%TOOL_CIRCLE = 4
%TOOL_FILLED_CIRCLE = 5
%TOOL_MOVE_LEFT = 6
%TOOL_MOVE_RIGHT = 7
%TOOL_MOVE_UP = 8
%TOOL_MOVE_DOWN = 9
%NUM_TOOLS = 10

' Grid & Drawing - These are now for screen layout only
%GRID_X_MAX = 534
%GRID_Y_MAX = 464
%GRID_X_STEP = 6
%GRID_Y_STEP = 6
%GRID_COLOR = 8
%DEFAULT_DRAW_COLOR = 15
%GRID_START_Y = 50

' Preview Window
%PREVIEW_X = %GRID_X_MAX + 10
%PREVIEW_Y = 150

' Color Picker Grid
%COLOR_GRID_X = %GRID_X_MAX + 10
%COLOR_GRID_Y = 92
%COLOR_GRID_STEP = 10
%COLOR_GRID_COLS = 4
%COLOR_GRID_ROWS = 4

TYPE Sprite
    spriteWidth AS INTEGER
    spriteHeight AS INTEGER
    boundingBoxX1 AS INTEGER
    boundingBoxY1 AS INTEGER
    boundingBoxX2 AS INTEGER
    boundingBoxY2 AS INTEGER
END TYPE

$INCLUDE "INTRO.SUB"
$INCLUDE "MOUSE.SUB"
$INCLUDE "SPRITE.SUB"
$INCLUDE "PREVIEW.SUB"
$INCLUDE "FILE_VGA.SUB"
$INCLUDE "FILE_BAS.SUB"
$INCLUDE "FILE_BMP.SUB"
$INCLUDE "FILE_PCX.SUB"
$INCLUDE "FILE_ICO.SUB"
$INCLUDE "FILE_XPM.SUB"
$INCLUDE "ICONS.SUB"


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
    DIM DYNAMIC spriteCanvas(0 TO 1, 0 TO 1) AS INTEGER
    DIM cursorBoxColorToggle AS INTEGER
    DIM cursorBoxColor AS INTEGER
    DIM drawingColor AS INTEGER
    DIM currentX AS INTEGER
    DIM currentY AS INTEGER
    DIM prevX AS INTEGER
    DIM prevY AS INTEGER
    DIM isSaved AS INTEGER
    DIM isLineMode AS INTEGER
    DIM selectedTool AS INTEGER
    DIM currentFileName AS STRING
    DIM toolIcons(0 TO %NUM_TOOLS - 1) AS STRING

    InitializeSprite mainSprite, spriteCanvas()
    LoadToolIcons toolIcons()

    isSaved = %TRUE
    isLineMode = %FALSE
    selectedTool = %TOOL_DRAW
    currentFileName = "UNBENANNT"
    drawingColor = %DEFAULT_DRAW_COLOR
    currentX = 0
    currentY = %GRID_START_Y
    cursorBoxColorToggle = 1
    
    CLS
    DrawGrid
    DrawUI drawingColor, currentFileName, mainSprite, selectedTool, toolIcons()
    
    DO
        GetMouseState mouse
        prevX = currentX
        prevY = currentY
        currentX = INT(mouse.x / %GRID_X_STEP) * %GRID_X_STEP
        currentY = INT(mouse.y / %GRID_Y_STEP) * %GRID_Y_STEP + 2

        IF currentX > %GRID_X_MAX - %GRID_X_STEP THEN currentX = %GRID_X_MAX - %GRID_X_STEP
        IF currentX < 0 THEN currentX = 0
        IF currentY < %GRID_START_Y THEN currentY = %GRID_START_Y
        IF currentY > %GRID_Y_MAX - %GRID_Y_STEP THEN currentY = %GRID_Y_MAX - %GRID_Y_STEP

        ' Redraw cursor every iteration to maintain flashing effect
        LINE (prevX, prevY)-STEP(%GRID_X_STEP, %GRID_Y_STEP), %GRID_COLOR, B
        IF cursorBoxColorToggle = 1 THEN cursorBoxColor = 4 ELSE cursorBoxColor = 14
        LINE (currentX, currentY)-STEP(%GRID_X_STEP, %GRID_Y_STEP), cursorBoxColor, B
        IF cursorBoxColorToggle = 1 THEN cursorBoxColorToggle = 2 ELSE cursorBoxColorToggle = 1

        HandleMouseInput mouse, mainSprite, spriteCanvas(), drawingColor, isLineMode, isSaved, selectedTool, currentFileName, toolIcons()
        IF HandleKeyboardInput(drawingColor, isLineMode, isSaved, currentFileName, mainSprite, spriteCanvas(), selectedTool) = %TRUE THEN
            DrawUI drawingColor, currentFileName, mainSprite, selectedTool, toolIcons()
        END IF
    LOOP
END SUB

'******************************************************************************
'* SUB: InitializeSystem
'* Purpose: Initializes screen mode and mouse driver.
'* Parameters:
'*   mouse (BYREF MouseInfo): The mouse state variable to initialize.
'******************************************************************************
SUB InitializeSystem (mouse AS MouseInfo)
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
SUB HandleMouseInput (mouse AS MouseInfo, spr AS Sprite, canvas() AS INTEGER, BYVAL drawingColor AS INTEGER, isLineMode AS INTEGER, isSaved AS INTEGER, BYVAL selectedTool AS INTEGER, BYVAL currentFileName AS STRING, toolIcons() AS STRING)
    DIM canvasX AS INTEGER
    DIM canvasY AS INTEGER
    DIM screenX AS INTEGER
    DIM screenY AS INTEGER
    DIM colorToUse AS INTEGER
    DIM firstClickX AS STATIC INTEGER
    DIM firstClickY AS STATIC INTEGER
    DIM isFirstClick AS STATIC INTEGER
    DIM lastPreviewX AS STATIC INTEGER
    DIM lastPreviewY AS STATIC INTEGER

    canvasX = mouse.x / %GRID_X_STEP
    canvasY = (mouse.y - %GRID_START_Y) / %GRID_Y_STEP

    IF canvasX < 0 OR canvasX > spr.spriteWidth OR canvasY < 0 OR canvasY > spr.spriteHeight THEN EXIT SUB

    colorToUse = -1
    IF mouse.button = 1 THEN colorToUse = drawingColor
    IF mouse.button = 2 THEN colorToUse = 0

    SELECT CASE selectedTool
        CASE %TOOL_DRAW
            IF colorToUse <> -1 THEN
                IF canvas(canvasX, canvasY) <> colorToUse THEN
                    canvas(canvasX, canvasY) = colorToUse
                    isSaved = %FALSE
                    ' Incremental bounding box update instead of full scan
                    IF colorToUse <> 0 THEN  ' Non-transparent pixel
                        IF spr.boundingBoxX2 = -1 THEN  ' Empty sprite, initialize
                            spr.boundingBoxX1 = canvasX
                            spr.boundingBoxY1 = canvasY
                            spr.boundingBoxX2 = canvasX
                            spr.boundingBoxY2 = canvasY
                        ELSE
                            IF canvasX < spr.boundingBoxX1 THEN spr.boundingBoxX1 = canvasX
                            IF canvasY < spr.boundingBoxY1 THEN spr.boundingBoxY1 = canvasY  
                            IF canvasX > spr.boundingBoxX2 THEN spr.boundingBoxX2 = canvasX
                            IF canvasY > spr.boundingBoxY2 THEN spr.boundingBoxY2 = canvasY
                        END IF
                    END IF
                    CanvasToScreen canvasX, canvasY, screenX, screenY
                    LINE (screenX, screenY)-STEP(%GRID_X_STEP, %GRID_Y_STEP), colorToUse, BF
                    LINE (screenX, screenY)-STEP(%GRID_X_STEP, %GRID_Y_STEP), %GRID_COLOR, B
                    PSET (canvasX + %PREVIEW_X + 3, canvasY + %PREVIEW_Y), colorToUse
                END IF
            END IF
        CASE %TOOL_LINE
            ' Line drawing will be handled by a separate interactive mode
        CASE %TOOL_RECTANGLE, %TOOL_FILLED_RECTANGLE, %TOOL_CIRCLE, %TOOL_FILLED_CIRCLE
            IF mouse.button = 1 THEN
                IF isFirstClick = %FALSE THEN
                    ' Start of drag - record starting position
                    firstClickX = canvasX
                    firstClickY = canvasY
                    lastPreviewX = canvasX
                    lastPreviewY = canvasY
                    isFirstClick = %TRUE
                ELSE
                    ' Clear previous preview if mouse moved
                    IF canvasX <> lastPreviewX OR canvasY <> lastPreviewY THEN
                        SELECT CASE selectedTool
                            CASE %TOOL_RECTANGLE: ClearRectanglePreview firstClickX, firstClickY, lastPreviewX, lastPreviewY
                            CASE %TOOL_FILLED_RECTANGLE: ClearFilledRectanglePreview firstClickX, firstClickY, lastPreviewX, lastPreviewY
                        END SELECT
                    END IF
                    ' Show new preview
                    SELECT CASE selectedTool  
                        CASE %TOOL_RECTANGLE: ShowRectanglePreview firstClickX, firstClickY, canvasX, canvasY, drawingColor
                        CASE %TOOL_FILLED_RECTANGLE: ShowFilledRectanglePreview firstClickX, firstClickY, canvasX, canvasY, drawingColor
                    END SELECT
                    lastPreviewX = canvasX
                    lastPreviewY = canvasY
                END IF
            ELSEIF isFirstClick = %TRUE THEN
                ' Mouse released - clear preview and draw final shape
                SELECT CASE selectedTool
                    CASE %TOOL_RECTANGLE: 
                        ClearRectanglePreview firstClickX, firstClickY, lastPreviewX, lastPreviewY
                        DrawRectangle spr, canvas(), firstClickX, firstClickY, canvasX, canvasY, drawingColor
                    CASE %TOOL_FILLED_RECTANGLE: 
                        ClearFilledRectanglePreview firstClickX, firstClickY, lastPreviewX, lastPreviewY
                        DrawFilledRectangle spr, canvas(), firstClickX, firstClickY, canvasX, canvasY, drawingColor
                    CASE %TOOL_CIRCLE: 
                        DrawCircle spr, canvas(), firstClickX, firstClickY, INT(SQR((canvasX - firstClickX)^2 + (canvasY - firstClickY)^2)), drawingColor
                    CASE %TOOL_FILLED_CIRCLE: 
                        DrawFilledCircle spr, canvas(), firstClickX, firstClickY, INT(SQR((canvasX - firstClickX)^2 + (canvasY - firstClickY)^2)), drawingColor
                END SELECT
                RenderCanvas spr, canvas()
                DrawUI drawingColor, currentFileName, spr, selectedTool, toolIcons()
                isSaved = %FALSE
                isFirstClick = %FALSE
            END IF
    END SELECT
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
FUNCTION HandleKeyboardInput (drawingColor AS INTEGER, isLineMode AS INTEGER, isSaved AS INTEGER, currentFileName AS STRING, spr AS Sprite, canvas() AS INTEGER, selectedTool AS INTEGER) AS INTEGER
    DIM inputKey AS STRING
    DIM keyCode AS INTEGER
    HandleKeyboardInput = %FALSE
    inputKey = INKEY$
    IF inputKey = "" THEN EXIT FUNCTION
    keyCode = ASC(inputKey)
    IF LEN(inputKey) > 1 THEN keyCode = ASC(RIGHT$(inputKey, 1))

    SELECT CASE keyCode
        CASE %KEY_N: HandleNewFile isSaved, isLineMode, currentFileName, spr, canvas(): HandleKeyboardInput = %TRUE
        CASE %KEY_C: HandleChangeColor drawingColor: HandleKeyboardInput = %TRUE
        CASE %KEY_L: HandleLoadFile isSaved, currentFileName, spr, canvas(): HandleKeyboardInput = %TRUE
        CASE %KEY_S: HandleSaveFile currentFileName, isSaved, spr, canvas()
        CASE %KEY_INSERT: isLineMode = NOT isLineMode
        CASE %KEY_T: HandleToolSelection selectedTool: HandleKeyboardInput = %TRUE
        CASE %KEY_ESC: HandleExit isSaved
        CASE 0 ' Extended key
            SELECT CASE keyCode
                CASE %KEY_LEFT_ARROW: IF selectedTool = %TOOL_MOVE_LEFT THEN MovePixelsLeft spr, canvas(): isSaved = %FALSE
                CASE %KEY_RIGHT_ARROW: IF selectedTool = %TOOL_MOVE_RIGHT THEN MovePixelsRight spr, canvas(): isSaved = %FALSE
                CASE %KEY_UP_ARROW: IF selectedTool = %TOOL_MOVE_UP THEN MovePixelsUp spr, canvas(): isSaved = %FALSE
                CASE %KEY_DOWN_ARROW: IF selectedTool = %TOOL_MOVE_DOWN THEN MovePixelsDown spr, canvas(): isSaved = %FALSE
            END SELECT
    END SELECT
END FUNCTION

'******************************************************************************
'* FUNCTION: CheckUnsavedChanges
'* Purpose: Asks user to confirm if they want to discard unsaved changes.
'* Parameters:
'*   isSaved (BYVAL INTEGER): Flag indicating if there are unsaved changes.
'* Returns: (INTEGER) %TRUE if okay to proceed, %FALSE to cancel.
'******************************************************************************
FUNCTION CheckUnsavedChanges (BYVAL isSaved AS INTEGER) AS INTEGER
    DIM confirm AS STRING
    CheckUnsavedChanges = %TRUE
    IF isSaved = %FALSE THEN
        LOCATE 1, 1: COLOR 4: BEEP
        PRINT "WARNING: File not saved. Continue? (y/n) ";
        INPUT "", confirm
        LOCATE 1, 1: PRINT STRING$(79, " ")
        IF LCASE$(confirm) <> "y" THEN CheckUnsavedChanges = %FALSE
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
SUB HandleNewFile (isSaved AS INTEGER, isLineMode AS INTEGER, currentFileName AS STRING, spr AS Sprite, canvas() AS INTEGER)
    IF CheckUnsavedChanges(isSaved) = %FALSE THEN EXIT SUB
    isSaved = %TRUE
    isLineMode = %FALSE
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
SUB HandleChangeColor (drawColor AS INTEGER)
    DIM selectedColorX AS INTEGER
    DIM selectedColorY AS INTEGER
    DIM currentKey AS STRING
    DIM oldColor AS INTEGER
    DIM temp AS INTEGER

    oldColor = drawColor
    selectedColorX = drawColor MOD %COLOR_GRID_COLS
    selectedColorY = drawColor \ %COLOR_GRID_COLS

    ' Draw initial selection highlight
    LINE (%COLOR_GRID_X + selectedColorX * (%COLOR_GRID_STEP + 2) - 1, %COLOR_GRID_Y + selectedColorY * (%COLOR_GRID_STEP + 2) - 1)-STEP(%COLOR_GRID_STEP + 2, %COLOR_GRID_STEP + 2), 15, B

    DO
        currentKey = WaitForKey()
        SELECT CASE ASC(currentKey)
            CASE 0 ' Extended key
                    ' Clear previous selection highlight before moving
                    LINE (%COLOR_GRID_X + selectedColorX * (%COLOR_GRID_STEP + 2) - 1, %COLOR_GRID_Y + selectedColorY * (%COLOR_GRID_STEP + 2) - 1)-STEP(%COLOR_GRID_STEP + 2, %COLOR_GRID_STEP + 2), 0, B
                    
                    SELECT CASE ASC(RIGHT$(currentKey, 1))
                        CASE %KEY_LEFT_ARROW ' Left Arrow
                            selectedColorX = (selectedColorX - 1 + %COLOR_GRID_COLS) MOD %COLOR_GRID_COLS
                        CASE %KEY_RIGHT_ARROW ' Right Arrow
                            selectedColorX = (selectedColorX + 1) MOD %COLOR_GRID_COLS
                        CASE %KEY_UP_ARROW ' Up Arrow
                            selectedColorY = (selectedColorY - 1 + %COLOR_GRID_ROWS) MOD %COLOR_GRID_ROWS
                        CASE %KEY_DOWN_ARROW ' Down Arrow
                            selectedColorY = (selectedColorY + 1) MOD %COLOR_GRID_ROWS
                    END SELECT
                    
                    ' Draw new selection highlight after moving
                    LINE (%COLOR_GRID_X + selectedColorX * (%COLOR_GRID_STEP + 2) - 1, %COLOR_GRID_Y + selectedColorY * (%COLOR_GRID_STEP + 2) - 1)-STEP(%COLOR_GRID_STEP + 2, %COLOR_GRID_STEP + 2), 15, B
            CASE 13 ' Enter
                drawColor = (selectedColorY * %COLOR_GRID_COLS) + selectedColorX
                EXIT DO
            CASE 27 ' ESC
                drawColor = oldColor ' Revert to old color
                EXIT DO
        END SELECT
    LOOP
    ' Don't clear the selection highlight - DrawUI will show the proper selection
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
SUB HandleLoadFile (isSaved AS INTEGER, currentFileName AS STRING, spr AS Sprite, canvas() AS INTEGER)
    DIM path AS STRING
    DIM fileName AS STRING
    DIM fileType AS STRING
    DIM fullPath AS STRING
    DIM errorMessage AS STRING
    IF CheckUnsavedChanges(isSaved) = %FALSE THEN EXIT SUB

    COLOR 15
    LOCATE 1, 1: INPUT "Path (if needed): ", path
    LOCATE 1, 1: PRINT STRING$(79, 32)
    IF path <> "" THEN path = path + "\"
    LOCATE 1, 1: INPUT "File-Name: ", fileName
    LOCATE 1, 1: PRINT STRING$(79, 32)
    LOCATE 1, 1: INPUT "[V]GA, [B]AS, [P]CX, B[M]P, [I]CO, [X]PM: ", fileType
    LOCATE 1, 1: PRINT STRING$(79, 32)
    
    currentFileName = fileName
    fullPath = path + LEFT$(fileName, 8)
    ClearCanvas spr, canvas()

    SELECT CASE UCASE$(fileType)
        CASE "V": ReadVGAFile fullPath + ".VGA", spr, canvas(), errorMessage
        CASE "B": ReadBASFile fullPath + ".BAS", spr, canvas(), errorMessage
        CASE "P": ReadPCXFile fullPath + ".PCX", spr, canvas(), errorMessage
        CASE "M": ReadBMPFile fullPath + ".BMP", spr, canvas(), errorMessage
        CASE "I": ReadICOFile fullPath + ".ICO", spr, canvas(), errorMessage
        CASE "X": ReadXPMFile fullPath + ".XPM", spr, canvas(), errorMessage
    END SELECT

    IF errorMessage <> "" THEN
        BEEP: LOCATE 1, 1: COLOR 4: PRINT "Error: " + errorMessage
        SLEEP 2
        LOCATE 1, 1: PRINT STRING$(79, " ")
    END IF

    UpdateSpriteBoundingBox spr, canvas()
    RenderCanvas spr, canvas()
    isSaved = %TRUE
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
SUB HandleSaveFile (currentFileName AS STRING, isSaved AS INTEGER, spr AS Sprite, canvas() AS INTEGER)
    DIM path AS STRING
    DIM fileName AS STRING
    DIM fileType AS STRING
    DIM fullPath AS STRING
    DIM errorMessage AS STRING
    COLOR 15
    LOCATE 1, 1: INPUT "Path (if needed): ", path
    LOCATE 1, 1: PRINT STRING$(79, 32)
    IF path <> "" THEN path = path + "\"
    LOCATE 1, 1: INPUT "File-Name: ", fileName
    LOCATE 1, 1: PRINT STRING$(79, 32)
    LOCATE 1, 1: INPUT "[V]GA, [B]AS, [P]CX, B[M]P, [I]CO, [X]PM: ", fileType
    LOCATE 1, 1: PRINT STRING$(79, 32)
    
    currentFileName = fileName
    fullPath = path + LEFT$(fileName, 8)
    
    SELECT CASE LCASE$(fileType)
        CASE "v": WriteVGAFile fullPath + ".VGA", spr, canvas(), errorMessage
        CASE "b": WriteBASFile fullPath + ".BAS", spr, canvas(), errorMessage
        CASE "p": WritePCXFile fullPath + ".PCX", spr, canvas(), errorMessage
        CASE "m": WriteBMPFile fullPath + ".BMP", spr, canvas(), errorMessage
        CASE "i": WriteICOFile fullPath + ".ICO", spr, canvas(), errorMessage
        CASE "x": WriteXPMFile fullPath + ".XPM", spr, canvas(), errorMessage
    END SELECT

    IF errorMessage <> "" THEN
        BEEP: LOCATE 1, 1: COLOR 4: PRINT "Error: " + errorMessage
        SLEEP 2
        LOCATE 1, 1: PRINT STRING$(79, " ")
    ELSE
        isSaved = %TRUE
    END IF
END SUB

'******************************************************************************
'* SUB: HandleExit
'* Purpose: Exits the program after checking for unsaved changes.
'* Parameters:
'*   isSaved (BYVAL INTEGER): Unsaved changes flag.
'******************************************************************************
SUB HandleExit (BYVAL isSaved AS INTEGER)
    IF CheckUnsavedChanges(isSaved) = %FALSE THEN EXIT SUB
    SetMouseVisibility 0
    SCREEN 0
    END
END SUB

'******************************************************************************
'* SUB: LoadToolIcons
'* Purpose: Loads tool icon data from ICONS.SUB into an array.
'******************************************************************************
SUB LoadToolIcons (toolIcons() AS STRING)
    DIM i AS INTEGER
    DIM j AS INTEGER
    DIM iconRow AS STRING
    RESTORE  ' Reset DATA pointer to beginning
    FOR i = 0 TO %NUM_TOOLS - 1
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
SUB HandleToolSelection (selectedTool AS INTEGER)
    DIM currentKey AS STRING
    DIM oldTool AS INTEGER
    DIM toolIcons(0 TO %NUM_TOOLS - 1) AS STRING
    DIM i AS INTEGER
    DIM iconX AS INTEGER
    DIM iconY AS INTEGER
    
    oldTool = selectedTool
    LoadToolIcons toolIcons()
    
    ' Show initial tool selection message
    LOCATE 1, 1: COLOR 15
    PRINT "Select Tool: Use arrow keys, Enter to confirm, ESC to cancel                    ";

    DO
        currentKey = WaitForKey()
        
        SELECT CASE ASC(currentKey)
            CASE 0 ' Extended key
                ' Clear old selection highlight before moving
                iconX = %PREVIEW_X + (selectedTool MOD 2) * 20
                iconY = %PREVIEW_Y + ((%GRID_Y_MAX - %GRID_START_Y) / %GRID_Y_STEP) + 20 + (selectedTool \ 2) * 20
                DrawIcon iconX, iconY, toolIcons(selectedTool), %FALSE
                
                SELECT CASE ASC(RIGHT$(currentKey, 1))
                    CASE %KEY_LEFT_ARROW ' Left Arrow
                        selectedTool = (selectedTool - 1 + %NUM_TOOLS) MOD %NUM_TOOLS
                    CASE %KEY_RIGHT_ARROW ' Right Arrow
                        selectedTool = (selectedTool + 1) MOD %NUM_TOOLS
                    CASE %KEY_UP_ARROW ' Up Arrow
                        IF selectedTool >= 2 THEN selectedTool = selectedTool - 2
                    CASE %KEY_DOWN_ARROW ' Down Arrow  
                        IF selectedTool < %NUM_TOOLS - 2 THEN selectedTool = selectedTool + 2
                END SELECT
                
                ' Draw new selection highlight after moving
                iconX = %PREVIEW_X + (selectedTool MOD 2) * 20
                iconY = %PREVIEW_Y + ((%GRID_Y_MAX - %GRID_START_Y) / %GRID_Y_STEP) + 20 + (selectedTool \ 2) * 20
                DrawIcon iconX, iconY, toolIcons(selectedTool), %TRUE
            CASE 13 ' Enter
                EXIT DO
            CASE 27 ' ESC
                selectedTool = oldTool ' Revert to old tool
                EXIT DO
        END SELECT
    LOOP
    
    ' Tool selection complete - the DrawUI call will show the final selection
    LOCATE 1, 1: PRINT STRING$(79, " ")
END SUB

'******************************************************************************
'* FUNCTION: WaitForKey
'* Purpose: Waits for a key press and returns the key code.
'* Returns: (STRING) The key that was pressed.
'******************************************************************************
FUNCTION WaitForKey () AS STRING
    DIM currentKey AS STRING
    DO
        currentKey = INKEY$
    LOOP WHILE currentKey = ""
    WaitForKey = currentKey
END FUNCTION
