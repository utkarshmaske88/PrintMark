(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    kasliwals 
 * AS Version : 4.12.4.107
 * Created:   December 14, 2023/11:35 PM 
* Description: Auto Ctrl Logic for Print Mark
* Version : 1.0.0.0 Intial Creation
			1.0.0.1 Added states and Logic
			2.0.0.0 Final Update
 *********************************************************************************)

PROGRAM _INIT
	//Accessing Various Variables for Pointer references
	Status_CutterCtrl := PV_xgetadr(ADR('CutterCtrl:iCutterCtrl'),ADR(CutterAdd),ADR(SizeCutter));
	Status_ConvCtrl := PV_xgetadr(ADR('ConvCtrl:iConvCtrl'),ADR(ConvAdd),ADR(SizeConv));
	Status_CamSeq := PV_xgetadr(ADR('CutterCtrl:iAx_CamSeq'),ADR(CamAdd),ADR(SizeCam));
	Status_RegCapture := PV_xgetadr(ADR('CutterCtrl:iFb_RegCapture'),ADR(RegAdd),ADR(RegSize));
	gAx_Master.In.Enable := TRUE;
	gAx_Slave.In.Enable := TRUE;
	iMI_CurrentMode := 'Manual Mode';
END_PROGRAM

PROGRAM _CYCLIC
	//Pointers Access
	pCutterCtrl ACCESS CutterAdd;
	pConvCtrl ACCESS ConvAdd;
 	pAx_CamSeq ACCESS CamAdd;
	pRegCapture ACCESS RegAdd;
	
	//Auto Control Logic State
	CASE AutoCtrlState OF
		
		//Wait State
		WAIT :
			iMI_MachineStatus := 'Please Select the Cutter.';
			gAx_Master.In.Enable := TRUE;
			gAx_Slave.In.Enable := TRUE;
			IF iAutoCtrl.Cmd.SingleCutter THEN
				pCutterCtrl.Cmd.SingleCutter := TRUE;
			ELSE
				pCutterCtrl.Cmd.SingleCutter := FALSE;
			END_IF
			IF iMI_CutterSelected THEN
				iMI_MachineStatus := 'Please Select the Mode and Press The Start Button.';
			END_IF
			IF iAutoCtrl.Cmd.Start AND iMI_CutterSelected THEN
				pConvCtrl.Cmd.Start := TRUE;
				pCutterCtrl.Cmd.Start := TRUE;
				AutoCtrlState := MODE_SELECT;
			END_IF
		
		//Mode Selection State
		MODE_SELECT :
			IF gMI_ModeConfirm THEN
				IF iAutoCtrl.Cmd.AutoMode THEN
					iMI_CurrentMode := 'Auto Mode';
					AutoCtrlState := HOMING_DONE;
				ELSE
					iMI_CurrentMode := 'Manual Mode';
					AutoCtrlState := MANUAL_START;
				END_IF
			END_IF
			
		//Axis Homing State
		HOMING_DONE :
			iMI_MachineStatus := 'Homing Both Axis';
			pAx_CamSeq.In.ErrorReset := TRUE;
			IF gAx_Master.Out.IsHomed AND gAx_Slave.Out.IsHomed THEN
				pAx_CamSeq.In.ErrorReset := FALSE;
				AutoCtrlState := AUTO_START;
			END_IF
		
		//Automatic Mode For print mark cross Cutter
		AUTO_START :
			//Starting cam sequencer
			IF pAx_CamSeq.Out.Info.MasterReady AND pAx_CamSeq.Out.Info.SlaveReady AND pAx_CamSeq.Out.StatusID = 0 THEN
				pAx_CamSeq.In.StartSequence := TRUE;
			END_IF
			//Error handling of cam
			IF pAx_CamSeq.Out.StatusID <> 0 THEN
				pAx_CamSeq.In.ErrorReset := TRUE;
			ELSE
				pAx_CamSeq.In.ErrorReset := FALSE;
			END_IF
			//Starting Master
			IF pAx_CamSeq.Out.InSync AND iAutoCtrl.Cmd.Start THEN
				iMI_MachineStatus := 'Running in Auto Mode';
				gAx_Master.In.MoveVelocity := TRUE;
			END_IF
			//IF stop Pressed
			IF iAutoCtrl.Cmd.Stop THEN
				iMI_MachineStatus := 'Stop Pressed. Press Start to Restart Or Change mode to Exit Mode and select mode.';
				gAx_Master.In.MoveVelocity := FALSE;
			END_IF
			//Disabled Cutter Cmd given
			IF iAutoCtrl.Cmd.DisableCutter THEN
				iMI_MachineStatus := 'Cutter Disabled Pressed';
				pAx_CamSeq.In.StartSequence := FALSE;
				pCutterCtrl.Cmd.Start := FALSE;
				gAx_Slave.In.Power := FALSE;
				gAx_Slave.In.Enable := FALSE;
				AutoCtrlState := CUTTER_DISABLED_HOME;
			END_IF
			//Stopping the mode and resetting machine
			IF iAutoCtrl.Cmd.ChangeMode AND iAutoCtrl.Cmd.Stop THEN
				iMI_MachineStatus := 'Machine Stopped';
				gAx_Master.In.MoveVelocity := FALSE;
				iAutoCtrl.Cmd.ChangeMode := FALSE;
				pAx_CamSeq.In.StartSequence := FALSE;
				AutoCtrlState := STOP;
			END_IF
			
		//Homing Cutter After Disabling
		CUTTER_DISABLED_HOME :
			gAx_Slave.In.Enable := TRUE;
			IF gAx_Slave.Out.Active THEN
				iMI_MachineStatus := 'Homing Cutter';
				gAx_Slave.In.Power := TRUE;
				AutoCtrlState := CUTTER_DISABLED;
			END_IF
			
		//Cutter Disabled and waiting for cmd
		CUTTER_DISABLED :
			pCutterCtrl.Cmd.Start := TRUE;
			IF gAx_Slave.Out.IsHomed THEN
				iMI_MachineStatus := 'Cutter Disbaled. Stop Mode or Restart Cutter Again';
				gAx_Slave.In.Home := FALSE;
			END_IF
			//Stop Cmd Given
			IF iAutoCtrl.Cmd.Stop THEN
				gAx_Master.In.MoveVelocity := FALSE;
			END_IF
			//Start given 
			IF iAutoCtrl.Cmd.Start THEN
				gAx_Master.In.MoveVelocity := TRUE;
			END_IF
			//Cutter Enabled
			IF iAutoCtrl.Cmd.DisableCutter = FALSE THEN
				iMI_MachineStatus := 'Cutter Enabled';
				AutoCtrlState := AUTO_START;
			END_IF
			//Mode Changed
			IF iAutoCtrl.Cmd.ChangeMode AND iAutoCtrl.Cmd.Stop THEN
				iMI_MachineStatus := 'Machine Stopped';
				gAx_Master.In.MoveVelocity := FALSE;
				iAutoCtrl.Cmd.ChangeMode := FALSE;
				pAx_CamSeq.In.StartSequence := FALSE;
				AutoCtrlState := STOP;
			END_IF
		
		//Manual Mode for print mark Cross cutter
		MANUAL_START :
			iMI_MachineStatus := 'Machine in Manual mode';
			IF iAutoCtrl.Cmd.Stop AND iAutoCtrl.Cmd.ChangeMode THEN
				iMI_MachineStatus := 'Machine Stopped';
				iAutoCtrl.ManualCmd.ConvPowerON := FALSE;
				iAutoCtrl.ManualCmd.CutterPowerON := FALSE;
				AutoCtrlState := STOP;
			END_IF
		
		//Machine stop state
		STOP :
			iMI_MachineStatus := 'Machine Stopped';
			iAutoCtrl.Cmd.Start := FALSE;
			gMI_ModeConfirm := FALSE;
			gAx_Master.In.Power := FALSE;
			gAx_Slave.In.Power := FALSE;
			gAx_Master.In.Enable := FALSE;
			gAx_Slave.In.Enable := FALSE;
			pConvCtrl.Cmd.Start := FALSE;
			iAutoCtrl.Cmd.ChangeMode := FALSE;
			iMI_CutterSelected := FALSE;
			pCutterCtrl.Cmd.Start := FALSE;
			iAutoCtrl.Cmd.DisableCutter := FALSE;
			iAutoCtrl.Cmd.Stop := FALSE;
			AutoCtrlState := WAIT;
		
		//Cutter in cutting zone state
		IN_CUTTING_ZONE :
			iMI_MachineStatus := 'Cutter In Cutting Zone.';
			iAutoCtrl.ManualCmd.ConvPowerON := FALSE;
			iAutoCtrl.ManualCmd.CutterPowerON := FALSE;
			IF gAx_Slave.Out.Position > UPPER_CUT_POS OR gAx_Slave.Out.Position <LOWER_CUT_POS  THEN
				iAutoCtrl.Cmd.Start := FALSE;
				AutoCtrlState := WAIT;
			END_IF
		END_CASE
	
	//Cmd for manual Modes
	IF NOT iAutoCtrl.Cmd.AutoMode THEN 
		gAx_Master.In.Power := iAutoCtrl.ManualCmd.ConvPowerON;
		gAx_Slave.In.Power := iAutoCtrl.ManualCmd.CutterPowerON;
		gAx_Master.In.JogNegative := pConvCtrl.Cmd.JogBack;
		gAx_Master.In.JogPositive := pConvCtrl.Cmd.JogFwd;
		gAx_Slave.In.JogNegative := pCutterCtrl.Cmd.JogBack;
		gAx_Slave.In.JogPositive := pCutterCtrl.Cmd.JogFwd;
		
	END_IF
	
	//Mapping some variables for sub task control
	pConvCtrl.Cmd.AutoMode := iAutoCtrl.Cmd.AutoMode;
	pCutterCtrl.Cmd.AutoMode := iAutoCtrl.Cmd.AutoMode;
	//Cutting zone Logic
	IF gAx_Slave.Out.Position < UPPER_CUT_POS AND gAx_Slave.Out.Position > LOWER_CUT_POS AND NOT iAutoCtrl.Cmd.AutoMode THEN
		AutoCtrlState := IN_CUTTING_ZONE;
	END_IF
	
	//Hmi Variables calculation
	iMI_LastBagLen := pRegCapture.AdditionalInfo.ActLength / TEN;
	iMI_AvgBagLen := pRegCapture.AdditionalInfo.AverageProductLength /TEN;
	IF iAutoCtrl.Cmd.AutoMode THEN
		iMI_CurrentMode := 'Auto Mode';
	ELSE
		iMI_CurrentMode := 'Manual Mode';
	END_IF
	
	//Reset Condition
	IF iAutoCtrl.Cmd.Reset THEN
		Reset;
	END_IF
	
	//Condition For Calling RegMarkCapture FB
	IF gAx_Slave.Out.Info.PLCopenState = mpAXIS_SYNCHRONIZED_MOTION THEN
		pRegCapture();
	END_IF
	//Cyclic Torque Read Enable
	gAx_Master.In.Parameters.CyclicRead.TorqueMode := mpAXIS_READ_CYCLIC;
	gAx_Slave.In.Parameters.CyclicRead.TorqueMode := mpAXIS_READ_CYCLIC;
	
	//Calling Alarm ACtion file
	gMI_MODE := iAutoCtrl.Cmd.AutoMode;
	Alarm;
END_PROGRAM

PROGRAM _EXIT
	
	 
END_PROGRAM

