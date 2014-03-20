
#include "Timer.h"

configuration LocalTimeMilliC {
  provides interface LocalTime<TMilli>;
}
implementation
{
  components TimingC;

  LocalTime = TimingC.LocalTimeMilli;
}
