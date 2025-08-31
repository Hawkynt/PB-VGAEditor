' VGAMAUS.BAS - Main Application File
' Acts as the View/Controller, binding all modules together.

' --- Constants ---
%TRUE = -1
%FALSE = 0

' Key Codes
%KEY_ESC = 27
%KEY_ENTER = 13
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

TYPE FileFormat
    keyChar AS STRING * 1
    extension AS STRING * 3
    displayName AS STRING * 10
    readFunction AS DWORD
    writeFunction AS DWORD
END TYPE

$INCLUDE "ICONS.SUB"

' Global format registry - shared array (will be redimensioned dynamically)
DIM formatRegistry(0) AS SHARED FileFormat

' Shared variables for method pointer workaround (arrays can't be passed to method pointers)
DIM currentSprite AS SHARED Sprite
DIM currentCanvas(1, 1) AS SHARED BYTE

' Initialize shared variables before use (canvas will be dimensioned in InitializeSprite)
currentSprite.spriteWidth = (%GRID_X_MAX / %GRID_X_STEP)
currentSprite.spriteHeight = (%GRID_Y_MAX - %GRID_START_Y) / %GRID_Y_STEP
currentSprite.boundingBoxX1 = -1
currentSprite.boundingBoxY1 = -1
currentSprite.boundingBoxX2 = -1
currentSprite.boundingBoxY2 = -1

$INCLUDE "SPRITE.SUB"

$INCLUDE "FILE_VGA.SUB"
$INCLUDE "FILE_BAS.SUB"
$INCLUDE "FILE_BMP.SUB"
$INCLUDE "FILE_PCX.SUB"
$INCLUDE "FILE_ICO.SUB"
$INCLUDE "FILE_XPM.SUB"
$INCLUDE "FILE_GIF.SUB"
$INCLUDE "FILE_TIF.SUB"
$INCLUDE "FILE_TGA.SUB"

$INCLUDE "MOUSE.SUB"
DIM mouse AS MouseInfo
$INCLUDE "PREVIEW.SUB"
$INCLUDE "INTRO.SUB"

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

'******************************************************************************
'* FUNCTION: GenerateKeyFromExtension
'* Purpose: Auto-generate unique single-letter key from file extension.
'* Parameters:
'*   extension (BYVAL STRING): File extension without dot (e.g., "VGA", "BMP").
'* Returns: (STRING) Single character key, trying first letter, then second, etc.
'******************************************************************************
FUNCTION GenerateKeyFromExtension (BYVAL extension AS STRING) AS STRING
    DIM i AS INTEGER
    DIM candidate AS STRING
    DIM j AS INTEGER
    DIM maxFormats AS INTEGER
    DIM isUsed AS INTEGER
    
    ' Try each character in the extension
    FOR i = 1 TO LEN(extension)
        candidate = UCASE$(MID$(extension, i, 1))
        isUsed = %FALSE
        
        ' Check if this character is already used
        ON ERROR RESUME NEXT
        maxFormats = UBOUND(formatRegistry)
        IF ERR = 0 THEN
            FOR j = 1 TO maxFormats
                IF formatRegistry(j).keyChar = candidate THEN
                    isUsed = %TRUE
                    EXIT FOR
                END IF
            NEXT j
        END IF
        ERRCLEAR
        ON ERROR GOTO 0
        
        ' If not used, return this character
        IF isUsed = %FALSE THEN
            GenerateKeyFromExtension = candidate
            EXIT FUNCTION
        END IF
    NEXT i
    
    ' If all characters are used, return the first character (fallback)
    GenerateKeyFromExtension = UCASE$(LEFT$(extension, 1))
END FUNCTION

'******************************************************************************
'* SUB: AddFormat
'* Purpose: Add a format to the registry (automatically expands array).
'* Parameters:
'*   extension (BYVAL STRING): File extension without dot.
'*   reader (BYVAL DWORD): Pointer to read function.
'*   writer (BYVAL DWORD): Pointer to write function.
'******************************************************************************
SUB AddFormat (BYVAL extension AS STRING, BYVAL readPtr AS DWORD, BYVAL writePtr AS DWORD)
    DIM currentCount AS INTEGER
    DIM newIndex AS INTEGER
    DIM keyChar AS STRING
    DIM displayName AS STRING
    
    ' Generate unique key from extension
    keyChar = GenerateKeyFromExtension(extension)
    
    ' Create display name with key highlighted (e.g., "[V]GA", "BM[P]")
    DIM keyPos AS INTEGER
    keyPos = INSTR(UCASE$(extension), keyChar)
    IF keyPos > 0 THEN
        displayName = LEFT$(extension, keyPos - 1) + "[" + keyChar + "]" + MID$(extension, keyPos + 1)
    ELSE
        displayName = "[" + keyChar + "] " + extension
    END IF
    
    ' Get current array size (0 if not yet dimensioned)
    ON ERROR RESUME NEXT
    currentCount = UBOUND(formatRegistry)
    IF ERR <> 0 THEN
        currentCount = 0
        ERRCLEAR
    END IF
    ON ERROR GOTO 0
    
    ' Expand array to hold one more format
    newIndex = currentCount + 1
    REDIM PRESERVE formatRegistry(newIndex)
    
    ' Store the format data
    formatRegistry(newIndex).keyChar = keyChar
    formatRegistry(newIndex).extension = extension
    formatRegistry(newIndex).displayName = displayName
    formatRegistry(newIndex).readFunction = readPtr
    formatRegistry(newIndex).writeFunction = writePtr
