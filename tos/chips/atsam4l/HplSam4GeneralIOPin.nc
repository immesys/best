/*
 * This file is part of the TinyOS support for the Storm mote
 *
 * Storm is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Storm is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Storm.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright 2014, Michael Andersen <m.andersen@eecs.berkeley.edu>
 */


interface HplSam4GeneralIOPin
{
    /**
     * This makes the standard GPIO controls work, as opposed to the
     * peripherals
     */
	async command void enableGPIO();
	/**
	 * This disables the GPIO, required for the peripheral to work
	 */
	async command void disableGPIO();
	
	async command bool isEnabledGPIO();

	async command void enableStrongDrive();
	async command void disableStrongDrive();
	async command bool isEnabledStrongDrive();

	async command void setResistorMode(gpio_resistor_mode_t mode);
	async command gpio_resistor_mode_t getResistorMode();

    async command void enableInputSchmittTrigger();
    async command void disableInputSchmittTrigger();
    async command bool isEnabledInputSchmittTrigger();
    
    async command void enableSlewControl();
    async command void disableSlewControl();
    async command bool isEnabledSlewControl();
    
    async command void enableInputGlitchFilter();
    async command void disableInputGlitchFilter();
    async command bool isEnabledInputGlitchFilter();
    
    async command void enableInterrupt();
    async command void disableInterrupt();
    async command bool isEnabledInterrupt();
    
    
    /**
     * 0 for A, 1 for B, 2 for C, 3 for D
     */
	async command void selectPeripheral(gpio_peripheral_mode_t peripheral);
	async command gpio_peripheral_mode_t getSelectedPeripheral();


    async command void setInterruptMode(gpio_interrupt_mode_t mode);
    async command gpio_interrupt_mode_t getInterruptMode();
    

}
