(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    kasliwals 
* AS Version : 4.12.4.107
 * Created:   December 11, 2023/10:45 AM 
* Description: Cam Sequencer Logic for Master and Slave Movement
* Version : 1.0.0.0 Intial Parameter setting
 *********************************************************************************)

PROGRAM _INIT
	//Giving initial parameters to various  axis parameters and reg capture fucntion block
	gAx_Master.In.Parameters.Acceleration := 10800;
	gAx_Master.In.Parameters.Deceleration := 108000;
	gAx_Slave.In.Parameters.Jog.Acceleration := 108000;
	gAx_Slave.In.Parameters.Jog.Deceleration := 1080000;
	gAx_Slave.In.Parameters.Jog.Velocity := 360;
	
	iVa_RegCaptureAdvPara.EventSourceParID := ACP10PAR_STAT_TRIGGER1;
	iVa_RegCaptureAdvPara.Edge := ncP_EDGE;
	iVa_RegCaptureAdvPara.MinWidth := 50;
	iVa_RegCaptureAdvPara.MaxWidth := 200;
	iVa_RegCaptureAdvPara.WindowNeg := 200;
	iVa_RegCaptureAdvPara.WindowPos := 200;
	iVa_RegCaptureAdvPara.SensorDelay := 200;
	iVa_RegCaptureAdvPara.CorrectCurrentCycle := TRUE;
	iVa_RegCaptureAdvPara.CorrectionValueLimitNeg := 70;
	iVa_RegCaptureAdvPara.CorrectionValueLimitPos := 70;
	
	iVa_RegCaptureConfig.DistanceToSensor := 1050;
	iVa_RegCaptureConfig.ProductLength := 700;
	iVa_RegCaptureConfig.RegMarkPosition := 700;
	iVa_RegCaptureConfig.RegMarkOffset := 10;
	gMI_ModeConfirm;
	gMI_MODE;
END_PROGRAM

PROGRAM _CYCLIC
	//Dual and single cutter switching logic
	IF iCutterCtrl.Cmd.SingleCutter THEN
		SingleCutter;
		SingleCam;
	ELSE
		DualCutter;
		DualCutterCamAuto;
	END_IF
	
	//Calling action files 
	Mapping;
	IF gAx_Slave.Out.Info.PLCopenState = mpAXIS_SYNCHRONIZED_MOTION THEN
		iFb_RegCapture();
	END_IF
	RegCapture;
END_PROGRAM

PROGRAM _EXIT
	//Disabling Function Blocks
	iFb_MpAxisBasic.Enable := FALSE;
	iFb_MpAxisBasic();
	iFb_MpAxisSlave.Enable := FALSE;
	iFb_MpAxisSlave();
	iFb_CamSeq.Enable := FALSE;
	iFb_CamSeq();
END_PROGRAM