END SUB

'******************************************************************************
'* SUB: InitializeFormatRegistry
'* Purpose: Initialize the file format registry with supported formats.
'******************************************************************************
SUB InitializeFormatRegistry
    ' Add each format with method pointers - keys and display names auto-generated
    AddFormat "VGA", CODEPTR32(FileVga_Read), CODEPTR32(FileVga_Write)
    AddFormat "BAS", CODEPTR32(FileBas_Read), CODEPTR32(FileBas_Write)
    AddFormat "PCX", CODEPTR32(FilePcx_Read), CODEPTR32(FilePcx_Write)
    AddFormat "BMP", CODEPTR32(FileBmp_Read), CODEPTR32(FileBmp_Write)
    AddFormat "ICO", CODEPTR32(FileIco_Read), CODEPTR32(FileIco_Write)
    AddFormat "XPM", CODEPTR32(FileXpm_Read), CODEPTR32(FileXpm_Write)
    AddFormat "TGA", CODEPTR32(FileTga_Read), CODEPTR32(FileTga_Write)
    AddFormat "TIF", CODEPTR32(FileTif_Read), CODEPTR32(FileTif_Write)
    'AddFormat "GIF", CODEPTR32(FileGif_Read), CODEPTR32(FileGif_Write)
END SUB

'******************************************************************************
'* FUNCTION: BuildFormatPrompt
'* Purpose: Build the format prompt string from the registry.
'* Returns: (STRING) The prompt string like "[V]GA, [B]AS, [P]CX, ..."
'******************************************************************************
FUNCTION BuildFormatPrompt AS STRING
    DIM prompt AS STRING
    DIM i AS INTEGER
    DIM maxFormats AS INTEGER
    
    maxFormats = UBOUND(formatRegistry)
    FOR i = 1 TO maxFormats
        IF i > 1 THEN prompt = prompt + ", "
        prompt = prompt + RTRIM$(formatRegistry(i).displayName)
    NEXT i
    prompt = prompt + ": "
    BuildFormatPrompt = prompt
END FUNCTION

'******************************************************************************
'* FUNCTION: FindFormatByKey
'* Purpose: Find format index by key character (case insensitive).
'* Parameters:
'*   keyChar (BYVAL STRING): The key character to search for.
'* Returns: (INTEGER) Array index or 0 if not found.
'******************************************************************************
FUNCTION FindFormatByKey (BYVAL keyChar AS STRING) AS INTEGER
    DIM i AS INTEGER
    DIM maxFormats AS INTEGER
    keyChar = UCASE$(keyChar)
    
    maxFormats = UBOUND(formatRegistry)
    FOR i = 1 TO maxFormats
        IF formatRegistry(i).keyChar = keyChar THEN
            FindFormatByKey = i
            EXIT FUNCTION
        END IF
    NEXT i
    FindFormatByKey = 0
END FUNCTION

