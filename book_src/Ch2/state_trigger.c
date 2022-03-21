if ( c1 >= 5) 
trigger; 
else if ( ! condition1 ) 
increment c1; 
else if ( condition1 && c1 < 5 ) 
reset c1; 


state ST1: 
if ( condition1 && c1 > 0 && c1 < 5) 
trigger; 
else if ( ! condition1 && c1 < 6) 
increment c1; 
else if ( condition1 && c1 > 5 ) 
reset c1; 


state ST1: 
if ( c1 >= 5) 
trigger; 
else if ( condition1 ) 
increment c1; 

state ST1: 
if ( condition1 ) 
goto ST2; 
state ST2: 
if ( condition1 ) 
goto ST2; 
else if (condition2 ) 
trigger; 
else 
goto ST1;

state ST1: 
if ( condition1 ) 
goto ST2; 
state ST2: 
if ( condition1) 
goto ST2; 
else if ( ! condition2) 
increment c1; 
else if (condition2 && c1 <= 5) 
trigger; 
else if (condition2 && c1 > 5) 
goto ST1; 
