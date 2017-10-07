using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;

namespace CSTimer
{
    public class RandoClass
    {
        [Microsoft.Azure.WebJobs.FunctionNameAttribute("std-artist-tally-tool")]
        public void Run(TimerInfo myTimer, TraceWriter log)
        {
            log.Info("My C# timer is running!!!!!")
        }
    }
}