'******************************************************************************
'* SUB: CallFormatRead
'* Purpose: Method pointer-based format dispatcher for read operations.
'* Parameters:
'*   formatID (BYVAL INTEGER): Index into formatRegistry array.
'*   fullPath (BYVAL STRING): The full file path.
'*   errorMessage (AS STRING): Error message output parameter.
'******************************************************************************
SUB CallFormatRead (BYVAL formatID AS INTEGER, BYVAL fullPath AS STRING, errorMessage AS STRING)
    DIM maxFormats AS INTEGER
    DIM readPtr AS DWORD
    
    ' Validate format ID
    maxFormats = UBOUND(formatRegistry)
    IF formatID < 1 OR formatID > maxFormats THEN
        errorMessage = "Invalid format ID: " + STR$(formatID)
        EXIT SUB
    END IF
    
    ' Get function pointer and call dynamically with explicit fallbacks
    readPtr = formatRegistry(formatID).readFunction
    IF readPtr <> 0 THEN
        IF readPtr = CODEPTR32(FileVga_Read) THEN 
            CALL FileVga_Read(fullPath, errorMessage)
        ELSEIF readPtr = CODEPTR32(FileBas_Read) THEN
            CALL FileBas_Read(fullPath, errorMessage)
        ELSEIF readPtr = CODEPTR32(FilePcx_Read) THEN
            CALL FilePcx_Read(fullPath, errorMessage)
        ELSEIF readPtr = CODEPTR32(FileBmp_Read) THEN
            CALL FileBmp_Read(fullPath, errorMessage)
        ELSEIF readPtr = CODEPTR32(FileIco_Read) THEN
            CALL FileIco_Read(fullPath, errorMessage)
        ELSEIF readPtr = CODEPTR32(FileXpm_Read) THEN
            CALL FileXpm_Read(fullPath, errorMessage)
        ELSEIF readPtr = CODEPTR32(FileTga_Read) THEN
            CALL FileTga_Read(fullPath, errorMessage)
        ELSE
            ' Fallback for any future formats
            'CALL DWORD readPtr BDECL (fullPath, errorMessage)
            errorMessage = "No read function for format: " + formatRegistry(formatID).extension
        END IF
    ELSE
        errorMessage = "No read function for format: " + formatRegistry(formatID).extension
    END IF
END SUB

'******************************************************************************
'* SUB: CallFormatWrite
'* Purpose: Method pointer-based format dispatcher for write operations.
'* Parameters:
'*   formatID (BYVAL INTEGER): Index into formatRegistry array.
'*   fullPath (BYVAL STRING): The full file path.
'*   errorMessage (AS STRING): Error message output parameter.
'******************************************************************************
SUB CallFormatWrite (BYVAL formatID AS INTEGER, BYVAL fullPath AS STRING, errorMessage AS STRING)
    DIM maxFormats AS INTEGER
    DIM writePtr AS DWORD
    
    ' Validate format ID
    maxFormats = UBOUND(formatRegistry)
    IF formatID < 1 OR formatID > maxFormats THEN
        errorMessage = "Invalid format ID: " + STR$(formatID)
        EXIT SUB
    END IF
    
    ' Get function pointer and call dynamically with explicit fallbacks
    writePtr = formatRegistry(formatID).writeFunction
    IF writePtr <> 0 THEN
        IF writePtr = CODEPTR32(FileVga_Write) THEN
            CALL FileVga_Write(fullPath, errorMessage)
        ELSEIF writePtr = CODEPTR32(FileBas_Write) THEN
            CALL FileBas_Write(fullPath, errorMessage)
        ELSEIF writePtr = CODEPTR32(FilePcx_Write) THEN
            CALL FilePcx_Write(fullPath, errorMessage)
        ELSEIF writePtr = CODEPTR32(FileBmp_Write) THEN
            CALL FileBmp_Write(fullPath, errorMessage)
        ELSEIF writePtr = CODEPTR32(FileIco_Write) THEN
            CALL FileIco_Write(fullPath, errorMessage)
        ELSEIF writePtr = CODEPTR32(FileXpm_Write) THEN
            CALL FileXpm_Write(fullPath, errorMessage)
        ELSEIF writePtr = CODEPTR32(FileTga_Write) THEN
            CALL FileTga_Write(fullPath, errorMessage)
        ELSE
            ' Fallback for any future formats
            CALL DWORD writePtr BDECL (fullPath, errorMessage)
        END IF
    ELSE
        errorMessage = "No write function for format: " + formatRegistry(formatID).extension
    END IF
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
SUB HandleMouseInput (mouse AS MouseInfo, BYVAL drawingColor AS INTEGER, isLineMode AS INTEGER, isSaved AS INTEGER, BYVAL selectedTool AS INTEGER, BYVAL currentFileName AS STRING, toolIcons() AS STRING)
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

    IF canvasX < 0 OR canvasX > currentSprite.spriteWidth OR canvasY < 0 OR canvasY > currentSprite.spriteHeight THEN EXIT SUB

    colorToUse = -1
    IF mouse.button = 1 THEN colorToUse = drawingColor
    IF mouse.button = 2 THEN colorToUse = 0

    SELECT CASE selectedTool
        CASE %TOOL_DRAW
            IF colorToUse <> -1 THEN
                IF currentCanvas(canvasX, canvasY) <> colorToUse THEN
                    currentCanvas(canvasX, canvasY) = colorToUse
                    isSaved = %FALSE
                    ' Incremental bounding box update instead of full scan
                    IF colorToUse <> 0 THEN  ' Non-transparent pixel
                        IF currentSprite.boundingBoxX2 = -1 THEN  ' Empty sprite, initialize
                            currentSprite.boundingBoxX1 = canvasX
                            currentSprite.boundingBoxY1 = canvasY
                            currentSprite.boundingBoxX2 = canvasX
                            currentSprite.boundingBoxY2 = canvasY
                        ELSE
                            IF canvasX < currentSprite.boundingBoxX1 THEN currentSprite.boundingBoxX1 = canvasX
                            IF canvasY < currentSprite.boundingBoxY1 THEN currentSprite.boundingBoxY1 = canvasY  
                            IF canvasX > currentSprite.boundingBoxX2 THEN currentSprite.boundingBoxX2 = canvasX
                            IF canvasY > currentSprite.boundingBoxY2 THEN currentSprite.boundingBoxY2 = canvasY
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
                        DrawRectangle currentSprite, currentCanvas(), firstClickX, firstClickY, canvasX, canvasY, drawingColor
                    CASE %TOOL_FILLED_RECTANGLE: 
                        ClearFilledRectanglePreview firstClickX, firstClickY, lastPreviewX, lastPreviewY
                        DrawFilledRectangle currentSprite, currentCanvas(), firstClickX, firstClickY, canvasX, canvasY, drawingColor
                    CASE %TOOL_CIRCLE: 
                        DrawCircle currentSprite, currentCanvas(), firstClickX, firstClickY, INT(SQR((canvasX - firstClickX)^2 + (canvasY - firstClickY)^2)), drawingColor
                    CASE %TOOL_FILLED_CIRCLE: 
                        DrawFilledCircle currentSprite, currentCanvas(), firstClickX, firstClickY, INT(SQR((canvasX - firstClickX)^2 + (canvasY - firstClickY)^2)), drawingColor
                END SELECT
                RenderCanvas currentSprite, currentCanvas()
                DrawUI drawingColor, currentFileName, currentSprite, selectedTool, toolIcons()
                isSaved = %FALSE
                isFirstClick = %FALSE
            END IF
    END SELECT
