/*
 * TaskScheduler.h
 *
 *  Created on: Sep 22, 2020
 *      Author: Piotr Reczek
 */

#ifndef INC_TASKSCHEDULER_H_
#define INC_TASKSCHEDULER_H_


/*Function starts Task Scheduler module*/
void TaskScheduler_Start(void);
/*Function shall be called when SysTick should be incremented*/
void TaskScheduler_Tick(void);
/*Function shall be called in main function. It runs tasks in proper order with predefined period*/
void TaskScheduler_Run(void);

#endif /* INC_TASKSCHEDULER_H_ */
