(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    kasliwals 
 * Created:   December 16, 2023/11:36 PM 
 *********************************************************************************)

TYPE
	AxisState_enum : 
		( (*Axis States*)
		WAIT, (*Wait State*)
		ACTIVE, (*Active State*)
		POWER_ON, (*Power on state*)
		POSITIVE_HOMING_MODE, (*Positive side homing*)
		NEGATIVE_HOMING_MODE, (*Negative side homing*)
		HOMING, (*Homing*)
		AUTO_MODE, (*Auto mode state*)
		OPERATION, (*Operation Mode*)
		JOG_POSITIVE, (*Jog positive state*)
		JOG_NEGATIVE, (*Jog Negative State*)
		IN_CUTTING_ZONE (*in Cutting zone state*)
		);
	DualAxisState_enum : 
		( (*Axis States*)
		IDLE, (*Wait State*)
		ACTIVEE, (*Active State*)
		POWERON, (*Power on state*)
		FIRST_Q_HOME,
		SECOND_Q_HOME,
		THIRD_Q_HOME,
		FOURTH_Q_HOME,
		HOME, (*Homing*)
		IN_OPERATION, (*Operation Mode*)
		CUTTING_ZONE (*in Cutting zone state*)
		);
END_TYPE
