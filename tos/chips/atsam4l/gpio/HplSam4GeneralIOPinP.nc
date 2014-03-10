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

generic module HplSam4GeneralIOPinP(uint32_t gpio_addr, uint8_t bit)
{
	provides
	{
		interface GeneralIO as IO;
     //   interface GpioInterrupt as Interrupt;
   //     interface GpioCapture as Capture;
		interface HplSam4GeneralIOPin as AdvCtl;
	}
}
implementation
{
    GpioPort *gpio = (GpioPort*) gpio_addr;
    
	async command bool IO.get()
	{
	    return (gpio->GPIO_PVR & (1 << bit)) != 0;
	}

	async command void IO.set()
	{
	    gpio->GPIO_OVRS =  1 << bit;
	}

	async command void IO.clr()
	{
	    gpio->GPIO_OVRC =  1 << bit;
	}

	async command void IO.toggle()
	{
	    gpio->GPIO_OVRT = 1 << bit;
	}

	async command void IO.makeInput()
	{
	    gpio->GPIO_ODERC = 1 << bit;
//XTAG we need a mechanism for keeping track of active bits in a port
//to control clocks
    }

	async command void IO.makeOutput()
	{
		gpio->GPIO_ODERS = 1 << bit;
//XTAG we need a mechanism for keeping track of active bits in a port
//to control clocks
    }

	async command bool IO.isOutput()
	{
		return (gpio->GPIO_ODER & (1 << bit)) != 0;
	}

	async command bool IO.isInput()
	{
		return (gpio->GPIO_ODER & (1 << bit)) == 0;
	}

	async command void AdvCtl.enableGPIO()
	{
	    gpio->GPIO_GPERS = 1 << bit;
	}

    async command void AdvCtl.disableGPIO()
	{
		gpio->GPIO_GPERC = 1 << bit;
	}
	
	async command bool AdvCtl.isEnabledGPIO()
	{
		return (gpio->GPIO_GPER & (1 << bit)) != 0;
	}
	
	async command void AdvCtl.enableStrongDrive()
	{
	    gpio->GPIO_ODCR0S = 1 << bit;
	}
	
	async command void AdvCtl.disableStrongDrive()
	{
	    gpio->GPIO_ODCR0C = 1 << bit;
	}

    async command bool AdvCtl.isEnabledStrongDrive()
	{
	    return (gpio->GPIO_ODCR0 & (1 << bit)) != 0;
	}
	
	async command void AdvCtl.setResistorMode(gpio_resistor_mode_t mode)
	{
	    switch(mode)
	    {
	        case RESMODE_DISABLED:
	            //PUER (CLR) + PDER (CLR)
	            gpio->GPIO_PUERC = 1 << bit;
	            gpio->GPIO_PDERC = 1 << bit;
	            break;
            case RESMODE_PULLUP:
            	gpio->GPIO_PUERS = 1 << bit;
	            gpio->GPIO_PDERC = 1 << bit;
                break;
            case RESMODE_PULLDOWN:
                gpio->GPIO_PUERC = 1 << bit;
	            gpio->GPIO_PDERS = 1 << bit;
                break;
            case RESMODE_KEEPER:
                gpio->GPIO_PUERS = 1 << bit;
	            gpio->GPIO_PDERS = 1 << bit;
	            break;
	    }
	}
	
	async command gpio_resistor_mode_t AdvCtl.getResistorMode()
	{
	    //Check PUER
	    if ((gpio->GPIO_PUER & (1 << bit)) != 0)
	    {
	        //Check PDER
	        if ((gpio->GPIO_PDER & (1 << bit)) != 0)
	        {
	            return RESMODE_KEEPER;
	        }
	        else
	        {
	            return RESMODE_PULLUP;
	        }
	    }
	    else if ((gpio->GPIO_PDER & (1 << bit)) != 0)
	    {
	        return RESMODE_PULLDOWN;
	    }
	    else
	    {
	        return RESMODE_DISABLED;
	    }
	}
	
    async command void AdvCtl.enableInputSchmittTrigger() {}
    async command void AdvCtl.disableInputSchmittTrigger() {}
    async command bool AdvCtl.isEnabledInputSchmittTrigger() {return FALSE;}
    
    async command void AdvCtl.enableSlewControl() {}
    async command void AdvCtl.disableSlewControl() {}
    async command bool AdvCtl.isEnabledSlewControl() {return FALSE;}
    
    async command void AdvCtl.enableInputGlitchFilter() {}
    async command void AdvCtl.disableInputGlitchFilter() {}
    async command bool AdvCtl.isEnabledInputGlitchFilter() {return FALSE;}
    
    async command void AdvCtl.enableInterrupt() {}
    async command void AdvCtl.disableInterrupt() {}
    async command bool AdvCtl.isEnabledInterrupt() {return FALSE;}

        
    /**
     * 0 for A, 1 for B, 2 for C, 3 for D
     */
	async command void AdvCtl.selectPeripheral(gpio_peripheral_mode_t peripheral) {}
	async command gpio_peripheral_mode_t AdvCtl.getSelectedPeripheral() {return PERIPHERAL_A;}


    async command void AdvCtl.setInterruptMode(gpio_interrupt_mode_t mode) {}
    async command gpio_interrupt_mode_t AdvCtl.getInterruptMode() {return IRQ_DISABLED;}
    
}

