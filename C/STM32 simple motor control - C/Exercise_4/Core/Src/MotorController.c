/*
 * MotorController.c
 *
 *  Created on: Sep 22, 2020
 *      Author: Piotr Reczek
 */
#include "main.h"
#include "MotorController.h"

typedef enum{
	IN_IN_MODE = 0,
	PH_EN_MODE = 1
}MotorDriverMode_T;

typedef enum{
	LEFT = 0,
	RIGHT = 1
}MotorDriverDirection_T;


typedef enum{
	NOT_INITIALIZED = 0,
	STARTED = 1,
	STOPPED =2
}MotorDriverState_T;

MotorDriverState_T Driver_State = NOT_INITIALIZED;

static void MotorController_Set_Driver_Mode(MotorDriverMode_T mode);
static void MotorController_Set_Direction(MotorDriverDirection_T direction);
static void MotorController_Set_PWM(uint16_t duty);

void MotorController_Start(void)
{
	if(Driver_State != STARTED)
	{
	  MotorController_Set_Driver_Mode(PH_EN_MODE);
	  HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_2);
	  MotorController_Set_PWM(500);
	  MotorController_Set_Direction(LEFT);
	  Driver_State = STARTED;
	}
}

void MotorController_Stop(void)
{
	if(Driver_State != STOPPED)
	{
	  MotorController_Set_Driver_Mode(PH_EN_MODE);
	  MotorController_Set_PWM(0);
	  HAL_TIM_PWM_Stop(&htim3, TIM_CHANNEL_2);
	  Driver_State = STOPPED;
	}
}

void MotorController_Change_Direction(void)
{
	static MotorDriverDirection_T direction = LEFT;

	if(direction==LEFT)
	{
		direction = RIGHT;
	}
	else
	{
		direction = LEFT;
	}

	MotorController_Set_Direction(direction);
}


static void MotorController_Set_Driver_Mode(MotorDriverMode_T mode)
{
	HAL_GPIO_WritePin(MODE_GPIO_Port, MODE_Pin, (GPIO_PinState)mode);
}

static void MotorController_Set_Direction(MotorDriverDirection_T direction)
{
	HAL_GPIO_WritePin(PHASE_GPIO_Port, PHASE_Pin, (GPIO_PinState) direction);
}

static void MotorController_Set_PWM(uint16_t duty)
{
	if(duty > 999)
	{
		duty = 999;
	}
	htim3.Instance->CCR2 = duty;
}
