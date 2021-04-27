package jday.hybris

import de.hybris.platform.core.PK;
import de.hybris.platform.core.model.ItemModel;
import de.hybris.platform.category.model.CategoryModel;
import de.hybris.platform.core.model.product.ProductModel;
import de.hybris.platform.catalog.model.*;
import de.hybris.platform.catalog.model.synchronization.CatalogVersionSyncCronJobModel;
import de.hybris.platform.catalog.model.synchronization.CatalogVersionSyncScheduleMediaModel;
import de.hybris.platform.cronjob.enums.CronJobResult
import de.hybris.platform.cms2.model.navigation.*;
import de.hybris.platform.cms2.model.contents.components.CMSLinkComponentModel;
import de.hybris.platform.catalog.model.synchronization.CatalogVersionSyncCronJobHistoryModel;
import de.hybris.platform.catalog.model.synchronization.CatalogVersionSyncJobModel;
import de.hybris.platform.servicelayer.search.SearchResult;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.collections4.CollectionUtils;
import org.springframework.util.Assert

import java.nio.charset.*

import de.hybris.platform.servicelayer.exceptions.ModelLoadingException;
//https://www.sap.com/cxworks/article/432582396/Catalog_Synchronization

// USE EMAIL TO SEND RESULTS
USEEMAIL = false
/* CHANGE THE FOLLOWING EMAIL PARMS */
TOLIST=['john.day@capgemini.com','matt.putnam@capgemini.com','david.joly@capgemini.com','pacifico.gonzales@capgemini.com']
FROM = "test@hybris.de"
SUBJECT = "Hybris ${getEnvString()} Sync Reports ${(new java.text.SimpleDateFormat('MMM-dd HH:mm')).format(new java.util.Date())} UTC"


// CONSTANTS
REPLYTO = FROM
MSG = new StringBuilder()
MSG.append '<h2>Summary of Last Full Sync Jobs</h2>'
MSG.append '<p><a href="https://lyonscg.atlassian.net/wiki/spaces/HD/pages/783583058/SAPCC+Report+for+Troubleshooting+Synchronization+Jobs">Sync Report Job Documentation</a></p>'
MSG.append '<p>Full report can be found in backoffice on cronjob "syncReportScriptCronJob" field "Log Files" on LOG tab</p>'
MSG.append '<ol>'
STYLE_GOOD='font-weight:bold;color:white;background-color:green'
STYLE_ERR='font-weight:bold;color:white;background-color:red'

// Create the email
if (USEEMAIL)
{
	email = de.hybris.platform.util.mail.MailUtils.getPreConfiguredEmail()
	for (item in TOLIST) {
		email.addTo(item)
	}
	email.from = FROM
	email.addReplyTo(REPLYTO)
	email.subject = SUBJECT
}

/* ----------------------------------- MAIN LOOP ------------------------------------------ */
SearchResult jobs = getSyncJobs();
for (job in jobs.getResult())
{
	CatalogVersionSyncCronJobModel cronjob = getLastFullSyncCronjob( job.getCode() );
	if (cronjob != null) {
	  Context context = new Context();
	  context.jobCode = job.getCode();
	  context.cronjob = cronjob;
	  
	  def statusLine, dumpedItemsCount=0, processedItemsCount=0, scheduledItemsCount=0, failureMessage;
		CatalogVersionSyncCronJobHistoryModel cronjobHistory = null;
		List<CatalogVersionSyncCronJobHistoryModel> cronjobHistorys = cronjob.getCronJobHistoryEntries();
		if (cronjobHistorys != null && cronjobHistorys.size() > 0) {
			cronjobHistory = cronjobHistorys.get(0);
			dumpedItemsCount = cronjobHistory.getDumpedItemsCount();
			processedItemsCount = cronjobHistory.getProcessedItemsCount();
			scheduledItemsCount = cronjobHistory.getScheduledItemsCount();
			statusLine = cronjobHistory.getStatusLine();
			failureMessage = cronjobHistory.getFailureMessage();
		}
		println();
		println();
		println '########################################################################################'
		println "Job Code        (Job.code)                           = ${context.jobCode}"
		println "Cronjob Code    (Cronjob.code)                       = ${context.cronjob.getCode()}"
		println "Start Time      (Cronjob.startTime)                  = ${cronjob.getStartTime()}"
		println "End Time        (Cronjob.startTime)                  = ${cronjob.getEndTime()}"
		println "Full Sync       (Cronjob.fullSync)                   = ${cronjob.getFullSync()}"
		println "Force Update    (Cronjob.forceUpdate)                = ${cronjob.getForceUpdate()}"
		println "Result          (Cronjob.startTime)                  = ${cronjob.getResult()}"
		println "Status          (Cronjob.startTime)                  = ${cronjob.getStatus()}"
		println "Status Line     (CronJobHistory.statusLine)          = ${statusLine}"
		println "Status Message  (Cronjob.statusMessage)              = ${cronjob.getStatusMessage()}"
		println "Scheduled Count (CronJobHistory.processedItemsCount) = ${processedItemsCount}"
		println "Processed Count (CronJobHistory.scheduledItemsCount) = ${scheduledItemsCount}"
		println "Dumped Count    (CronJobHistory.dumpedItemsCount)    = ${dumpedItemsCount}"
		println "Failure Message (CronJobHistory.failureMessage)      = ${failureMessage}"
		println '########################################################################################'

		msgSummary( "${context.jobCode} (${context.cronjob.getCode()})", (CronJobResult.SUCCESS == cronjob.getResult()) )
		
		if (CronJobResult.SUCCESS != cronjob.getResult()) {
			processScheduleMedia( context, cronjob.getScheduleMedias() );
		}
	}
}

