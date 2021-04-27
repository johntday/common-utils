package jday.hybris

import de.hybris.platform.core.Registry;
import de.hybris.platform.ruleengineservices.rule.services.RuleService;
import de.hybris.platform.ruleengineservices.maintenance.RuleMaintenanceService;
import de.hybris.platform.ruleengineservices.maintenance.RuleCompilerPublisherResult;

println "Publishing Rules"
RuleService ruleService = (RuleService) Registry.getApplicationContext().getBean("ruleService");
RuleMaintenanceService ruleMaintenanceService = (RuleMaintenanceService) Registry.getApplicationContext().getBean("ruleMaintenanceService");
RuleCompilerPublisherResult rcpResult = ruleMaintenanceService.compileAndPublishRules(ruleService.getAllToBePublishedRules());
println "----------------"
println "Rule status call"
println (rcpResult.getResult())
println "$rcpResult.getResult()"
println "----------------"
println "Job Complete"
return
