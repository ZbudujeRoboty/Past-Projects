/*
 * InputsHandler.c
 *
 *  Created on: Sep 22, 2020
 *      Author: Piotr Reczek
 */

#include "InputsHandler.h"
#include "main.h"
#include "MotorController.h"

#define BUTTON_DEBOUNCE_THRESOLD_VALUE 3

uint16_t Adc_Measurements[2];



void InputsHandler_Start(void)
{
	HAL_ADC_Start_DMA(&hadc1,(uint32_t *)Adc_Measurements, 2);
}

void InputsHandler_Task(void)
{
	static uint8_t button_debouncer;


	  /*Input from IR Sensor*/
	  if(Adc_Measurements[0] < 1000 )
	  {
		 MotorController_Start();
	  }

	  /*Input from Hall Sensor*/
	  if( Adc_Measurements[1] < 1000)
	  {

		 MotorController_Stop();
	  }


	  /*Button pressed connects Pin on the microcontroller with the ground*/
	  if(HAL_GPIO_ReadPin(Button_GPIO_Port, Button_Pin) == GPIO_PIN_RESET)
	  {

		  if(button_debouncer<BUTTON_DEBOUNCE_THRESOLD_VALUE)
		  {
			  button_debouncer++;
		  }

		  if(button_debouncer == BUTTON_DEBOUNCE_THRESOLD_VALUE)
		  {
			 button_debouncer++;//Prevention from continous direction switchin, when button is keept
			 MotorController_Change_Direction();
		  }
	  }
	  else
	  {
		  if(button_debouncer>0)
		  {
			  button_debouncer--;
		  }

	  }

	/*Trigger Adc Measurement*/
	HAL_ADC_Start_DMA(&hadc1,(uint32_t *)Adc_Measurements, 2);
}
