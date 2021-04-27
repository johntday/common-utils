package jday.hybris
/**
 * Hybris groovy script
 * Find any recursive categories
 * Change query as needed
 * Run script in HAC
 */

import de.hybris.platform.servicelayer.search.FlexibleSearchQuery;
flexibleSearchService = spring.getBean("flexibleSearchService")
categoryService = spring.getBean("categoryService")

def findAllCategoriesOnline() {
	query = "SELECT {Category.pk} FROM {CatalogVersion JOIN Catalog ON {Catalog.pk} = {CatalogVersion.catalog} JOIN Category ON {Category.catalogVersion}={CatalogVersion.pk}} WHERE {CatalogVersion.version} = 'Online' AND {Catalog.id}='meijerProductCatalog'"
	flexibleSearchService.search(query).result.get(0)
}

findAllCategoriesOnline().each {
	count=0
	for (path in categoryService.getPathsForCategory(it)) {
		if (path.equals(it)) {
			println "CATEGORY IS RECURSIVE: $path.code"
			count++
		}
	}
	println "COUNT=$count"
}
