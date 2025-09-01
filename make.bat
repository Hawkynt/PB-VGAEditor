@ECHO OFF
SET LOGFILE=Make.log
VER >%LOGFILE%
DATE /D >>%LOGFILE%
TIME /D >>%LOGFILE%

IF EXIST UNITTEST.EXE GOTO ClearOldUnitTest
GOTO NoOldUnitTest
:ClearOldUnitTest
ECHO [Info] Deleting old Unit Test Executable
ECHO [Info] Deleting old Unit Test Executable >>%LOGFILE%
DEL UNITTEST.EXE
DEL UNITTEST.LOG
:NoOldUnitTest

FOR %%A IN (*.BAS) DO PBC.EXE -FNPX -G386 -ODV -OZF+ -CE -ES -EB -LB -LG %%A>>%LOGFILE%

ECHO [Info] Compilation Log:
TYPE %LOGFILE%

IF EXIST UNITTEST.EXE GOTO RunUnitTest
GOTO End
:RunUnitTest
ECHO [Info] Found Unit Test Executable
ECHO [Info] Found Unit Test Executable >>%LOGFILE%
UNITTEST.EXE >>%LOGFILE%
TYPE UNITTEST.LOG
TYPE UNITTEST.LOG >>%LOGFILE%

:End