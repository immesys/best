/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * The implementation of the standard 3 LED mote abstraction.
 * Adapted because LED 2 (red) is active high on SAM3U_EK.
 *
 * @author Joe Polastre
 * @author Philip Levis
 * @author Wanja Hofer <wanja@cs.fau.de>
 *
 * @date   March 21, 2005
 */

module LedsP @safe() {
  provides {
    interface Init;
    interface Leds;
  }
}
implementation {
  command error_t Init.init() {
    
    return SUCCESS;
  }


  async command void Leds.led0On() {

  }

  async command void Leds.led0Off() {

  }

  async command void Leds.led0Toggle() {

  }

  async command void Leds.led1On() {

  }

  async command void Leds.led1Off() {

  }

  async command void Leds.led1Toggle() {

  }

  async command void Leds.led2On() {

  }

  async command void Leds.led2Off() {

  }

  async command void Leds.led2Toggle() {

  }

  async command uint8_t Leds.get() {
    return 0;
  }

  async command void Leds.set(uint8_t val) {
  }
}
