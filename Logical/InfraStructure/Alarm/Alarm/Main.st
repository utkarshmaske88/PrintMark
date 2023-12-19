(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    kasliwals 
* AS Version : 4.12.4.107
 * Created:   December 16, 2023/11:54 PM 
* Description: Alarm Configuration
* Version : 1.0.0.0 
 *********************************************************************************)

PROGRAM _INIT
	
	 
END_PROGRAM

PROGRAM _CYCLIC
	//Config of alarm FB
	iFB_Alarm.Enable := TRUE;
	iFB_Alarm.MpLink := ADR(gAlarmXMain);
	iFB_Alarm();
	
END_PROGRAM

PROGRAM _EXIT
	//Diabling alarm FB
	iFB_Alarm.Enable := FALSE;
	iFB_Alarm();
	
END_PROGRAM

