
#include <stdio.h>
#include <stdarg.h>
#include <ast.h>

char swo_buffer[128];

int _write(int fd, const void *buf, size_t count)
{
    return 0;
}
int _read(int fd, void *buf, size_t count)
{
    return 0;
}
void sdebug_init()
{
    CoreDebug->DEMCR |= CoreDebug_DEMCR_TRCENA_Msk;
    ITM->TCR = 0b1000001001;
    ITM->TER = 1;
}
void sdebug(char* fmt, ...)
{
    va_list args;
    int cnt;
    char* p = &swo_buffer[0];
    va_start(args, fmt);
        
    cnt = vsnprintf(&swo_buffer[0], 128, fmt, args);

    while(cnt > 0)
    {
        while (ITM->PORT[0].u32 == 0);
        ITM->PORT[0].u8 = *p++;
        cnt--;
    }
    
    va_end(args);
}
