(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    kasliwals 
* AS Version : 4.12.4.107
 * Created:   December 17, 2023/8:29 PM 
* Description: Reset Logic For Machine Resetting 
* Version : 1.0.0.0 
 *********************************************************************************)

ACTION Reset: 
	
	CASE RESET OF 
		0 :
			iAutoCtrl.Cmd.Start := FALSE;
			iAutoCtrl.Cmd.AutoMode := FALSE;
			iAutoCtrl.Cmd.Stop := FALSE;
			iAutoCtrl.ManualCmd.ConvPowerON := FALSE;
			iAutoCtrl.ManualCmd.CutterPowerON := FALSE;
			gAx_Master.In.Power := FALSE;
			gMI_ModeConfirm := FALSE;
			gAx_Slave.In.Power := FALSE;
			gAx_Slave.In.ErrorReset := TRUE;
			gAx_Master.In.ErrorReset := TRUE;
			pConvCtrl.Cmd.Start := FALSE;
			pCutterCtrl.Cmd.Start := FALSE;
			pAx_CamSeq.In.StartSequence := FALSE;
			RESET := 10;
		10 :
			gAx_Slave.In.ErrorReset := FALSE;
			gAx_Master.In.ErrorReset := FALSE;
			iAutoCtrl.Cmd.DisableCutter := FALSE;
			iAutoCtrl.Cmd.SingleCutter := FALSE;
			iAutoCtrl.Cmd.AutoMode := FALSE;
			iMI_CutterSelected := FALSE;
			gMI_ModeConfirm := FALSE;
			pAx_CamSeq.In.ErrorReset := FALSE;
			RESET := 20;
		20 :
			pAx_CamSeq.In.ErrorReset := TRUE;
			gAx_Master.In.Enable := FALSE;
			gAx_Slave.In.Enable := FALSE;
			
			RESET := 30;
		30 :
			AutoCtrlState := WAIT ;
			RESET := 0;
	END_CASE
	
END_ACTION
