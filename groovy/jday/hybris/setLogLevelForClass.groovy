package jday.hybris

import org.apache.logging.log4j.*;
import org.apache.logging.log4j.core.config.*;
import de.hybris.platform.util.logging.log4j2.HybrisLoggerContext;

// example:
setLogger("de.hybris.platform.jalo.flexiblesearch.FlexibleSearch", "DEBUG");

public String setLogger(String logClass, String logLevel) {
    final HybrisLoggerContext loggerCtx = (HybrisLoggerContext) LogManager.getContext(false);
    final Configuration loggerCfg = loggerCtx.getConfiguration();
    LoggerConfig loggerConfig = loggerCfg.getLoggers().get(logClass);
    if (loggerConfig == null) {
// create
        String additivity = "true";
        String includeLocation = "true";
        Property[] properties = null;
        AppenderRef[] refs = [];
        filter = null;
        LoggerConfig createdLoggerConfig = LoggerConfig.createLogger(
                additivity,
                Level.getLevel(logLevel),
                logClass,
                includeLocation,
                refs,
                properties,
                loggerCfg,
                filter
        );

        loggerCfg.addLogger(logClass, createdLoggerConfig);
    } else {

        loggerCfg.getLoggers().get(logClass).setLevel(Level.getLevel(logLevel));
    }
    loggerCtx.updateLoggers();
}