set IP_HOST=115.145.212.176
set END_PORT=10002

:while

if exist c:\end goto wend

choice /t 3 /d n > nul

goto while

:wend 

del c:\end

nc %IP_HOST% %END_PORT% 
