package jday.hybris

STOREFRONTCONTEXT = "/dealersupport";

import de.hybris.platform.spring.HybrisContextLoaderListener;
import org.springframework.web.context.ContextLoader;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.bind.annotation.RequestMapping;
import java.lang.reflect.*;
import java.lang.annotation.Annotation;
def f = ContextLoader.getDeclaredField("currentContextPerThread");
f.setAccessible(true);
appContext = null;
Map<ClassLoader, WebApplicationContext> contexts = f.get(HybrisContextLoaderListener);
for (loader in contexts) {
    contextName = loader.getKey().getContextName();
    if (contextName == STOREFRONTCONTEXT) {
        appContext = loader.getValue();
    }
}

if (appContext == null) { 
    println ("context is not found. Please set up STOREFRONTCONTEXT");
    return;
}

beanMap = appContext.getBeanNamesForAnnotation(RequestMapping.class);

for (beanName in beanMap) {
    requestMapping(appContext.getBean(beanName).getClass());
}

String requestMapping(Class clazz) {
    classValue = "";
    if (clazz.getDeclaredAnnotations()) {
        for(Annotation annotation :clazz.getDeclaredAnnotations()){
            if(annotation.toString().contains("RequestMapping"))
            printAnnotation(annotation, "class", null, clazz, "");
            classValue = getValue("value", annotation.toString());
        }
    }
    for(Method method :clazz.getMethods()){
        for(Annotation annotation :method.getDeclaredAnnotations()){
            if(annotation.toString().contains("RequestMapping"))
                printAnnotation(annotation, "method", method, clazz, classValue);
        }
    }
}

String printAnnotation(Annotation annotation, String type, Method method, Class clazz, String classValue) {
    print clazz?.getSimpleName() + "\t"+
    ((method==null)?"":method.getName()) + "\t" +
    getValue("method", annotation.toString()) + "\t" +
    classValue + getValue("value", annotation.toString()) + "\t" +
    getValue("param", annotation.toString()) + "\n";
    ;
}

String getValue(String param, String annotation) {
    retValue = "";
    annotation.findAll(/$param=\[(.*?)\]/) { full, value -> retValue = value; }
    return retValue;
}
