/*
 * TaskScheduler.c
 *
 *  Created on: Sep 22, 2020
 *      Author: Piotr Reczek
 */
#include "TaskScheduler.h"
#include "TaskScheduler_Cfg.h"
#include "main.h"


typedef struct {
   uint16_t period;
   void (*TaskHandler)(void);
} task_t;


task_t Tasks_table[NUMBER_OF_TASKS] = TASKS_CONFIGURATION_TABLE;
uint16_t Tasks_elapsed_times[NUMBER_OF_TASKS];
uint16_t TaskSchedulerTick;

/*Function starts Task Scheduler module*/
void TaskScheduler_Start(void)
{
	 HAL_TIM_Base_Start_IT(&htim2);
}


/*Function shall be called when SysTick should be incremented*/
void TaskScheduler_Tick(void)
{
	TaskSchedulerTick++;
}

/*Function shall be called in main function. It runs tasks in proper order with predefined period*/
void TaskScheduler_Run(void)
{
	static uint16_t prev_TaskSchedulerTick=0xFFFFU;

	if( TaskSchedulerTick != prev_TaskSchedulerTick )
	{
		/*Increment elapsed times for all tasks*/
		for (uint8_t cntr = 0; cntr < NUMBER_OF_TASKS; cntr++)
		{
			Tasks_elapsed_times[cntr]++;
		}

		/*Call tasks*/
		for (uint8_t cntr = 0; cntr < NUMBER_OF_TASKS; cntr++)
		{
			if(Tasks_elapsed_times[cntr] == Tasks_table[cntr].period )
			{
				Tasks_table[cntr].TaskHandler();
				Tasks_elapsed_times[cntr]= 0;
			}
		}

		prev_TaskSchedulerTick = TaskSchedulerTick;

	}
	else
	{
		/*Idle*/
	}

}
