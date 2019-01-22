set WORKDIR=%cd%\bin
set ENGINEPATH=%cd%\engine\debug\Engine317.exe
start %ENGINEPATH% -workdir %WORKDIR%  -id editor_debug -app_name editor_debug -console
