
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

    void AST_ALARM_Handler() @C() @spontaneous()
    {
        signal HplAST.alarmFired();
    }

    void AST_OVF_Handler() @C() @spontaneous()
    {
        signal HplAST.overflowFired();
    }

    command error_t Init.init()
    {
    
        irqflags_t flags;
	    uint32_t temp;
	    ast_config_t astcfg;

	    flags = cpu_irq_save();
	    temp = BSCIF->BSCIF_RC32KCR;
	    BSCIF->BSCIF_UNLOCK = BSCIF_UNLOCK_KEY(0xAAu)
		    | BSCIF_UNLOCK_ADDR((uint32_t)&BSCIF->BSCIF_RC32KCR - (uint32_t)BSCIF);
	    BSCIF->BSCIF_RC32KCR = temp | BSCIF_RC32KCR_EN32K | BSCIF_RC32KCR_EN;
	    cpu_irq_restore(flags);
	
        bpm_set_clk32_source(BPM, BPM_CLK32_SOURCE_RC32K);
        
        
        astcfg.mode = AST_COUNTER_MODE;
        astcfg.osc_type = AST_OSC_32KHZ;
        astcfg.psel = 3; //1Khz ticks
        astcfg.counter = 0;
        ast_enable(AST);
        ast_set_config(AST, &astcfg);
        NVIC_ClearPendingIRQ(AST_ALARM_IRQn);
        NVIC_ClearPendingIRQ(AST_OVF_IRQn);
        NVIC_SetPriority(AST_ALARM_IRQn, 15);
        NVIC_SetPriority(AST_OVF_IRQn, 15);
        NVIC_EnableIRQ(AST_ALARM_IRQn);
        NVIC_EnableIRQ(AST_OVF_IRQn);
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
