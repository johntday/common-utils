package jday.hybris
/**
 * Hybris groovy script
 * Print spring beans for CONTEXTNAME
 * Change CONTEXTNAME and run script in HAC
 */
CONTEXTNAME = "/rlpstorefront";

import de.hybris.platform.spring.HybrisContextLoaderListener;
import org.springframework.web.context.ContextLoader;
import org.springframework.web.context.WebApplicationContext;

def f = ContextLoader.getDeclaredField("currentContextPerThread");
f.setAccessible(true);
appContext = null;
Map<ClassLoader, WebApplicationContext> contexts = f.get(HybrisContextLoaderListener);
for (loader in contexts) {
	contextName = loader.getKey().getContextName();
	if (contextName == CONTEXTNAME) {
		appContext = loader.getValue();
	}
}

if (appContext == null) { 
	println "context is not found for '${CONTEXTNAME}'.  Using 'ROOT' context name";
	println "";
	CONTEXTNAME = 'ROOT';
	for (loader in contexts) {
		contextName = loader.getKey().getContextName();
		if (contextName == CONTEXTNAME) {
			appContext = loader.getValue();
		}
	}
	if (appContext == null) {
		println "context is not found for '${CONTEXTNAME}'";
		return;
	}
}

printAllBeans(appContext);

void printAllBeans(context)
{
	beanFactory = context.getAutowireCapableBeanFactory()
	for (String beanName : beanFactory.getBeanDefinitionNames()) {
		println beanName;
	}
}
