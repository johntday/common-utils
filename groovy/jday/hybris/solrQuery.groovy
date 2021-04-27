package jday.hybris

import de.hybris.platform.solrfacetsearch.solr.SolrSearchProvider;
import de.hybris.platform.solrfacetsearch.solr.SolrSearchProviderFactory;
import de.hybris.platform.solrfacetsearch.config.FacetSearchConfigService;
import de.hybris.platform.solrfacetsearch.solr.Index;
import de.hybris.platform.solrfacetsearch.config.FacetSearchConfig;
import de.hybris.platform.solrfacetsearch.config.IndexedType;
import org.apache.solr.client.solrj.SolrClient;
import org.apache.solr.client.solrj.SolrQuery;
import org.apache.solr.client.solrj.SolrServerException;
import org.apache.solr.client.solrj.SolrRequest.METHOD;
import org.apache.solr.client.solrj.response.QueryResponse;
import org.apache.solr.common.params.MapSolrParams;
import groovy.json.JsonOutput;
import org.apache.solr.common.util.IOUtils;
    
SolrSearchProviderFactory solrSearchProviderFactory = spring.getBean('solrSearchProviderFactory');
FacetSearchConfigService facetSearchConfigService = spring.getBean('facetSearchConfigService');
    
//1. Change this to the name of your index.
FacetSearchConfig facetSearchConfig = facetSearchConfigService.getConfiguration('actionsportsIndex');
//2. The FacetSearchConfig type can have more than one IndexedType associated with it. In practice, there's only one IndexedType - Product.
IndexedType indexedType = facetSearchConfig.indexConfig.indexedTypes.get('Product');
SolrSearchProvider solrSearchProvider = solrSearchProviderFactory.getSearchProvider(facetSearchConfig, indexedType);
//3. 'default' is the SolrIndex.qualifier. Change this if you are not using 'default'.
Index index = solrSearchProvider.resolveIndex(facetSearchConfig, indexedType, 'default');
SolrClient solrClient = solrSearchProvider.getClient(index);
  
SolrQuery query = new SolrQuery('{!boost}( {!lucene v=$yq})');
query
   .set('yq','*:*')
   .setFilterQueries(
    'customProductCatalogs_string_mv:(BikeCustomProductCatalog OR CPremeCustomProductCatalog)',
    'baseProductCode_string:100000000300000099',
    '(catalogId:"actionsportsProductCatalog" AND catalogVersion:"Online")'
   )
  .set('sort', 'score desc')
  .setStart(0)
  .setRows(20)
  .set(
  	'fl', 
  	'score,id,pk,code_string,gender_string_mv,keywords_text_en,img-cart-icon_string,description_text_en,reviewAvgRating_en_double,tint_en_string,categoryName_text_en_mv,collectionName_text_en_mv,price_usd_b2b_default_price_group_string,baseProductCode_string,img-product_string,summary_text_en,categoryPath_string_mv,tintSwatchColors_string_mv,priceValue_usd_b2b_default_price_group_double,collection_string_mv,url_en_string,itemtype_string,size_en_string,allCategories_string_mv,name_text_en,style_en_string,customCatalogs_string_mv,category_string_mv,swatchColors_string_mv,img-thumbnail_string')
 
QueryResponse queryResponse = solrClient.query(index.getName(), query);
IOUtils.closeQuietly(solrClient);
queryResponse.toString() + '\n';
JsonOutput.toJson(queryResponse.getResults()) + '\n';