// send email
if (USEEMAIL)
{
	email.msg = MSG.append('</ol>').toString();
	email.send();
}

/* ----------------------------------- PRIVATE METHODS ------------------------------------------ */
	private void processScheduleMedia(Context context, List<CatalogVersionSyncScheduleMediaModel> syncSchds)
	{
		if (CollectionUtils.isNotEmpty(syncSchds)) 
		{
			final CatalogVersionSyncScheduleMediaModel syncSchd = findFirstScheduleMedia( syncSchds );
			if (syncSchd == null) return;
			
			def pw;
			def fileName = context.cronjob.code;
			try
			{
				// Create a temporary file
				if (USEEMAIL)
				{
					file = File.createTempFile(fileName,".csv")
					file.deleteOnExit()
					pw = new PrintWriter(file)
					pw.println '"Item Type Name","Source PK","Source Unique Keys:Values","Source Msg","Target PK","Target Unique Keys:Values","Target Msg","Pending Attributes","Reference PKs","Is Source  Modified"';
				}
				println '"Item Type Name","Source PK","Source Unique Keys:Values","Source Msg","Target PK","Target Unique Keys:Values","Target Msg","Pending Attributes","Reference PKs","Is Source  Modified"';

				String thisLine = null;
				final BufferedReader br = new BufferedReader(new InputStreamReader(mediaService.getDataStreamFromMedia(syncSchd), StandardCharsets.UTF_8));
	   
				while ((thisLine = br.readLine()) != null) 
				{
					columns = thisLine.split( ';' );
					Assert.noNullElements( columns );
					// 8803273703425;8803284058113;8865377747563;galleryImages;;false
					String sourcePk = columns[0];
					String targetPk = columns[1];
					String itemsynctimestampPk = columns[2];
					String pendingAttributes = columns[3];
					String column4 = columns[4];
					String isSourceModified = columns[5];
					
					def sourceMsg = [];
					def targetMsg = [];
					def sourceItem = null;
					def targetItem = null;
					
					String itemTypeName = '';
					
					if (StringUtils.isNotEmpty(sourcePk)) {
						try {
							sourceItem = modelService.get( PK.parse(sourcePk) );
							itemTypeName = sourceItem.getItemtype();
						} catch(ModelLoadingException e) {
							sourceMsg.add(e.getMessage());
						}
					}
					if (StringUtils.isNotEmpty(targetPk)) {
						try {
							targetItem = modelService.get( PK.parse(targetPk) );
						} catch(ModelLoadingException e) {
							targetMsg.add(e.getMessage());
						}
					}
					
					additionalTypeProcessing(sourceItem, targetItem, sourceMsg, targetMsg);
					println "${itemTypeName},${sourcePk},\"${getUniqueKeys(sourceItem)}\",\"${sourceMsg}\",${targetPk},\"${getUniqueKeys(targetItem)}\",\"${targetMsg}\",\"${pendingAttributes}\",${column4},${isSourceModified}";
					if (USEEMAIL) {
						pw.println "${itemTypeName},${sourcePk},\"${getUniqueKeys(sourceItem)}\",\"${sourceMsg}\",${targetPk},\"${getUniqueKeys(targetItem)}\",\"${targetMsg}\",\"${pendingAttributes}\",${column4},${isSourceModified}";					
					}
				}
				
				// Create an attachment
				if (USEEMAIL)
				{
					attachment = new org.apache.commons.mail.EmailAttachment();
					attachment.disposition = org.apache.commons.mail.EmailAttachment.ATTACHMENT
					attachment.path = file.absolutePath
					attachment.name = "${fileName}.csv"
					email.attach(attachment)
				}
			} 
			catch (Exception e) 
			{
				println e
			} 
			finally 
			{
				if (pw != null) { pw.close() }
			}
		}//if
	}//processScheduleMedia
	
	/**
	 * START: project related additional attributes for reporting
	 */
	private void additionalTypeProcessing(ProductReferenceModel sourceItem, ProductReferenceModel targetItem, def sourceMsg, def targetMsg)
	{
		if (sourceItem != null) {
			sourceMsg.add( ['source.visibleOnSites':sourceItem.source.visibleOnSites, 'target.visibleOnSites':sourceItem.target.visibleOnSites] );
		}
		if (targetItem != null) {
			targetMsg.add( ['source.visibleOnSites':targetItem.source.visibleOnSites, 'target.visibleOnSites':targetItem.target.visibleOnSites] );
		}
	}
	private void additionalTypeProcessing(def sourceItem, def targetItem, def sourceMsg, def targetMsg)
	{
		if (sourceItem != null && (sourceItem instanceof ProductModel || sourceItem instanceof CategoryModel)) {
			sourceMsg.add( [visibleOnSites:sourceItem.visibleOnSites] );
		}
		if (targetItem != null && (targetItem instanceof ProductModel || targetItem instanceof CategoryModel)) {
			targetMsg.add( [visibleOnSites:targetItem.visibleOnSites] );
		}
	}
	/**
	 * END: project related additional attributes for reporting
	 */

	private void additionalTypeProcessing(CMSNavigationNodeModel sourceItem, CMSNavigationNodeModel targetItem, def sourceMsg, def targetMsg)
	{
		if (sourceItem != null) {
			sourceMsg.add( "(CMSNavigationNode) ${getItem(sourceItem)}" );
		}
		if (targetItem != null) {
			targetMsg.add( "(CMSNavigationNode) ${getItem(targetItem)}" );
		}
	}
	private void additionalTypeProcessing(CMSNavigationEntryModel sourceItem, CMSNavigationEntryModel targetItem, def sourceMsg, def targetMsg)
	{
		if (sourceItem != null) {
			sourceMsg.add( "(CMSNavigationEntry) ${getItem(sourceItem)}" );
		}
		if (targetItem != null) {
			targetMsg.add( "(CMSNavigationEntry) ${getItem(targetItem)}" );
		}
	}
	private def getItem(CMSNavigationNodeModel item)
	{
		def returnValue = [:];
		if (item != null) {
			returnValue.put('title', item.title);	
			returnValue.put('visible', item.visible);
			returnValue.put('parent (CMSNavigationNode)', getUniqueKeys(item.parent));

			def children = [];
			if (item.children != null) {
				for (child in item.children)
				{
					children.add( getItem(child) );
				}
			}
			returnValue.put('children (CMSNavigationNode)', children);

			def entries = [];
			if (item.entries != null) {
				for (entry in item.entries)
				{
					entries.add( getItem( entry ) );
				}
			}
			returnValue.put('entries (CMSNavigationEntry)', entries);

			def links = [];
			if (item.links != null) {
				for (link in item.links)
				{
					links.add( getItem( link ) );
				}
			}
			returnValue.put('links (CMSLinkComponent)', links);
		}
		
		return returnValue;
	}
	private def getItem(CMSNavigationEntryModel item)
	{
		def returnValue = [:];
		if (item != null) {
			returnValue = getUniqueKeys(item);
			returnValue.put('item', getUniqueKeys(item.item));
		}		
		return returnValue;
	}
	private def getItem(CMSLinkComponentModel item)
	{
		def returnValue = [:];
		if (item != null) {
			returnValue = getUniqueKeys(item);
			returnValue.put('linkName', item.getLinkName());
			returnValue.put('url', getUniqueKeys(item.url));
			returnValue.put('external', getUniqueKeys(item.external));
			returnValue.put('contentPageLabelOrId', getUniqueKeys(item.contentPageLabelOrId));
			returnValue.put('product', getUniqueKeys(item.product));
			returnValue.put('category', getUniqueKeys(item.category));
		}		
		return returnValue;
	}
	private CatalogVersionSyncScheduleMediaModel findFirstScheduleMedia(List<CatalogVersionSyncScheduleMediaModel> syncSchds)
	{
		Assert.notNull(syncSchds, 'syncSchds');
		returnValue = null;
		for (syncSchd in syncSchds)
		{
			if (syncSchd.getRealFileName().endsWith('.csv')) {
				returnValue = syncSchd;
			}
		}
		return returnValue;
	}

	private def getUniqueKeys(def item, String prefix = '')
	{
		if (item == null)
			return [:];
		Set<String> uniqueAttributes = typeService.getUniqueAttributes(item.getItemtype());
		def returnValue = [:];
		if (CollectionUtils.isNotEmpty(uniqueAttributes))
		{
			for (key in uniqueAttributes)
			{
				String prefixKey = ( StringUtils.isNotEmpty(prefix) ? "${prefix}.${key}" : key );
				try 
				{
					if (key == 'catalogVersion')
					{
						returnValue[prefixKey] = formatCatalogVersion(item);
					} else if (item."$key" instanceof ItemModel) {
						returnValue[prefixKey] = getUniqueKeys(item."$key", prefix);
					} else {
						def value = item."$key";
						returnValue[prefixKey] = value;
					}
				} catch(Exception e) {
					println( "Problem with script: ${e}" );
				}
			}	
		}
		return returnValue;
	}
	
	private SearchResult getSyncJobs()
	{
		String query = "SELECT {pk} FROM {CatalogVersionSyncJob} WHERE {CatalogVersionSyncJob.code} NOT LIKE 'Sync Default%' ORDER BY {CatalogVersionSyncJob.code}";
		SearchResult<CatalogVersionSyncJobModel> results = flexibleSearchService.search(query);
		return results;
	}
	
	private String formatCatalogVersion(def item)
	{
		return "${item.getCatalogVersion().getCatalog().getId()} ${item.getCatalogVersion().getVersion()}";
	}

	private CatalogVersionSyncCronJobModel getLastFullSyncCronjob(String jobCode)
	{
		CatalogVersionSyncCronJobModel returnValue = null;
		String query = "SELECT {CatalogVersionSyncCronJob.pk} FROM {CatalogVersionSyncCronJob JOIN CronJobStatus ON {CronJobStatus.pk} = {CatalogVersionSyncCronJob.status} JOIN CronJobResult ON {CronJobResult.pk} = {CatalogVersionSyncCronJob.result} JOIN Job ON {Job.pk} = {CatalogVersionSyncCronJob.job} } WHERE {Job.code} = ?jobCode AND {CatalogVersionSyncCronJob.fullSync}=1 AND {CronJobStatus.code} NOT IN ('RUNNING','NEW') ORDER BY {CatalogVersionSyncCronJob.modifiedtime} DESC";
		Map<String, Object> queryParams = [jobCode:jobCode];
		SearchResult<CatalogVersionSyncJobModel> results = flexibleSearchService.search(query, queryParams);
		if (results.getCount() > 0) {
			returnValue = results.getResult().get(0);
		}
		return returnValue;
	}
	
	private String getEnvString() {
		env = "LCG-DEV"
		hostname = java.net.InetAddress.getLocalHost().getHostName()
		if (hostname.startsWith("vis-p"))
			env = "PRD"
		else if (hostname.startsWith("vis-s"))
			env = "STG"
		else if (hostname.startsWith("vis-d"))
			env = "DEV"
		return env
	}
	private void msgSummary(String name, boolean isSuccess)
	{
		String style = (isSuccess) ? STYLE_GOOD : STYLE_ERR;
		MSG.append('<li><span style="').append(style).append('">').append(name).append('</span></li>');
	}

	//////////////////////////////////
	class Context
	{
		String jobCode;
		CatalogVersionSyncCronJobModel cronjob;
	}