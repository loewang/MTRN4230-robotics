MODULE MTRN4230_Move_Sample
    
    PERS string errmsg; ! Error/Okay messages stored in string 
    PERS string ROBargs{8}; ! Stores movement commands received in Server_Sample
    PERS bool flag; ! Indicates a movement command has been copied into ROBargs
    PERS bool quit; ! Program keeps looping while quit is FALSE
    PERS speeddata sspeed; ! Speed variable which controls movement speed
    PERS string jointAngles; ! Contains current joint angles
    PERS string eePos; ! Contains current end effector position
    PERS string eeOri; ! Contains current end effector orientation 
    PERS bool motionCancel; ! Indicates whether the motion has been cancelled
    PERS bool inMotion; ! Indicates whether the robot is in motion
    VAR intnum cancel; ! Interrupt number connected to motionCancel
    VAR intnum execErr; ! Interrupt number connected to DO_EXEC_ERR
    
    PROC Initialise()
        motionCancel := FALSE; ! Set motionCancel to be initally FALSE
        !MotionSup \On; 
        
        ! Connect the cancelTrap routine which runs when motionCancel bool changes value
        CONNECT cancel WITH cancelTrap;
        IPers motionCancel, cancel;
        
        ! Connect the execErrTrap routine which runs when DO_EXEC_ERR has a value 1
        CONNECT execErr WITH execErrTrap;
        ISignalDO DO_EXEC_ERR, 1, execErr;
        
    ENDPROC
    
    PROC Main()
               
        Initialise;
        
        ReceiveCommandLoop; ! Main Loop

    ENDPROC
    
    PROC ReceiveCommandLoop()
        
        VAR bool ok; ! For StrToVal function
        VAR pos coord; ! Contains offset coordinates for movement relative to table and conveyor
        VAR robjoint pose; ! Contains desired angle for all six joints
        VAR jointtarget jtarg; ! Contains target joint angles
        VAR jointtarget jcurr; ! Contains current joint angles
        VAR num joint; ! Contains the joint number which will be jogged
        VAR num jogdir; ! Contains the jogging direction (pos/neg)
        VAR orient quat; ! Contains desired quaternion for reorienting the end effector
        VAR orient qcurr; ! Contains the current quaternion
        VAR robtarget rcurr; ! Contains the current robot properties
        VAR robtarget rtarg; ! Contains the target robot properties
        VAR num myerr; ! For catching axis errors
        VAR string outputMsg; ! For printing messages to the FlexPendant
        VAR num eulerAngles{3}; ! Stores the 3 Euler Angles found from converting the current orientation from quaternion      
        
        restart: ! Jumps back to this point if quit is FALSE
        
        jcurr := CJointT(); ! Obtain current joint angles
        jointAngles := ValToStr(jcurr.robax); ! Convert joint angles to string, ready to be sent to MATLAB
        rcurr := CRobT(); ! Obtain current robot properties
        eePos := ValToStr(rcurr.trans); ! Convert end effector position to string, ready to be sent to MATLAB
        
        ! Convert orientation from quaternion to Euler angles
        eulerAngles{1} := EulerZYX(\X, rcurr.rot);
        eulerAngles{2} := EulerZYX(\Y, rcurr.rot);
        eulerAngles{3} := EulerZYX(\Z, rcurr.rot);
        eeOri := ValToStr(eulerAngles); ! Convert end effector orientation to string, ready to be sent to MATLAB
        
        
        WaitUntil flag = TRUE; ! Wait here until a movement command has been receieved
            flag := FALSE; ! Set flag back to false once command has been received         

            ! Switch to determine which command was sent
            TEST ROBargs{1}
            
            CASE "MVPOSTAB": ! Move position relative to table
            
                ! Convert received string arguments to values
                ok := StrToVal(ROBargs{2}, coord.x);
                ok := StrToVal(ROBargs{3}, coord.y);
                ok := StrToVal(ROBargs{4}, coord.z);
                
                ! Calculate required joint angles to reach the offset coordinate position and check if it's reachable
                jtarg := CalcJointT(Offs(pTableHome, coord.x, coord.y, coord.z),tSCup \ErrorNumber:=myerr);
                
                ! If not feasible send error message to both MATLAB and FlexPendant
                IF myerr = ERR_ROBLIMIT THEN 
                    errmsg := "Robot Movement Limit";
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                ! Else perform the movement command and indicate that the movement is okay
                ELSE
                    outputMsg := ("Moving to: " + ValToStr(coord) + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Movement Okay";
                    
                    inMotion := TRUE;
                    MoveAbsJ jtarg,sspeed,fine,tSCup;
                    inMotion := FALSE;
                ENDIF
                

            CASE "MVPOSCON": ! Move position relative to conveyor
                ok := StrToVal(ROBargs{2}, coord.x);
                ok := StrToVal(ROBargs{3}, coord.y);
                ok := StrToVal(ROBargs{4}, coord.z);
                
                jtarg := CalcJointT(Offs(pConvHome, coord.x, coord.y, coord.z),tSCup \ErrorNumber:=myerr);
                IF myerr = ERR_ROBLIMIT THEN
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Robot Movement Limit";
                ELSE
                    errmsg := "Movement Okay";
                    outputMsg := ("Moving to: " + ValToStr(coord) + "\0A");
                    TPWrite outputMsg;   
                    
                    inMotion := TRUE;
                    MoveAbsJ jtarg,sspeed,fine,tSCup;
                    inMotion := FALSE;
                ENDIF
                
            CASE "SETPOSES": ! Set all joint angles 
                ok := StrToVal(ROBargs{2}, pose.rax_1);
                ok := StrToVal(ROBargs{3}, pose.rax_2);
                ok := StrToVal(ROBargs{4}, pose.rax_3);
                ok := StrToVal(ROBargs{5}, pose.rax_4);
                ok := StrToVal(ROBargs{6}, pose.rax_5);
                ok := StrToVal(ROBargs{7}, pose.rax_6);

                IF myerr = ERR_ROBLIMIT THEN 
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Robot Movement Limit";
                ELSE
                    jtarg.robax := pose;
                    jtarg.extax := [0, 9E9, 9E9, 9E9, 9E9, 9E9];
                                        
                    outputMsg := ("Setting axes angles to: " + ValToStr(pose) + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Movement Okay";
                    
                    inMotion := TRUE;
                    MoveAbsJ jtarg, sspeed, fine, tSCup;
                    inMotion := FALSE;

                    
                ENDIF       
                           
            CASE "JOGJOINT": ! Jog a joint
                ok := StrToVal(ROBargs{2}, joint);
                
                ! Set jogdir to a value relative to the set speed
                IF ROBargs{3} = "pos" THEN 
                    jogdir := sspeed.v_tcp/10;
                ELSE
                    jogdir := -sspeed.v_tcp/10;
                ENDIF
                    
                jcurr := CJointT(); ! Get current joint angles
                jtarg := jcurr; ! Set target joint angles to current joint angles
                
                ! Switch to determine which joint will be jogged
                TEST joint
                
                CASE 1:
                jtarg.robax.rax_1 := jcurr.robax.rax_1 + jogdir;
                
                CASE 2:
                jtarg.robax.rax_2 := jcurr.robax.rax_2 + jogdir;
                
                CASE 3:
                jtarg.robax.rax_3 := jcurr.robax.rax_3 + jogdir;
                
                CASE 4:
                jtarg.robax.rax_4 := jcurr.robax.rax_4 + jogdir;
                
                CASE 5:
                jtarg.robax.rax_5 := jcurr.robax.rax_5 + jogdir;
                
                CASE 6:
                jtarg.robax.rax_6 := jcurr.robax.rax_6 + jogdir;
                                
                ENDTEST
                
                ! Make sure none of the joints are jogged beyond their angle limits
                IF abs(jtarg.robax.rax_1) > 165 THEN
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Robot Movement Limit";
                ELSEIF abs(jtarg.robax.rax_2) > 110 THEN
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Robot Movement Limit";
                ELSEIF jtarg.robax.rax_3 > 70 OR jtarg.robax.rax_3 < -110 THEN
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Robot Movement Limit";
                ELSEIF abs(jtarg.robax.rax_4) > 160 THEN
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Robot Movement Limit";
                ELSEIF abs(jtarg.robax.rax_5) > 120 THEN
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Robot Movement Limit";
                ELSEIF abs(jtarg.robax.rax_1) > 400 THEN
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Robot Movement Limit";
                ELSE
                    outputMsg := ("Jogging joint " + ValToStr(joint) + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Movement Okay";
                    
                    inMotion := TRUE;
                    MoveAbsJ jtarg, sspeed, fine, tSCup;
                    inMotion := FALSE;       

                ENDIF
                
            CASE "EEORIENT": ! Orient the end effector according to a desired quaternion
                ok := StrToVal(ROBargs{2}, quat.q1);
                ok := StrToVal(ROBargs{3}, quat.q2);
                ok := StrToVal(ROBargs{4}, quat.q3);
                ok := StrToVal(ROBargs{5}, quat.q4);
                
                quat := NOrient(quat); ! Normalise the quaternion in case it doesn't quite add up to 1
                
                rcurr := CRobT(); ! Get current robot properties
                rtarg := rcurr; ! Set target robot properties to current robot properties 
                rtarg.rot := quat; ! Set target quaternion 
                
                sspeed.v_ori := sspeed.v_tcp; ! Set orientation speed to be the same as end effector speed
                
                ! Calculate required joint angles to reach the offset coordinate position and check if it's reachable
                jtarg := CalcJointT(rtarg,tSCup \ErrorNumber:=myerr);
                
                ! Make sure each joint is not exceeding its angle limit
                IF abs(jtarg.robax.rax_1) > 165 THEN
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Robot Movement Limit";
                ELSEIF abs(jtarg.robax.rax_2) > 110 THEN
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Robot Movement Limit";
                ELSEIF jtarg.robax.rax_3 > 70 OR jtarg.robax.rax_3 < -110 THEN
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Robot Movement Limit";
                ELSEIF abs(jtarg.robax.rax_4) > 160 THEN
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Robot Movement Limit";
                ELSEIF abs(jtarg.robax.rax_5) > 120 THEN
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Robot Movement Limit";
                ELSEIF abs(jtarg.robax.rax_1) > 400 THEN
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Robot Movement Limit";
                ELSE
                    outputMsg := ("Orienting end effector to: " + ValToStr(quat) + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Movement Okay";
                    
                    inMotion := TRUE;
                    MoveL rtarg,sspeed,fine,tSCup;
                    inMotion := FALSE;  
                
                ENDIF
                
            CASE "LINMDBAS": ! Linear mode relative to base frame
                rcurr := CRobT(); ! Get current robot properties
                rtarg := rcurr; ! Set target robot properties to current robot properties
                
                ! Set jogdir relative to set speed
                IF ROBargs{3} = "pos" THEN
                    jogdir := sspeed.v_tcp/10;
                ELSE
                    jogdir := -sspeed.v_tcp/10;
                ENDIF
                
                ! Switch to determine which direction the linear movement is in
                TEST ROBargs{2}
                
                CASE "X":
                    rtarg.trans.x := rcurr.trans.x + jogdir;
                
                CASE "Y":
                    rtarg.trans.y := rcurr.trans.y + jogdir;
                    
                CASE "Z":
                    rtarg.trans.z := rcurr.trans.z + jogdir;
                ENDTEST
                
                ! Calculate required joint angles to reach the offset coordinate position and check if it's reachable
                jtarg := CalcJointT(rtarg,tSCup \ErrorNumber:=myerr);
                
                IF myerr = ERR_ROBLIMIT THEN
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Robot Movement Limit";
                ELSE
                    outputMsg := ("Linear mode, rel. base, axis " + ROBargs{2} + " in the " + ROBargs{3} + " direction" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Movement Okay";
                    
                    inMotion := TRUE;
                    MoveL rtarg,sspeed,fine,tSCup;
                    inMotion := FALSE;
                ENDIF
            
            CASE "LINMDEND": ! Linear mode relative to end effector frame
                rcurr := CRobT(); ! Get current robot properties
                
                ! Set jogdir relative to set speed
                IF ROBargs{3} = "pos" THEN
                    jogdir := sspeed.v_tcp/10;
                ELSE
                    jogdir := -sspeed.v_tcp/10;
                ENDIF
                
                ! Switch to determine which direction the linear movement is in
                TEST ROBargs{2}
                
                CASE "X":
                        rtarg := RelTool(rcurr,jogdir,0,0);
                
                CASE "Y":
                        rtarg := RelTool(rcurr,0,jogdir,0);
                    
                CASE "Z":
                        rtarg := RelTool(rcurr,0,0,jogdir);
                    
                ENDTEST
                
                ! Calculate required joint angles to reach the offset coordinate position and check if it's reachable
                jtarg := CalcJointT(rtarg,tSCup \ErrorNumber:=myerr);
                
                IF myerr = ERR_ROBLIMIT THEN
                    outputMsg := ("Robot Movement Limit" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Robot Movement Limit";
                ELSE
                    outputMsg := ("Linear mode, rel. EE, axis " + ROBargs{2} + " in the " + ROBargs{3} + " direction" + "\0A");
                    TPWrite outputMsg;
                    errmsg := "Movement Okay";
                    
                    inMotion := TRUE;
                    MoveL rtarg,sspeed,fine,tSCup;
                    inMotion := FALSE;
                ENDIF
                   
            ENDTEST
        
        IF quit = FALSE THEN
            GOTO restart;
        ENDIF
        
        ERROR
        
            IF ERRNO = ERR_ROBLIMIT THEN
                errmsg:= "Robot Movement Limit" + "\0A";
                RETURN; 
            ENDIF
            
    ENDPROC
    
    TRAP cancelTrap
        IF INTNO = cancel THEN
            StorePath;
            ClearPath;
            motionCancel := FALSE;
            ReceiveCommandLoop;
        ENDIF
        
    ENDTRAP
    
    TRAP execErrTrap
        IF INTNO = execErr THEN
            StopMove;
            StopMoveReset;
            StorePath;
            ClearPath;
            ReceiveCommandLoop;
        ENDIF
    ENDTRAP
        
    PROC MoveJSample()
    
        ! 'MoveJ' executes a joint motion towards a robtarget. This is used to move the robot quickly from one point to another when that 
        !   movement does not need to be in a straight line.
        ! 'pTableHome' is a robtarget defined in system module. The exact location of this on the table has been provided to you.
        ! 'v100' is a speeddata variable, and defines how fast the robot should move. The numbers is the speed in mm/sec, in this case 100mm/sec.
        ! 'fine' is a zonedata variable, and defines how close the robot should move to a point before executing its next command. 
        !   'fine' means very close, other values such as 'z10' or 'z50', will move within 10mm and 50mm respectively before executing the next command.
        ! 'tSCup' is a tooldata variable. This has been defined in a system module, and represents the tip of the suction cup, telling the robot that we
        !   want to move this point to the specified robtarget. Please be careful about what tool you use, as using the incorrect tool will result in
        !   the robot not moving where you would expect it to. Generally you should be using
        MoveJ pTableHome, v100, fine, tSCup;
        
    ENDPROC
    
    PROC MoveLSample()
        
        ! 'MoveL' will move in a straight line between 2 points. This should be used as you approach to pick up a chocolate
        ! 'Offs' is a function that is used to offset an existing robtarget by a specified x, y, and z. Here it will be offset 100mm in the positive z direction.
        !   Note that function are called using brackets, whilst procedures and called without brackets.
        MoveL Offs(pTableHome, 0, 0, 100), v100, fine, tSCup;
        
    ENDPROC
    
    PROC VariableSample(robtarget target, num x_offset, num y_offset, num z_offset, speeddata speed, zonedata zone)
        
        ! Call 'MoveL' with the input arguments provided.
        MoveL Offs(target, x_offset, y_offset, z_offset), speed, zone, tSCup;
        
    ENDPROC
    
ENDMODULE