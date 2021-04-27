package jday.hybris

import de.hybris.platform.servicelayer.internal.model.ScriptingJobModel;
import de.hybris.platform.cronjob.model.CronJobModel;

scriptName = "tmpHacScript" /* change to be your saved scriptName saved in HAC */
CRONJOBNAME="tmpHacScriptCronJob";
MYHACSCRIPTJOBNAME = "tmpHacScriptJob"
def scriptingJob = null;
def myHacScriptDynamicCronJob = null;
scriptingJobResults = flexibleSearchService.search("select {pk} from {ScriptingJob} where {code} = '"+MYHACSCRIPTJOBNAME+"'").getResult();
if (scriptingJobResults.size()>0) { scriptingJob = scriptingJobResults.get(0) }
else {
	scriptingJob = modelService.create(ScriptingJobModel.class);
	scriptingJob.setCode(MYHACSCRIPTJOBNAME);
	scriptingJob.setScriptURI("model://"+scriptName);
	modelService.save(scriptingJob);
}

try {
	myHacScriptDynamicCronJob = cronJobService.getCronJob(CRONJOBNAME);
} catch (de.hybris.platform.servicelayer.exceptions.UnknownIdentifierException e) {
	myHacScriptDynamicCronJob = modelService.create(CronJobModel.class);
	myHacScriptDynamicCronJob.setCode(CRONJOBNAME);
	myHacScriptDynamicCronJob.setJob(scriptingJob);
	myHacScriptDynamicCronJob.setActive(true);
	myHacScriptDynamicCronJob.setSingleExecutable(true);
	myHacScriptDynamicCronJob.setLogToFile(true);
	modelService.save(myHacScriptDynamicCronJob);
}
dynamicCJ = cronJobService.getCronJob(CRONJOBNAME)
cronJobService.performCronJob(dynamicCJ,true)
