using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;

namespace CSTimer
{
    public static class RandoClass
    {
        public static void Run(TimerInfo myTimer, TraceWriter log)
        {
            log.Info("My C# timer is running!!!!!");
        }
    }
}
