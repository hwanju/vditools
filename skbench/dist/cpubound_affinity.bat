set a=0 
cd c:\ 

:LOOP 

start /affinity %2 cpubound.exe 
set /a a+=1 
if %a% geq %1 goto QUIT 

goto LOOP 

:QUIT
