package jday.hybris

import de.hybris.platform.core.Registry;
import de.hybris.platform.ruleengine.RuleEngineService;
import de.hybris.platform.ruleengine.RuleEngineActionResult;

println "--reload has started"
RuleEngineService ruleEngineService = (RuleEngineService) Registry.getApplicationContext().getBean("platformRuleEngineService");
List<RuleEngineActionResult> ruleEngineActionResults = ruleEngineService.initializeAllRulesModules();
ruleEngineActionResults.each {
	println "Action Failed? - ${it.isActionFailed()}"
}

println "--reload ended"
