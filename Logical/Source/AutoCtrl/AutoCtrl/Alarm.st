(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    kasliwals 
* AS Version : 4.12.4.107
 * Created:   December 16, 2023/11:54 PM 
* Description: Alarm Logic
* Version : 1.0.0.0 
 *********************************************************************************)

ACTION Alarm: 
	//in Cutting zone alarm
	IF gAx_Slave.Out.Position < UPPER_CUT_POS AND gAx_Slave.Out.Position > LOWER_CUT_POS AND NOT iAutoCtrl.Cmd.AutoMode THEN
		MpAlarmXSet(gAlarmXMain,'InCuttingZone');
	ELSE
		MpAlarmXReset(gAlarmXMain,'InCuttingZone');
	END_IF
	
	//Product without pritn mark limit exceeded alarm
	IF pRegCapture.ProductsWithoutRM > PROUCT_WITHOUT_RM THEN
		pAx_CamSeq.In.StartSequence := FALSE;
		gAx_Master.In.Power := FALSE;
		gAx_Slave.In.Power := FALSE;
		MpAlarmXSet(gAlarmXMain,'CuttingError');
		AutoCtrlState := STOP;
	ELSE
		MpAlarmXReset(gAlarmXMain,'CuttingError');
	END_IF
	
END_ACTION
