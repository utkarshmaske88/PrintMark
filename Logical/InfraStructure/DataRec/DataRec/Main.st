(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    kasliwals 
* AS Version : 4.12.4.107
 * Created:   December 17, 2023/3:43 PM 
* Description: Data Recorder Implementati
* Version : 1.0.0.0 
 *********************************************************************************)

PROGRAM _INIT
	
	 
END_PROGRAM

PROGRAM _CYCLIC
	//Config of Data Rec FB and Data Reg par FB
	iFB_DataR.DeviceName := ADR('USER');
	iFB_DataR.Enable := TRUE;
	iFB_DataR.MpLink := ADR(gDataRecorder);
	iFB_DataR.SamplingTime := T#1s;
	iFB_DataR.Record := TRUE;
	iFB_DataR.RecordMode := mpDATA_RECORD_MODE_VALUE;
	
	iFB_DataR();
	
	iFB_DataRegPar.Enable := TRUE;
	iFB_DataRegPar.MpLink := ADR(gDataRecorder);
	iFB_DataRegPar.PVName := ADR('AutoCtrl:iMI_AvgBagLen');
	iFB_DataRegPar();
	
END_PROGRAM

PROGRAM _EXIT
	//Diabling Data rec FB
	iFB_DataR.Enable := FALSE;
	iFB_DataRegPar.Enable := FALSE;
	iFB_DataR();
	iFB_DataRegPar();
END_PROGRAM

