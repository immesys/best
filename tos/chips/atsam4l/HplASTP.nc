
#include <ast.h>
#include <bpm.h>
#include <sleepmgr.h>
#include <sysclk.h>

#include "bldebug.h"

module HplASTP
{
    provides
    {
        interface HplAST;
        interface Init;
        interface LocalTime<T32khz>;
        interface Counter<T32khz, uint32_t>;
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
        signal Counter.overflow();
    }

    inline void block_ast_busy()
    {
        while ( (AST->AST_SR & AST_SR_BUSY) != 0 );
    }
    inline void block_ast_clkbusy()
    {
        while ( (AST->AST_SR & AST_SR_CLKBUSY) != 0 );
    }

    command error_t Init.init()
    {
    
        uint32_t temp;
	    uint32_t pmcon;
	    
	    atomic
	    {
	        temp = BSCIF->BSCIF_RC32KCR;
	        BSCIF->BSCIF_UNLOCK = BSCIF_UNLOCK_KEY(0xAAu)
		        | BSCIF_UNLOCK_ADDR((uint32_t)&BSCIF->BSCIF_RC32KCR - (uint32_t)BSCIF);
	        BSCIF->BSCIF_RC32KCR = temp | BSCIF_RC32KCR_EN32K | BSCIF_RC32KCR_EN;
	    }
	    
	    // Set BPM to use RC32 for OSC32
	    pmcon = BPM->BPM_PMCON;
        pmcon |= BPM_PMCON_CK32S;
	    BPM->BPM_UNLOCK = BPM_UNLOCK_KEY(0xAAu) | BPM_UNLOCK_ADDR((uint32_t)&BPM->BPM_PMCON - (uint32_t)BPM);
	    BPM->BPM_PMCON = pmcon;

        sysclk_enable_peripheral_clock(AST);
	    sleepmgr_lock_mode(SLEEPMGR_BACKUP);

        block_ast_clkbusy();
	    
	    //Configure for OSC32
	    AST->AST_CLOCK = (AST_OSC_32KHZ) << AST_CLOCK_CSSEL_Pos;
	    block_ast_clkbusy();
	    AST->AST_CLOCK |= AST_CLOCK_CEN;
	    block_ast_clkbusy();

        //Configure counter mode with psel == 5 (1ms)
        //AST->AST_CR = (5) << AST_CR_PSEL_Pos;
        
        //Config counter with psel == 0 (16Khz)
        //We will shift it around to make it look like 32khz
        AST->AST_CR = (0) << AST_CR_PSEL_Pos;
        
        //Set counter to zero
        call HplAST.setCounterValue(0);
        call HplAST.clearAlarmInterrupt();

        NVIC_ClearPendingIRQ(AST_ALARM_IRQn);
        NVIC_ClearPendingIRQ(AST_OVF_IRQn);
        NVIC_SetPriority(AST_ALARM_IRQn, 0);
        NVIC_SetPriority(AST_OVF_IRQn, 0);
        NVIC_EnableIRQ(AST_ALARM_IRQn);
        NVIC_EnableIRQ(AST_OVF_IRQn);
        
        call HplAST.enableAlarmInterrupt();

        return SUCCESS;
    }

    async command void HplAST.start()
    {
        block_ast_busy();
        AST->AST_CR |= AST_CR_EN;
    }

    async command bool HplAST.isRunning()
    {
        return (AST->AST_CR & AST_CR_EN) != 0;
    }

    async command void HplAST.stop()
    {
        block_ast_busy();
        AST->AST_CR &= ~(AST_CR_EN);
    }

    async command uint32_t HplAST.getCounterValue()
    {
        block_ast_busy();
        //Pretend it's 32Khz
        return (AST->AST_CV << 1);
    }

    async command uint32_t LocalTime.get()
    {
        block_ast_busy();
        return (AST->AST_CV << 1);
    }
    
    async command uint32_t Counter.get()
    {
        block_ast_busy();
        return (AST->AST_CV << 1);
    }
    
    async command void HplAST.setCounterValue(uint32_t v)
    {
        
        // Wait until write is ok
        block_ast_busy();

        AST->AST_CV = (v >> 1);

        // Wait until write complete
        block_ast_busy();
    }

    async command void HplAST.setAlarmValue(uint32_t v)
    {
       // bl_printf("sav %u, ct %u\n",v, AST->AST_CV);
        // Wait until write is ok
        block_ast_busy();

        AST->AST_AR0 = (v >> 1);

        // Wait until write complete
        block_ast_busy();
    }

    async command uint32_t HplAST.getAlarmValue()
    {
        block_ast_busy();
        return (AST->AST_AR0 << 1);
    }

    async command void HplAST.enableAlarmInterrupt()
    {
        block_ast_busy();
        AST->AST_IER = AST_IER_ALARM0_1;
        block_ast_busy();
    }
    async command void HplAST.disableAlarmInterrupt()
    {
        block_ast_busy();
        AST->AST_IDR = AST_IDR_ALARM0_1;
        block_ast_busy();
    }
    async command void HplAST.clearAlarmInterrupt()
    {
        block_ast_busy();
        AST->AST_SCR = AST_SCR_ALARM0;
        block_ast_busy();
    }

    async command bool Counter.isOverflowPending()
    {
        block_ast_busy();
        return (AST->AST_SR & 1) != 0;
    }
    async command void Counter.clearOverflow()
    {
        block_ast_busy();
        AST->AST_SCR = AST_SCR_OVF;
        block_ast_busy();
    }
    
    async command void HplAST.enableOverflowInterrupt()
    {
        block_ast_busy();
        AST->AST_IER = AST_IER_OVF_1;
        block_ast_busy();
    }
    async command void HplAST.disableOverflowInterrupt()
    {
        block_ast_busy();
        AST->AST_IDR = AST_IDR_OVF_1;
        block_ast_busy();
    }
    async command void HplAST.clearOverflowInterrupt()
    {
        block_ast_busy();
        AST->AST_SCR = AST_SCR_OVF;
        block_ast_busy();
    }
    

}
