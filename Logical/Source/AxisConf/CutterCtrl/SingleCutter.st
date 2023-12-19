(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    kasliwals 
* AS Version : 4.12.4.107
 * Created:   December 12, 2023/11:40 PM 
* Description: Single Cutter Homingb Logic and jog Limits
* Version : 1.0.0.0 Intial State declaration
			1.0.0.1 Added Homing Logic
			2.0.0.1 Final Update
 *********************************************************************************)

ACTION  SingleCutter : 
	//Homing State for single cutter
	CASE iSlaveStateSingle OF 
		//Wait state
		WAIT :
			IF gAx_Slave.Out.Active AND iCutterCtrl.Cmd.Start THEN
				iSlaveStateSingle := ACTIVE;
			END_IF
			
			//Active State
		ACTIVE :
			IF gAx_Slave.Out.Position >= LOWER_CUT_POS AND gAx_Master.Out.Position <= UPPER_CUT_POS THEN
				gAx_Slave.In.Power := FALSE;
			ELSE
				iSlaveStateSingle := POWER_ON;
			END_IF
			
	//Axis Power On State
		POWER_ON :
			IF gAx_Slave.Out.Info.ReadyToPowerOn  AND iCutterCtrl.Cmd.AutoMode  THEN
				gAx_Slave.In.Power := TRUE;
			END_IF
			IF gAx_Slave.Out.PowerOn AND gAx_Slave.Out.Position < LOWER_CUT_POS THEN
				iSlaveStateSingle := NEGATIVE_HOMING_MODE;
			END_IF
			IF gAx_Slave.Out.PowerOn AND gAx_Slave.Out.Position > UPPER_CUT_POS THEN
				iSlaveStateSingle := POSITIVE_HOMING_MODE;
			END_IF

			//Deciding homing paramters
		NEGATIVE_HOMING_MODE :
			gAx_Slave.In.Parameters.Home.Mode := mpAXIS_HOME_MODE_REF_PULSE;
			gAx_Slave.In.Parameters.Home.HomingDirection := mpAXIS_HOME_DIR_NEGATIVE;
			gAx_Slave.In.Parameters.Home.SensorOffset := HOMING_OFFSET;
			gAx_Slave.In.Parameters.Home.HomingVelocity := HOMING_VEL;
			gAx_Slave.In.Parameters.Home.StartVelocity := START_VEL;
			gAx_Slave.In.Update := TRUE;
			IF gAx_Slave.Out.UpdateDone THEN
				gAx_Slave.In.Update := FALSE;
				gAx_Slave.In.Home := TRUE;
				iSlaveStateSingle := HOMING;
			END_IF
			
		POSITIVE_HOMING_MODE :
			gAx_Slave.In.Parameters.Home.Mode := mpAXIS_HOME_MODE_REF_PULSE;
			gAx_Slave.In.Parameters.Home.HomingDirection := mpAXIS_HOME_DIR_POSITIVE;
			gAx_Slave.In.Parameters.Home.SensorOffset := HOMING_OFFSET;
			gAx_Slave.In.Parameters.Home.HomingVelocity := HOMING_VEL;
			gAx_Slave.In.Parameters.Home.StartVelocity := START_VEL;
			
			gAx_Slave.In.Update := TRUE;
			IF gAx_Slave.Out.UpdateDone THEN
				gAx_Slave.In.Update := FALSE;
				gAx_Slave.In.Home := TRUE;
				iSlaveStateSingle := HOMING;
			END_IF
			
	//Homing State
		HOMING :
			IF gAx_Slave.Out.IsHomed THEN
				gAx_Slave.In.Home := FALSE;
				IF iCutterCtrl.Cmd.AutoMode THEN
					iSlaveStateSingle := AUTO_MODE;
				ELSE
					iSlaveStateSingle := OPERATION;
				END_IF
			END_IF
		
		//Automatic mode for single cutter
		AUTO_MODE :
			IF iCutterCtrl.Cmd.Start = FALSE THEN
				iSlaveStateSingle := WAIT;
			END_IF
		
		//Manual Mode for Single Cutter
		OPERATION :
			IF iCutterCtrl.Cmd.JogFwd THEN
				iSlaveStateSingle := JOG_POSITIVE;
			END_IF
			IF iCutterCtrl.Cmd.JogBack THEN
				iSlaveStateSingle := JOG_NEGATIVE;
			END_IF
			IF iCutterCtrl.Cmd.Start = FALSE THEN
				iSlaveStateSingle := WAIT;
			END_IF
		
		//Jog Positive State
		JOG_POSITIVE :
			IF NOT iCutterCtrl.Cmd.JogFwd OR gAx_Slave.Out.Position = LOWER_BUFER  THEN
				gAx_Slave.In.JogPositive := FALSE;
				iSlaveStateSingle := OPERATION;
			ELSE
				gAx_Slave.In.JogPositive := TRUE;
			END_IF
			IF gAx_Slave.Out.Position = LOWER_BUFER THEN
				iCutterCtrl.Cmd.JogFwd := FALSE;
			END_IF
	
		//Jog Negative State
		JOG_NEGATIVE :
			IF NOT iCutterCtrl.Cmd.JogBack OR gAx_Slave.Out.Position = UPPER_BUFFER  THEN
				gAx_Slave.In.JogNegative := FALSE;
				iSlaveStateSingle := OPERATION;
			ELSE
				gAx_Slave.In.JogNegative := TRUE;
			END_IF
			IF gAx_Slave.Out.Position = UPPER_BUFFER THEN
				iCutterCtrl.Cmd.JogBack := FALSE;
			END_IF
		
		//Cuttter in cutting zone state
		IN_CUTTING_ZONE :
			gAx_Slave.In.Power := FALSE;
			IF (gAx_Slave.Out.Position < LOWER_CUT_POS OR gAx_Slave.Out.Position >UPPER_CUT_POS) AND gAx_Slave.Out.IsHomed THEN
				gAx_Slave.In.Power := TRUE;
				iSlaveStateSingle := OPERATION;
			ELSIF  (gAx_Slave.Out.Position < LOWER_CUT_POS OR gAx_Slave.Out.Position >UPPER_CUT_POS) AND NOT gAx_Slave.Out.IsHomed THEN
				iSlaveStateSingle := POWER_ON;
			END_IF
		
	END_CASE
	
	
	
	//Case State for Deciding jog Limit of Cutter and limitting its jog 
	CASE iJogState OF
		0:
			IF gAx_Slave.In.JogNegative = TRUE THEN
				iJogState	:= 10;
			END_IF;
			IF (gAx_Slave.In.JogPositive = TRUE) THEN
				iJogState	:= 20;
			END_IF;
		5:
			gAx_Slave.In.JogPositive	:= TRUE;
			gAx_Slave.In.JogNegative	:= TRUE;
			iJogState		:= 0;
				
		10:
			IF (gAx_Slave.Out.CommandAborted = TRUE) THEN
				iJogState					:= 5;
				gAx_Slave.In.JogNegative	:= FALSE;
			END_IF;
				
			IF (gAx_Slave.Out.Position > UPPER_CUT_POS)THEN
				gAx_Slave.In.Parameters.Jog.LowerLimit	:= UPPER_BUFFER;
				gAx_Slave.In.Parameters.Jog.UpperLimit	:= LIMIT_END;
				gAx_Slave.In.Update					:= TRUE;
				iJogState								:= 30;
			END_IF;
		20:
			IF (gAx_Slave.Out.CommandAborted = TRUE) THEN
				iJogState					:= 5;
				gAx_Slave.In.JogPositive	:= FALSE;
			END_IF;
				
			IF (gAx_Slave.Out.Position < LOWER_CUT_POS)THEN
				gAx_Slave.In.Parameters.Jog.LowerLimit	:=ZERO;
				gAx_Slave.In.Parameters.Jog.UpperLimit	:= LOWER_BUFER;
				gAx_Slave.In.Update					:= TRUE;
				iJogState								:= 30;
			END_IF;
		30:
			IF gAx_Slave.Out.UpdateDone = TRUE THEN
				gAx_Slave.In.Update					:= FALSE;
			END_IF;
			IF gAx_Slave.In.JogNegative = TRUE AND gAx_Slave.Out.Position <ZERO AND gAx_Slave.Out.Position > UPPER_CUT_POS THEN
				iJogState	:= 10;
			END_IF;
			IF (gAx_Slave.In.JogPositive = TRUE) AND gAx_Slave.Out.Position > ZERO AND gAx_Slave.Out.Position < LOWER_CUT_POS  THEN
				iJogState	:= 20;
			END_IF;
			IF ((gAx_Slave.Out.Position = UPPER_BUFFER) OR (gAx_Slave.Out.Position =LOWER_BUFER )) THEN
				gAx_Slave.In.JogNegative			:= FALSE;
				gAx_Slave.In.JogPositive			:= FALSE;
				iJogState							:= 40;
			END_IF;
		40:
	
			gAx_Slave.In.Parameters.Jog.LowerLimit	:= ZERO;
			gAx_Slave.In.Parameters.Jog.UpperLimit	:= ZERO;
			gAx_Slave.In.Update					:= TRUE;
			IF gAx_Slave.Out.UpdateDone = TRUE THEN
				gAx_Slave.In.Update				:= FALSE;
				iJogState							:= 0;
			END_IF;
	END_CASE;
	//Reset Condition
	IF iCutterCtrl.Cmd.Start = FALSE THEN
		iSlaveStateSingle := WAIT;
		iJogState := 0;
	END_IF
END_ACTION