END SUB

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
SUB HandleNewFile (isSaved AS INTEGER, isLineMode AS INTEGER, currentFileName AS STRING)
    IF CheckUnsavedChanges(isSaved) = %FALSE THEN EXIT SUB
    isSaved = %TRUE
    isLineMode = %FALSE
    currentFileName = "UNBENANNT"
    ClearCanvas currentSprite, currentCanvas()
    RenderCanvas currentSprite, currentCanvas()
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
            CASE %KEY_ENTER
                drawColor = (selectedColorY * %COLOR_GRID_COLS) + selectedColorX
                EXIT DO
            CASE %KEY_ESC
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
SUB HandleLoadFile (isSaved AS INTEGER, currentFileName AS STRING)
    IF CheckUnsavedChanges(isSaved) = %FALSE THEN EXIT SUB

    COLOR 15
    DIM path AS STRING
    LOCATE 1, 1: INPUT "Path (if needed): ", path
    LOCATE 1, 1: PRINT STRING$(79, 32)
    IF path <> "" THEN path = path + "\"
    DIM fileName AS STRING
    LOCATE 1, 1: INPUT "File-Name: ", fileName
    LOCATE 1, 1: PRINT STRING$(79, 32)
    LOCATE 1, 1: PRINT BuildFormatPrompt()
    DIM fileType AS STRING * 1
    fileType = INPUT$(1)
    LOCATE 1, 1: PRINT STRING$(79, 32)
    
    currentFileName = fileName
    ClearCanvas currentSprite, currentCanvas()

    DIM errorMessage AS STRING
    DIM formatID AS INTEGER
    formatID = FindFormatByKey(fileType)
    IF formatID > 0 THEN
      DIM fullPath AS STRING
      fullPath = path + LEFT$(fileName, 8) + "." + formatRegistry(formatID).extension
      
      CallFormatRead formatID, fullPath, errorMessage
    ELSE
        errorMessage = "Unknown file format: " + fileType
    END IF

    IF errorMessage <> "" THEN
        LOCATE 1, 1: COLOR 4: PRINT "Error: " + errorMessage: BEEP
        SLEEP 2
        LOCATE 1, 1: PRINT STRING$(79, " ")
    END IF

    ' Bounding box already updated by format reader
    RenderCanvas currentSprite, currentCanvas()
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
SUB HandleSaveFile (currentFileName AS STRING, isSaved AS INTEGER)
    COLOR 15
    DIM path AS STRING
    LOCATE 1, 1: INPUT "Path (if needed): ", path
    LOCATE 1, 1: PRINT STRING$(79, 32)
    IF path <> "" THEN path = path + "\"
    DIM fileName AS STRING
    LOCATE 1, 1: INPUT "File-Name: ", fileName
    LOCATE 1, 1: PRINT STRING$(79, 32)
    LOCATE 1, 1: PRINT BuildFormatPrompt()
    DIM fileType AS STRING * 1
    fileType = INPUT$(1)
    LOCATE 1, 1: PRINT STRING$(79, 32)
    
    currentFileName = fileName
    
    DIM errorMessage AS STRING
    DIM formatID AS INTEGER
    formatID = FindFormatByKey(fileType)
    IF formatID > 0 THEN
      DIM fullPath AS STRING
      fullPath = path + LEFT$(fileName, 8) + "." + formatRegistry(formatID).extension
      
      CallFormatWrite formatID, fullPath, errorMessage
    ELSE
        errorMessage = "Unknown file format: " + fileType
    END IF

    IF errorMessage <> "" THEN
        LOCATE 1, 1: COLOR 4: PRINT "Error: " + errorMessage: BEEP
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
            CASE %KEY_ENTER
                EXIT DO
            CASE %KEY_ESC
                selectedTool = oldTool ' Revert to old tool
                EXIT DO
        END SELECT
    LOOP
    
    ' Tool selection complete - the DrawUI call will show the final selection
    LOCATE 1, 1: PRINT STRING$(79, " ")
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
FUNCTION HandleKeyboardInput (drawingColor AS INTEGER, isLineMode AS INTEGER, isSaved AS INTEGER, currentFileName AS STRING, selectedTool AS INTEGER) AS INTEGER
    DIM inputKey AS STRING
    DIM keyCode AS INTEGER
    HandleKeyboardInput = %FALSE
    inputKey = INKEY$
    IF inputKey = "" THEN EXIT FUNCTION
    keyCode = ASC(inputKey)
    IF LEN(inputKey) > 1 THEN keyCode = ASC(RIGHT$(inputKey, 1))

    SELECT CASE keyCode
        CASE %KEY_N: HandleNewFile isSaved, isLineMode, currentFileName: HandleKeyboardInput = %TRUE
        CASE %KEY_C: HandleChangeColor drawingColor: HandleKeyboardInput = %TRUE
        CASE %KEY_L: HandleLoadFile isSaved, currentFileName: HandleKeyboardInput = %TRUE
        CASE %KEY_S: HandleSaveFile currentFileName, isSaved
        CASE %KEY_INSERT: isLineMode = NOT isLineMode
        CASE %KEY_T: HandleToolSelection selectedTool: HandleKeyboardInput = %TRUE
        CASE %KEY_ESC: HandleExit isSaved
        CASE 0 ' Extended key
            SELECT CASE keyCode
                CASE %KEY_LEFT_ARROW: IF selectedTool = %TOOL_MOVE_LEFT THEN MovePixelsLeft currentSprite, currentCanvas(): isSaved = %FALSE
                CASE %KEY_RIGHT_ARROW: IF selectedTool = %TOOL_MOVE_RIGHT THEN MovePixelsRight currentSprite, currentCanvas(): isSaved = %FALSE
                CASE %KEY_UP_ARROW: IF selectedTool = %TOOL_MOVE_UP THEN MovePixelsUp currentSprite, currentCanvas(): isSaved = %FALSE
                CASE %KEY_DOWN_ARROW: IF selectedTool = %TOOL_MOVE_DOWN THEN MovePixelsDown currentSprite, currentCanvas(): isSaved = %FALSE
            END SELECT
    END SELECT
END FUNCTION

'******************************************************************************
'* SUB: MainEditorLoop
'* Purpose: The main event loop for the sprite editor.
'* Parameters: None
'******************************************************************************
SUB MainEditorLoop
    DIM mouse AS MouseInfo
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

    InitializeSprite currentSprite, currentCanvas()
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
    DrawUI drawingColor, currentFileName, currentSprite, selectedTool, toolIcons()
    
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

        HandleMouseInput mouse, drawingColor, isLineMode, isSaved, selectedTool, currentFileName, toolIcons()
        IF HandleKeyboardInput(drawingColor, isLineMode, isSaved, currentFileName, selectedTool) = %TRUE THEN
            DrawUI drawingColor, currentFileName, currentSprite, selectedTool, toolIcons()
        END IF
    LOOP
END SUB

InitializeFormatRegistry
InitializeSystem mouse
ShowIntro
WaitForInput
MainEditorLoop
