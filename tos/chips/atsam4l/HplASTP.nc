
#include <ast.h>
#include <bpm.h>

module HplASTP
{
    provides
    {
        interface HplAST;
        interface Init;
    }
}
implementation
{

    void foo_AST_ALARM_Handler() @C() @spontaneous()
    {
       // signal HplAST.alarmFired();
    //     ioport_toggle_pin_level(PIN_PB08);
   // ioport_toggle_pin_level(PIN_PB08);
        signal HplAST.alarmFired();
     /*   ast_clear_interrupt_flag(AST, AST_INTERRUPT_ALARM);
    ast_stop(AST);
    ast_write_counter_value(AST, 0);
    ast_write_alarm0_value(AST, 100);
    ast_start(AST);*/
    }

    void AST_OVF_Handler() @C() @spontaneous()
    {
        
        signal HplAST.overflowFired();
    }

    command error_t Init.init()
    {
        struct ast_config ast_conf;
        ast_enable(AST);
        ast_conf.mode = AST_COUNTER_MODE;
        ast_conf.osc_type = AST_OSC_RC;
        ast_conf.psel = 5;
        ast_conf.counter = 0;
        ast_set_config(AST, &ast_conf);
        ast_clear_interrupt_flag(AST, AST_INTERRUPT_ALARM);
        ast_set_callback(AST, AST_INTERRUPT_ALARM, foo_AST_ALARM_Handler, AST_ALARM_IRQn, 0);
        ast_stop(AST);
        
        //ast_write_counter_value(AST, 0);
      //  ast_write_alarm0_value(AST, 100);
     //   ast_enable_interrupt(AST, AST_INTERRUPT_ALARM);
     //   ast_start(AST);
    
   // while(1);
    #if 0
        

	    ast_config_t astcfg;
        

        
              //  irqflags_t flags;
	  //  uint32_t temp;
        
	 /*   flags = cpu_irq_save();
	    temp = BSCIF->BSCIF_RC32KCR;
	    BSCIF->BSCIF_UNLOCK = BSCIF_UNLOCK_KEY(0xAAu)
		    | BSCIF_UNLOCK_ADDR((uint32_t)&BSCIF->BSCIF_RC32KCR - (uint32_t)BSCIF);
	    BSCIF->BSCIF_RC32KCR = temp | BSCIF_RC32KCR_EN32K | BSCIF_RC32KCR_EN;
	    cpu_irq_restore(flags);
	
        bpm_set_clk32_source(BPM, BPM_CLK32_SOURCE_RC32K);
        */
        /*
        astcfg.mode = AST_COUNTER_MODE;
        astcfg.osc_type = AST_OSC_RC; //AST_OSC_32KHZ;
        astcfg.psel = 5; 
        astcfg.counter = 0;
        ast_enable(AST);
        ast_set_config(AST, &astcfg);
        call HplAST.stop();
        ast_set_callback(AST, AST_INTERRUPT_ALARM, foo_AST_ALARM_Handler, AST_ALARM_IRQn, 0);
        */
       /* NVIC_ClearPendingIRQ(AST_ALARM_IRQn);
        NVIC_ClearPendingIRQ(AST_OVF_IRQn);
        NVIC_SetPriority(AST_ALARM_IRQn, 0);
        NVIC_SetPriority(AST_OVF_IRQn, 0);
        NVIC_EnableIRQ(AST_ALARM_IRQn);
        NVIC_EnableIRQ(AST_OVF_IRQn);
        
        call HplAST.clearAlarmInterrupt();
        call HplAST.enableAlarmInterrupt();
        */
    
        
        ast_enable(AST);
    
    ast_conf.mode = AST_COUNTER_MODE;
    ast_conf.osc_type = AST_OSC_RC;
    ast_conf.psel = 5;
    ast_conf.counter = 0;
    ast_set_config(AST, &ast_conf);
    ast_clear_interrupt_flag(AST, AST_INTERRUPT_ALARM);
    ast_set_callback(AST, AST_INTERRUPT_ALARM, foo_AST_ALARM_Handler, AST_ALARM_IRQn, 0);
    ast_stop(AST);
    ast_write_counter_value(AST, 0);
    ast_write_alarm0_value(AST, 100);
    ast_enable_interrupt(AST, AST_INTERRUPT_ALARM);
    ast_start(AST);
        #endif
        return SUCCESS;
    }

    async command void HplAST.start()
    {
        while (ast_is_busy(AST));
        AST->AST_CR |= AST_CR_EN;
    }

    async command bool HplAST.isRunning()
    {
        return (AST->AST_CR & AST_CR_EN) != 0;
    }

    async command void HplAST.stop()
    {
        while (ast_is_busy(AST));
        AST->AST_CR &= ~(AST_CR_EN);
    }

    async command uint32_t HplAST.getCounterValue()
    {
        return AST->AST_CV;
    }

    async command void HplAST.setCounterValue(uint32_t v)
    {
        // Wait until write is ok
        while (ast_is_busy(AST));

        AST->AST_CV = v;

        // Wait until write complete
        while (ast_is_busy(AST));
    }

    async command void HplAST.setAlarmValue(uint32_t v)
    {
        // Wait until write is ok
        while (ast_is_busy(AST));

        AST->AST_AR0 = v;

        // Wait until write complete
        while (ast_is_busy(AST));
    }

    async command uint32_t HplAST.getAlarmValue()
    {
        return AST->AST_AR0;
    }

    async command void HplAST.enableAlarmInterrupt()
    {
        while (ast_is_busy(AST));
        AST->AST_IER = AST_IER_ALARM0_1;
        while (ast_is_busy(AST));
    }
    async command void HplAST.disableAlarmInterrupt()
    {
        while (ast_is_busy(AST));
        AST->AST_IDR = AST_IDR_ALARM0_1;
        while (ast_is_busy(AST));
    }
    async command void HplAST.clearAlarmInterrupt()
    {
        while (ast_is_busy(AST));
        AST->AST_SCR = AST_SCR_ALARM0;
        while (ast_is_busy(AST));
    }

    async command void HplAST.enableOverflowInterrupt()
    {
        while (ast_is_busy(AST));
        AST->AST_IER = AST_IER_OVF_1;
        while (ast_is_busy(AST));
    }
    async command void HplAST.disableOverflowInterrupt()
    {
        while (ast_is_busy(AST));
        AST->AST_IDR = AST_IDR_OVF_1;
        while (ast_is_busy(AST));
    }
    async command void HplAST.clearOverflowInterrupt()
    {
        while (ast_is_busy(AST));
        AST->AST_SCR = AST_SCR_OVF;
        while (ast_is_busy(AST));
    }
    

}
