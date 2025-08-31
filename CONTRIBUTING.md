# Contributing New File Formats

This guide explains how to add new file format support to the PB-VGAEditor sprite editor. Follow these conventions to ensure consistency and compatibility with the existing codebase.

## File Structure

Each format should be implemented as a separate `.SUB` file:
- **Filename**: `FILE_<EXT>.SUB` (e.g., `FILE_PNG.SUB`, `FILE_WBP.SUB`), due to DOS limitations, extension must not be longer than 3 characters
- **Namespace**: Use format prefix for all functions (e.g., `FilePng_`, `FileBmp_`)

## Required Functions

Each format module must implement exactly two functions:

```basic
SUB File<Format>_Write (fullPath AS STRING, errorMessage AS STRING)
SUB File<Format>_Read (fullPath AS STRING, errorMessage AS STRING)
```

Parameters are passed by reference implicitly.

### Function Signatures
- **Parameters**: `fullPath` for file location, `errorMessage` for error reporting
- **Global Access**: Use `currentSprite` and `currentCanvas()` shared variables
- **Error Handling**: Set `errorMessage` to non-empty string on failure, empty string on success

## Data Type Guidelines

### Use Proper Types for Binary Data
```basic
' GOOD: Use appropriate primitive types
DIM header AS DWORD
DIM width AS WORD
DIM colorValue AS BYTE

' BAD: Avoid string manipulation for binary data (non-text data)
DIM header AS STRING * 4
```

### Avoid String Conversion Functions
```basic
' GOOD: Direct binary operations
GET #fileNum, , byteValue
pixelIndex = byteValue AND 15

' BAD: Unnecessary string conversions
GET #fileNum, , byteString
pixelIndex = ASC(byteString) AND 15
```

### Define TYPE Structures
```basic
TYPE PngHeader
    signature AS STRING * 8
    chunkLength AS DWORD 
    chunkType AS STRING * 4
END TYPE

TYPE BitmapFileHeader
    bfType AS WORD
    bfSize AS DWORD
    bfOffBits AS DWORD
END TYPE
```

## Constants Over Magic Numbers

```basic
' GOOD: Define meaningful constants
%PNG_SIGNATURE = &H89504E47
%IHDR_CHUNK = &H49484452
%COMPRESSION_NONE = 0
%COLOR_TYPE_PALETTE = 3

' BAD: Magic numbers in code
IF chunkType = &H49484452 THEN ' What does this mean?
```

## Writing Functions

### Template Structure

```basic
SUB File<Format>_Write (fullPath AS STRING, errorMessage AS STRING)
    errorMessage = ""

    ' Check if there is anything to save
    IF currentSprite.boundingBoxX2 = -1 THEN EXIT SUB

    ' Calculate sprite dimensions from bounding box
    DIM spriteWidth AS INTEGER  : spriteWidth = currentSprite.boundingBoxX2 - currentSprite.boundingBoxX1 + 1
    DIM spriteHeight AS INTEGER : spriteHeight = currentSprite.boundingBoxY2 - currentSprite.boundingBoxY1 + 1

    DIM fileNum AS INTEGER : fileNum = FREEFILE
    OPEN fullPath FOR BINARY AS #fileNum

        ' Write header
        ' Write image data from bounding box area only
        DIM x AS DWORD, y AS DWORD
        FOR y = currentSprite.boundingBoxY1 TO currentSprite.boundingBoxY2
            FOR x = currentSprite.boundingBoxX1 TO currentSprite.boundingBoxX2
                ' Write currentCanvas(x, y) data
            NEXT
        NEXT

    CLOSE #fileNum
END SUB
```

### Key Requirements

- **Bounding Box**: Only save the sprite's bounding box region, not the entire canvas
- **Error Handling**: Set `errorMessage` on any failure
- **File Handles**: Always use `FREEFILE` and properly close files
- **Data Source**: Read pixel data from `currentCanvas(x, y)`

## Reading Functions

### Template Structure

