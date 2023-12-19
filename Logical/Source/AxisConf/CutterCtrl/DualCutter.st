(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    kasliwals 
* AS Version : 4.12.4.107
 * Created:   December 16, 2023/11:41 PM 
* Description: Dual Cutter Homing Logic and jog limits
* Version : 1.0.0.0 Intial State declaration
			1.0.0.1 Added Homing Logic
			2.0.0.1 Final Update
 *********************************************************************************)

ACTION DualCutter: 
	//Dual Cutter Homing And operation State
	
	CASE iSlaveStateDual OF
		
		//Wait State
		WAIT :
			IF gAx_Slave.Out.Active AND iCutterCtrl.Cmd.Start THEN
				iSlaveStateDual := ACTIVE;
			END_IF
		
		//Active State
		ACTIVE :
			IF gAx_Slave.Out.Position >= LOWER_CUT_POS AND gAx_Master.Out.Position <= UPPER_CUT_POS THEN
				gAx_Slave.In.Power := FALSE;
			ELSE
				iSlaveStateDual := POWER_ON;
			END_IF
		
		//Axis Power On State
		POWER_ON :
			IF gAx_Slave.Out.Info.ReadyToPowerOn  AND iCutterCtrl.Cmd.AutoMode  THEN
				gAx_Slave.In.Power := TRUE;
			END_IF
			IF gAx_Slave.Out.PowerOn AND gAx_Slave.Out.Position < LOWER_CUT_POS THEN
				iSlaveStateDual := NEGATIVE_HOMING_MODE;
			END_IF
			IF gAx_Slave.Out.PowerOn AND gAx_Slave.Out.Position > UPPER_CUT_POS THEN
				iSlaveStateDual := POSITIVE_HOMING_MODE;
			END_IF
		
		//Deciding HominG parameters for Homing of cutter
		NEGATIVE_HOMING_MODE :
			gAx_Slave.In.Parameters.Home.Mode := mpAXIS_HOME_MODE_REF_PULSE;
			gAx_Slave.In.Parameters.Home.HomingDirection := mpAXIS_HOME_DIR_NEGATIVE;
			gAx_Slave.In.Parameters.Home.SensorOffset := HOMING_OFFSET_DUAL;
			gAx_Slave.In.Parameters.Home.HomingVelocity := HOMING_VEL;
			gAx_Slave.In.Parameters.Home.StartVelocity := START_VEL;
			gAx_Slave.In.Update := TRUE;
			IF gAx_Slave.Out.UpdateDone THEN
				gAx_Slave.In.Update := FALSE;
				gAx_Slave.In.Home := TRUE;
				iSlaveStateDual := HOMING;
			END_IF
		POSITIVE_HOMING_MODE :
			gAx_Slave.In.Parameters.Home.Mode := mpAXIS_HOME_MODE_REF_PULSE;
			gAx_Slave.In.Parameters.Home.HomingDirection := mpAXIS_HOME_DIR_POSITIVE;
			gAx_Slave.In.Parameters.Home.SensorOffset := HOMING_OFFSET_DUAL;
			gAx_Slave.In.Parameters.Home.HomingVelocity := HOMING_VEL;
			gAx_Slave.In.Parameters.Home.StartVelocity := START_VEL;
			
			gAx_Slave.In.Update := TRUE;
			IF gAx_Slave.Out.UpdateDone THEN
				gAx_Slave.In.Update := FALSE;
				gAx_Slave.In.Home := TRUE;
				iSlaveStateDual := HOMING;
			END_IF
		
		//Homing of Cutter
		HOMING :
			IF gAx_Slave.Out.IsHomed THEN
				gAx_Slave.In.Home := FALSE;
				IF iCutterCtrl.Cmd.AutoMode THEN
					iSlaveStateDual := AUTO_MODE;
				END_IF
				
			END_IF
		
		//Auto MODe OF CUtter
		AUTO_MODE :
			IF iCutterCtrl.Cmd.Start = FALSE THEN
				iSlaveStateDual := WAIT;
			END_IF
	END_CASE
	
	//Reset Condition
	IF iCutterCtrl.Cmd.Start = FALSE THEN
		iSlaveStateDual := WAIT;
	END_IF
	
END_ACTION
