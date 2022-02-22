/*
 * TaskScheduler_Cfg.h
 *
 *  Created on: Sep 22, 2020
 *      Author: Piotr Reczek
 */

#ifndef INC_TASKSCHEDULER_CFG_H_
#define INC_TASKSCHEDULER_CFG_H_

#include "InputsHandler.h"

/*Macro defines number of used tasks */
#define NUMBER_OF_TASKS 1U

/*Here shall be put tasks callbacks and the tasks period*
 * Format {Period_in_ms,Task Handler}
 */
#define TASKS_CONFIGURATION_TABLE \
{\
	{10,InputsHandler_Task},\
}




#endif /* INC_TASKSCHEDULER_CFG_H_ */