```basic
SUB File<Format>_Read (fullPath AS STRING, errorMessage AS STRING)
    errorMessage = ""

    DIM fileNum AS INTEGER : fileNum = FREEFILE
    ON ERROR RESUME NEXT
        OPEN fullPath FOR BINARY AS #fileNum
        IF ERR <> 0 THEN
            errorMessage = "Cannot open file: " + fullPath
            ERRCLEAR : ON ERROR GOTO 0
            EXIT SUB
        END IF
    ON ERROR GOTO 0
        
        ' Read and validate header
        ' Parse image dimensions
        DIM imageWidth AS DWORD
        DIM imageHeight AS DWORD
        
        ' Read image data to (0,0) origin in currentCanvas
        DIM x AS DWORD, y AS DWORD
        FOR y = 0 TO imageHeight - 1
            FOR x = 0 TO imageWidth - 1
            ' Set currentCanvas(x, y) = pixelValue (0-15 for VGA colors)
            NEXT
        NEXT

    CLOSE #fileNum
    
    currentSprite.boundingBoxX1 = 0
    currentSprite.boundingBoxY1 = 0  
    currentSprite.boundingBoxX2 = imageWidth - 1
    currentSprite.boundingBoxY2 = imageHeight - 1
END SUB
```

### Key Requirements

- **Origin Mapping**: Always load image data starting at canvas position (0,0)
- **Bounds Checking**: Ensure coordinates don't exceed `currentSprite.spriteWidth/Height` once, not inside loops
- **Color Mapping**: Convert external colors to VGA 4-bit palette (0-15)
- **Bounding Box Update**: MUST set `currentSprite.boundingBoxX1/Y1/X2/Y2` after successful read
- **Error Handling**: Use `ON ERROR RESUME NEXT` for file operations

## Color Palette Mapping

The editor uses a standard 16-color VGA palette:

|ID|Name|Code|
|--|----|----|
|0|Black|#000000|
|1|Blue|#0000AA|
|2|Green|#00AA00|
|3|Cyan|#00AAAA|
|4|Red|#AA0000|
|5|Magenta|#AA00AA|
|6|Brown|#AA5500|
|7|LightGray|#AAAAAA|
|8|DarkGray|#555555|
|9|LightBlue|#5555FF|
|10|LightGreen|#55FF55|
|11|LightCyan|#55FFFF|
|12|LightRed|#FF5555|
|13|LightMagenta|#FF55FF|
|14|Yellow|#FFFF00|
|15|White|#FFFFFF|

Map external color formats to this palette as appropriate for your format.

## Integration Steps

### 1. Update Main Test File

Add your format to the comprehensive test in `FileFormatRoundtrip.tst`:

```basic
' Add to WriteFormat function
ELSEIF formatName = "PNG" THEN
    CALL FilePng_Write(fileName, errorMessage)

' Add to ReadFormat function  
ELSEIF formatName = "PNG" THEN
    CALL FilePng_Read(fileName, errorMessage)

' Add include directive
$INCLUDE "FILE_PNG.SUB"

' Add test call
CALL TestFormat("PNG", "RTTEST.PNG")
```

### 2. Update Main Application

Add format support to the main `VGAMAUS.BAS` file by including your module and adding menu/export options.

## Testing Requirements

### Comprehensive Testing

1. **Copy Test Template**: Use `FileFormatRoundtrip.tst` as your testing base
2. **Create Unit Test**: Write `UNITTEST.BAS` with your format-specific tests
3. **Run Tests**: Execute via `MAKE.BAT` inside DOSBox or a DOS machine
4. **Verify Results**: Check `MAKE.LOG` for detailed results

### Success Criteria

- **Write Test**: File created successfully, readable by external tools
- **Read Test**: File parsed without errors
- **Round-Trip Test**: Original data matches loaded data exactly ("PERFECT MATCH")
- **External Compatibility**: Generated files should be readable by standard image viewers

### Test Pattern

The test system uses an 11x11 pixel test pattern with:

- White border (color 15)
- Diagonal line (color 8)
- Specific corner colors for verification (colors 1,2,3,4,5,14)
- White center pixel (color 15)

Your format must preserve all these colors accurately in the round-trip test.

## Quality Standards

- **No Magic Numbers**: All numeric constants should be named
- **Error Recovery**: Handle all possible file format errors gracefully
- **Memory Safety**: Proper bounds checking on all array access
- **File Safety**: Always close file handles, even on error paths
- **Documentation**: Clear comments explaining file format specifics

Following these guidelines will ensure your format integrates seamlessly with the existing codebase and maintains the high quality standards of the PB-VGAEditor project.
