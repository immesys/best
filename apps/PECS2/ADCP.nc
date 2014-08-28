
#include <adcife.h>
#include <ioport.h>

module ADCP
{
    provides interface ADC;
}
implementation
{
    struct adc_dev_inst g_adc_inst;
    void adcife_read_conv_result(void)
    {
        // Check the ADC conversion status
        if ((adc_get_status(&g_adc_inst) & ADCIFE_SR_SEOC) == ADCIFE_SR_SEOC){
            uint16_t dat = adc_get_last_conv_value(&g_adc_inst);
            adc_clear_status(&g_adc_inst, ADCIFE_SCR_SEOC);
            bl_printf("Got ADC result %d\n", dat);
            signal ADC.sampleComplete(dat);
        }
    }

    struct adc_config adc_cfg = {
        // System clock division factor is 16
        .prescal = ADC_PRESCAL_DIV128,
        // The APB clock is used
        .clksel = ADC_CLKSEL_APBCLK,
        // Max speed is 150K
        .speed = ADC_SPEED_150K,
        // ADC Reference voltage is 1V
        .refsel = ADC_REFSEL_0,
        // Enables the Startup time
        .start_up = CONFIG_ADC_STARTUP
    };
    struct adc_seq_config adc_seq_cfg = {
        // Select Vref for shift cycle
        .zoomrange = ADC_ZOOMRANGE_0,
        // Pad Ground
        .muxneg = ADC_MUXNEG_1,
        // AD0 pin
        .muxpos = ADC_MUXPOS_0,
        // Enables the internal voltage sources
        .internal = ADC_INTERNAL_2,
        // Disables the ADC gain error reduction
        .gcomp = ADC_GCOMP_DIS,
        // Disables the HWLA mode
        .hwla = ADC_HWLA_DIS,
        // 12-bits resolution
        .res = ADC_RES_12_BIT,
        // Enables the single-ended mode
        .bipolar = ADC_BIPOLAR_SINGLEENDED
    };

	struct adc_ch_config adc_ch_cfg = {
		.seq_cfg = &adc_seq_cfg,
		/* Internal Timer Max Counter */
		.internal_timer_max_count = 60,
		/* Window monitor mode is off */
		.window_mode = 0,
		.low_threshold = 0,
		.high_threshold = 0,
	};

    command void ADC.config()
    {
        ioport_set_pin_mode(PIN_PA04A_ADCIFE_AD0, MUX_PA04A_ADCIFE_AD0);
        ioport_disable_pin(PIN_PA04A_ADCIFE_AD0);

        adc_init(&g_adc_inst, ADCIFE, &adc_cfg);
        adc_enable(&g_adc_inst);
        adc_ch_set_config(&g_adc_inst, &adc_ch_cfg);
        adc_set_callback(&g_adc_inst, ADC_SEQ_SEOC, adcife_read_conv_result,
             ADCIFE_IRQn, 1);

        adc_configure_trigger(&g_adc_inst, ADC_TRIG_SW);
        adc_configure_gain(&g_adc_inst, ADC_GAIN_1X);
    }

     async command void ADC.sample()
     {
        adc_start_software_conversion(&g_adc_inst);
     }
     //async event void sampleComplete(uint16_t r);

}