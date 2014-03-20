
module HplRF233P
{
	provides
	{
		interface Init as PlatformInit;
	}

	uses
	{
		interface GeneralIO as PortSLP_TR;
	}
}

implementation
{
	command error_t PlatformInit.init()
	{
		call PortSLP_TR.makeOutput();
		call PortSLP_TR.clr();
		return SUCCESS;
	}
}
