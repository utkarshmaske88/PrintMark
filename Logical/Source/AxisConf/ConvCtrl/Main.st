(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    kasliwals 
* AS Version : 4.12.4.107
 * Created:   December 12, 2023/11:44 PM 
* Description: Conv Homing and jog logic
* Version : 1.0.0.0 Intial State Logic
			2.0.0.0 Final Update 
 *********************************************************************************)

PROGRAM _INIT
	(* Insert code here *)
	//Setting Various conv Parameters
	gAx_Master.In.Parameters.Jog.Acceleration := 480000;
	gAx_Master.In.Parameters.Jog.Deceleration := 4800000;
	gAx_Master.In.Parameters.Jog.Velocity := 45;
	gAx_Master.In.Parameters.Home.Mode := mpAXIS_HOME_MODE_ABS_SWITCH;
	gAx_Master.In.Parameters.Home.StartVelocity := 200;
	gAx_Master.In.Parameters.Home.HomingDirection := mpAXIS_HOME_DIR_NEGATIVE;
	
END_PROGRAM

PROGRAM _CYCLIC
	//Homing of Conv and Adding jog limits
	
	CASE iMasterAxisStep OF
		
		//Wait State
		WAIT :
			IF gAx_Master.Out.Active AND iConvCtrl.Cmd.Start THEN
				iMasterAxisStep := ACTIVE;
			END_IF
		
		//Active State
		ACTIVE :
			IF gAx_Master.Out.Info.ReadyToPowerOn AND iConvCtrl.Cmd.AutoMode THEN
				gAx_Master.In.Power := TRUE;
			END_IF
			IF gAx_Master.Out.PowerOn THEN
				iMasterAxisStep := HOME;
			END_IF
		
		//Home State
		HOME :
			gAx_Master.In.Home := TRUE;
			IF gAx_Master.Out.IsHomed THEN
				gAx_Master.In.Home := FALSE;
				IF iConvCtrl.Cmd.AutoMode THEN
					iMasterAxisStep := AUTOMATIC;
				ELSE
					iMasterAxisStep := MANUAL;
				END_IF
			END_IF
			
		//Automatic Mode OF conv
		AUTOMATIC :
			IF iConvCtrl.Cmd.Start = FALSE THEN
				iMasterAxisStep := WAIT;
			END_IF
			
		//Manual Mode of COnv
		MANUAL :
			IF iConvCtrl.Cmd.JogFwd THEN
				iMasterAxisStep := JOG_POSITIVE;
			END_IF
			IF iConvCtrl.Cmd.JogBack THEN
				iMasterAxisStep := JOG_NEGATIVE;
			END_IF
			iVa_RecPrintPosition := K_ZERO;
			IF iConvCtrl.Cmd.Start = FALSE THEN
				iMasterAxisStep := WAIT;
				gAx_Master.In.Power := FALSE;
			END_IF
		
		//Jog Positive of Conv
		JOG_POSITIVE :
			gAx_Master.In.JogPositive := TRUE;
			IF NOT iConvCtrl.Cmd.JogFwd THEN
				gAx_Master.In.JogPositive := FALSE;
				iMasterAxisStep := MANUAL;
			END_IF
				
		//Jog negative of COnv
		JOG_NEGATIVE :
			gAx_Master.In.JogNegative := TRUE;
			IF (gAx_Master.In.JogNegative  AND EDGENEG(iConvCtrl.Cmd.PrintMark)) OR 
				(EDGEPOS(gAx_Master.In.JogNegative) AND iConvCtrl.Cmd.PrintMark ) THEN
				iVa_RecPrintPosition := gAx_Master.Out.Position;
			END_IF
			//Setting 3 Cm limit for jog Negative
			IF (iVa_RecPrintPosition - gAx_Master.Out.Position) > (PRINT_MARK_LIMIT) AND iVa_RecPrintPosition <> K_ZERO THEN
				gAx_Master.In.JogNegative := FALSE;
				iConvCtrl.Cmd.JogBack := FALSE;
				iMasterAxisStep := MANUAL;
			ELSE
				iConvCtrl.Status.JogNegReady := TRUE;
			END_IF
		
	END_CASE
	
	//Variable mapping and config of set hardware input FB
	iConvCtrl.Cmd.PrintMark := gAx_Slave.Out.Info.DigitalInputsStatus.Trigger1;
	iVa_SetMasterInputs.Axis := ADR(gAxis01);
	iVa_SetMasterInputs.Enable := TRUE;
	iVa_SetMasterInputs.HomeSwitch := gAx_Slave.Out.Info.DigitalInputsStatus.Trigger1;
	iVa_SetMasterInputs();
	IF iConvCtrl.Cmd.Start = FALSE THEN
		iMasterAxisStep := WAIT;
	END_IF
	
END_PROGRAM

PROGRAM _EXIT
	//Diabling FB
	iVa_SetMasterInputs.Enable := FALSE;
	iVa_SetMasterInputs();
	 
END_PROGRAM

