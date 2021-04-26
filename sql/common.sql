-- noinspection SqlDialectInspectionForFile
-- noinspection SqlNoDataSourceInspectionForFile

/*info_find_itemType_by_pk*/
select {composedType.code} from {Item as item}, {ComposedType as composedType} where {item.itemtype}={composedType.pk} and {item.pk} in (8796200993374,8797371039886)

SELECT 
	{Job.code} as Job_code,
	{CatalogVersionSyncCronJob.code} as cronjob_code,
	{CronJobStatus.code} as cronjob_status,
	{CronJobResult.code} as cronjob_result,
	{CatalogVersionSyncCronJob.modifiedtime} as cronjob_modifiedtime,
	{CatalogVersionSyncCronJob.creationtime} as cronjob_creationtime,
	{CatalogVersionSyncCronJob.startTime} as cronjob_startTime,
	{CatalogVersionSyncCronJob.endTime} as cronjob_endTime
FROM {CatalogVersionSyncCronJob
	JOIN CronJobStatus
		ON {CronJobStatus.pk} = {CatalogVersionSyncCronJob.status}
	JOIN CronJobResult
		ON {CronJobResult.pk} = {CatalogVersionSyncCronJob.result}
	JOIN Job
		ON {Job.pk} = {CatalogVersionSyncCronJob.job}
}
WHERE {CatalogVersionSyncCronJob.fullSync}=1
/*WHERE {CronJobResult.code} <> 'SUCCESS'*/
AND {Job.code} = 'sync giroProductCatalog:Staged->Online'
ORDER BY {CatalogVersionSyncCronJob.modifiedtime} DESC


SELECT
	{CatalogVersionSyncJob.code} as job_code
FROM {CatalogVersionSyncJob}
WHERE {CatalogVersionSyncJob.code} NOT LIKE 'Sync Default%'
ORDER BY {CatalogVersionSyncJob.code}


/*source_ni_target*/
SELECT 
	{src_catalog.id} as Src_Catalog_id,
	{src_catalogversion.version} as Src_version,
	{src_product.code} as Src_Product_code,
	{src_product.name} as Src_Product_name
FROM {Product as src_product
	JOIN CatalogVersion as src_catalogversion
		ON {src_catalogversion.pk} = {src_product.catalogVersion}
	JOIN Catalog as src_catalog ON {src_catalog.pk} = {src_catalogversion.catalog}
}
WHERE {src_catalog.id} = 'blackburnProductCatalog' AND {src_catalogversion.version} = 'Staged'
AND NOT EXISTS ({{ 	
	SELECT 1
	FROM {Product as tgt_product
		JOIN CatalogVersion as tgt_catalogversion
			ON {tgt_catalogversion.pk} = {tgt_product.catalogVersion}
		JOIN Catalog as tgt_catalog ON {tgt_catalog.pk} = {tgt_catalogversion.catalog}
	}
	WHERE {tgt_catalog.id} = 'blackburnProductCatalog' AND {tgt_catalogversion.version} = 'Online'
	AND {src_product.code} = {tgt_product.code}
}})
ORDER BY {src_catalog.id}, {src_catalogversion.version}, {src_product.code}

/*source_ne_target*/
SELECT 
	{src_catalog.id} as src_Catalog_id,
	{src_catalogversion.version} as src_version,
	{src_category.code} as src_category_code,
	{tgt_catalog.id} as tgt_Catalog_id,
	{tgt_catalogversion.version} as tgt_version,
	{tgt_category.code} as Tgt_category_code
FROM {category as src_category}, {CatalogVersion as src_catalogversion}, {Catalog as src_catalog},
	{category as tgt_category}, {CatalogVersion as tgt_catalogversion}, {Catalog as tgt_catalog}
WHERE {src_catalog.id} = 'blackburnProductCatalog' AND {src_catalogversion.version} = 'Staged'
AND {src_catalogversion.pk} = {src_category.catalogVersion}
AND {src_catalog.pk} = {src_catalogversion.catalog}
AND {tgt_catalog.id} = 'blackburnProductCatalog' AND {tgt_catalogversion.version} = 'Online'
AND {tgt_catalogversion.pk} = {tgt_category.catalogVersion}
AND {tgt_catalog.pk} = {tgt_catalogversion.catalog}
AND (
	{src_category.code} = {tgt_category.code}
)
AND (
	{src_category.name} <> {tgt_category.name} OR
	{src_category.description} <> {tgt_category.description} OR
	{src_category.order} <> {tgt_category.order} OR
	{src_category.visibleOnSites} <> {tgt_category.visibleOnSites} OR
	{src_category.useInCategoryPathUrl} <> {tgt_category.useInCategoryPathUrl} OR
	{src_category.useInCategoryBreadcrumb} <> {tgt_category.useInCategoryBreadcrumb} OR
	{src_category.googleId} <> {tgt_category.googleId} OR
	{src_category.facetBySubCategoryOnly} <> {tgt_category.facetBySubCategoryOnly}
)
ORDER BY {src_catalog.id}, {src_catalogversion.version}, {src_category.code}, 
	{tgt_catalog.id}, {tgt_catalogversion.version}, {tgt_category.code}


/* base */
SELECT 
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
	{Product.code} as Product_code,
	{Product.name} as Product_name
FROM {Product
	JOIN CatalogVersion
		ON {CatalogVersion.pk} = {Product.catalogVersion}
	JOIN Catalog ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {Catalog.id} = 'rlpProductCatalog' AND {CatalogVersion.version} = 'Online'
ORDER BY {Catalog.id}, {CatalogVersion.version}, {Product.code}


/* info_product_summary */
SELECT x.Catalog_id, x.CatalogVersion_version, x.SKU_code, x.SKU_name, x.StyleVariant_color, 
	x.SizeVariant_size, x.TintVariant_tint, x.StyleVariant_code, x.BaseProduct_code, x.B2C_price, 
	x.B2B_price,x.B2B_customer_price_cnt, x.B2C_stock, x.B2B_stock, 
	x.Attr_Details_Cnt, x.Attr_Specs_Cnt, x.Attr_Features_Cnt, x.Base_Has_Similar_Cnt, x.Base_Has_Accessories_Cnt
FROM ({{
	SELECT 
		{Catalog.id} as Catalog_id,
		{CatalogVersion.version} as CatalogVersion_version,
		{size.code} as SKU_code,
		{size.name} as SKU_name,
		{style.style} as StyleVariant_color,
		{size.size} as SizeVariant_size,
		'' as TintVariant_tint,
		{style.code} as StyleVariant_code,
		{base.code} as BaseProduct_code,
		({{ select {PriceRow.price} from {PriceRow JOIN Currency ON {PriceRow.currency}={Currency.pk}} WHERE {Currency.isocode}='USD' AND {PriceRow.ug} is null AND {size.pk}={PriceRow.product} AND {CatalogVersion.pk} = {PriceRow.catalogVersion} }}) as B2C_price,
		({{ select {PriceRow.price} from {PriceRow JOIN UserPriceGroup ON {PriceRow.ug}={UserPriceGroup.pk} JOIN Currency ON {PriceRow.currency}={Currency.pk}} WHERE {Currency.isocode}='USD' AND {UserPriceGroup.code}='B2B_DEFAULT_PRICE_GROUP' AND {size.pk}={PriceRow.product} AND {CatalogVersion.pk} = {PriceRow.catalogVersion} }}) as B2B_price,
		({{ select count({PriceRow.pk}) from {PriceRow JOIN UserPriceGroup ON {PriceRow.ug}={UserPriceGroup.pk} JOIN Currency ON {PriceRow.currency}={Currency.pk}} WHERE {Currency.isocode}='USD' AND {UserPriceGroup.code} <> 'B2B_DEFAULT_PRICE_GROUP' AND {UserPriceGroup.code} IS NOT NULL AND {size.pk}={PriceRow.product} AND {CatalogVersion.pk} = {PriceRow.catalogVersion} }}) as B2B_customer_price_cnt,
		({{ select {s.available} from {StockLevel as s JOIN Warehouse as w ON {s.warehouse}={w.pk}} WHERE {s.productcode}={size.code} AND {w.code}='default' }}) as B2C_stock,
		({{ select {s.available} from {StockLevel as s JOIN Warehouse as w ON {s.warehouse}={w.pk}} WHERE {s.productcode}={size.code} AND {w.code}='b2bWarehouse' }}) as B2B_stock,
		({{ select count({a.pk}) from {VistaProductAttribute as a JOIN VistaProductAttrEnum as e ON {a.productAttrType}={e.pk} } where {a.product}={base.pk} and {e.code}='DETAILS' }}) as Attr_Details_Cnt,
		({{ select count({a.pk}) from {VistaProductAttribute as a JOIN VistaProductAttrEnum as e ON {a.productAttrType}={e.pk} } where {a.product}={base.pk} and {e.code}='SPECIFICATION' }}) as Attr_Specs_Cnt,
		({{ select count({a.pk}) from {VistaProductAttribute as a JOIN VistaProductAttrEnum as e ON {a.productAttrType}={e.pk} } where {a.product}={base.pk} and {e.code}='FEATURE' }}) as Attr_Features_Cnt,
		({{ select count({a.pk}) from {ProductReference as a JOIN ProductReferenceTypeEnum as e ON {a.referenceType}={e.pk} } where {a.source}={base.pk} and {e.code}='SIMILAR' }}) as Base_Has_Similar_Cnt,
		({{ select count({a.pk}) from {ProductReference as a JOIN ProductReferenceTypeEnum as e ON {a.referenceType}={e.pk} } where {a.source}={base.pk} and {e.code}='ACCESSORIES' }}) as Base_Has_Accessories_Cnt		
	FROM
		{ApparelSizeVariantProduct! as size
			JOIN CatalogVersion
				ON {CatalogVersion.pk} = {size.catalogVersion}
			JOIN Catalog
				ON {Catalog.pk} = {CatalogVersion.catalog}
			LEFT JOIN ApparelStyleVariantProduct! as style
				ON {size.baseproduct} = {style.pk}
					AND {CatalogVersion.pk} = {style.catalogVersion}
			LEFT JOIN Product! as base
				ON {style.baseproduct} = {base.pk}
					AND {CatalogVersion.pk} = {base.catalogVersion}
	}
	WHERE {size.varianttype} is null
}} UNION {{
SELECT 
		{Catalog.id} as Catalog_id,
		{CatalogVersion.version} as CatalogVersion_version,
		{tint.code} as SKU_code,
		{tint.name} as SKU_name,
		{style.style} as StyleVariant_color,
		'' as SizeVariant_size,
		{tint.tint} as TintVariant_tint,
		{style.code} as StyleVariant_code,
		{base.code} as BaseProduct_code,
		({{ select {PriceRow.price} from {PriceRow JOIN Currency ON {PriceRow.currency}={Currency.pk}} WHERE {Currency.isocode}='USD' AND {PriceRow.ug} is null AND {tint.pk}={PriceRow.product} AND {CatalogVersion.pk} = {PriceRow.catalogVersion} }}) as B2C_price,
		({{ select {PriceRow.price} from {PriceRow JOIN UserPriceGroup ON {PriceRow.ug}={UserPriceGroup.pk} JOIN Currency ON {PriceRow.currency}={Currency.pk}} WHERE {Currency.isocode}='USD' AND {UserPriceGroup.code}='B2B_DEFAULT_PRICE_GROUP' AND {tint.pk}={PriceRow.product} AND {CatalogVersion.pk} = {PriceRow.catalogVersion} }}) as B2B_price,
		({{ select count({PriceRow.pk}) from {PriceRow JOIN UserPriceGroup ON {PriceRow.ug}={UserPriceGroup.pk} JOIN Currency ON {PriceRow.currency}={Currency.pk}} WHERE {Currency.isocode}='USD' AND {UserPriceGroup.code} <> 'B2B_DEFAULT_PRICE_GROUP' AND {UserPriceGroup.code} IS NOT NULL AND {tint.pk}={PriceRow.product} AND {CatalogVersion.pk} = {PriceRow.catalogVersion} }}) as B2B_customer_price_cnt,
		({{ select {s.available} from {StockLevel as s JOIN Warehouse as w ON {s.warehouse}={w.pk}} WHERE {s.productcode}={tint.code} AND {w.code}='default' }}) as B2C_stock,
		({{ select {s.available} from {StockLevel as s JOIN Warehouse as w ON {s.warehouse}={w.pk}} WHERE {s.productcode}={tint.code} AND {w.code}='b2bWarehouse' }}) as B2B_stock,
		({{ select count({a.pk}) from {VistaProductAttribute as a JOIN VistaProductAttrEnum as e ON {a.productAttrType}={e.pk} } where {a.product}={base.pk} and {e.code}='DETAILS' }}) as Attr_Details_Cnt,
		({{ select count({a.pk}) from {VistaProductAttribute as a JOIN VistaProductAttrEnum as e ON {a.productAttrType}={e.pk} } where {a.product}={base.pk} and {e.code}='SPECIFICATION' }}) as Attr_Specs_Cnt,
		({{ select count({a.pk}) from {VistaProductAttribute as a JOIN VistaProductAttrEnum as e ON {a.productAttrType}={e.pk} } where {a.product}={base.pk} and {e.code}='FEATURE' }}) as Attr_Features_Cnt,
		({{ select count({a.pk}) from {ProductReference as a JOIN ProductReferenceTypeEnum as e ON {a.referenceType}={e.pk} } where {a.source}={base.pk} and {e.code}='SIMILAR' }}) as Base_Has_Similar_Cnt,
		({{ select count({a.pk}) from {ProductReference as a JOIN ProductReferenceTypeEnum as e ON {a.referenceType}={e.pk} } where {a.source}={base.pk} and {e.code}='ACCESSORIES' }}) as Base_Has_Accessories_Cnt		
	FROM
		{VistaTintVariantProduct! as tint
			JOIN CatalogVersion
				ON {CatalogVersion.pk} = {tint.catalogVersion}
			JOIN Catalog
				ON {Catalog.pk} = {CatalogVersion.catalog}
			LEFT JOIN ApparelStyleVariantProduct! as style
				ON {tint.baseproduct} = {style.pk}
					AND {CatalogVersion.pk} = {style.catalogVersion}
			LEFT JOIN Product! as base
				ON {style.baseproduct} = {base.pk}
					AND {CatalogVersion.pk} = {base.catalogVersion}
	}
	WHERE {tint.varianttype} is null
}}) as x
WHERE x.Catalog_id IN ('giroProductCatalog','blackburnProductCatalog','actionsportsProductCatalog','bellhelmetsProductCatalog')
AND x.CatalogVersion_version='Online'
ORDER BY 
	x.Catalog_id,
	x.CatalogVersion_version,
	x.SKU_code


/*err_categoryRelation_catalog_mismatch*/
select
	{cp.id} as parent_category_catalog_id, {cvp.version} as parent_category_catalog_version, {p.code} as parent_category_code, {p.name} as parent_category_name,
	{cc.id} as child_category_catalog_id,  {cvc.version} as child_category_catalog_version,  {c.code} as child_category_code,  {c.name} as child_category_name
from
	{CategoryCategoryRelation as r
	JOIN Category as p
		ON {r.source}={p.pk}
	JOIN Category as c
		ON {r.target}={c.pk}
	JOIN CatalogVersion as cvp
		ON {cvp.pk} = {p.catalogVersion}
	JOIN Catalog as cp
		ON {cp.pk} = {cvp.catalog}
	JOIN CatalogVersion as cvc
		ON {cvc.pk} = {c.catalogVersion}
	JOIN Catalog as cc
		ON {cc.pk} = {cvc.catalog}
}
WHERE ( {cp.id} <> {cc.id} OR {cvp.version} <> {cvc.version} )
ORDER BY {cp.id}, {cvp.version}, {p.code}, {cc.id}, {cvp.version}, {c.code}

/*err_productReference_category_mismatch*/
select
	{cp.id} as source_product_catalog_id, {cvp.version} as source_product_catalog_version, {p.code} as source_product_code, {p.name} as source_product_name,
	{cc.id} as target_product_catalog_id,  {cvc.version} as target_product_catalog_version,  {c.code} as target_product_code,  {c.name} as target_product_name
from
	{ProductReference as r
	JOIN Product as p
		ON {r.source}={p.pk}
	JOIN Product as c
		ON {r.target}={c.pk}
	JOIN CatalogVersion as cvp
		ON {cvp.pk} = {p.catalogVersion}
	JOIN Catalog as cp
		ON {cp.pk} = {cvp.catalog}
	JOIN CatalogVersion as cvc
		ON {cvc.pk} = {c.catalogVersion}
	JOIN Catalog as cc
		ON {cc.pk} = {cvc.catalog}
}
WHERE ( {cp.id} <> {cc.id} OR {cvp.version} <> {cvc.version} )
ORDER BY {cp.id}, {cvp.version}, {p.code}, {cc.id}, {cvp.version}, {c.code}

/* err_product_dup_canonicalname */
select
	{Catalog.id} as catalog_id,{CatalogVersion.version} as version,{p.canonicalName} as catalogName,count(*) as cnt
FROM
  {Product! as p
   JOIN CatalogVersion
       ON {CatalogVersion.pk} = {p.catalogVersion}
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {Catalog.id} IN ('vistaMasterProductCatalog')
AND {CatalogVersion.version}='Staged'
group by {Catalog.id},{CatalogVersion.version},{p.canonicalName}
having count(*)>1
ORDER BY 	{Catalog.id},{CatalogVersion.version},{p.canonicalName}


select y.catalog_id, y.version, y.code, y.canonicalName, y.name FROM
({{
	select
	{Catalog.id} as catalog_id,{CatalogVersion.version} as version,{p.canonicalName} as canonicalName,count(*) as cnt
	FROM
	  {Product! as p
	   JOIN CatalogVersion
	       ON {CatalogVersion.pk} = {p.catalogVersion}
	   JOIN Catalog
	       ON {Catalog.pk} = {CatalogVersion.catalog}
	}
	group by {Catalog.id},{CatalogVersion.version},{p.canonicalName}
	having count(*)>1
}}) as x,
({{
	select
	{Catalog.id} as catalog_id,{CatalogVersion.version} as version,{p.canonicalName} as canonicalName, {p.code} as code, {p.name} as name
	FROM
	  {Product! as p
	   JOIN CatalogVersion
	       ON {CatalogVersion.pk} = {p.catalogVersion}
	   JOIN Catalog
	       ON {Catalog.pk} = {CatalogVersion.catalog}
	}
}}) as y
WHERE x.catalog_id = y.catalog_id
AND x.version = y.version
AND x.canonicalName = y.canonicalName
AND x.catalog_id IN ('giroProductCatalog','blackburnProductCatalog','bellhelmetsProductCatalog')
AND x.version='Online'
ORDER BY y.catalog_id, y.version, y.canonicalName, y.code



select {b.uid} as baseb2bunit_uid,{a.streetname} as line1,{a.postalcode},{a.town},{a.region},{a.country} from {address as a JOIN b2bunit as b ON {a.owner}={b.pk}} where ({streetname} is null OR {postalcode} is null OR {town} is null OR {region} is null OR {country} is null)

SELECT 
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
  {Product.code} as Product_code FROM   {Product    JOIN CatalogVersion        ON {CatalogVersion.pk} = {Product.catalogVersion}    JOIN Catalog        ON {Catalog.pk} = {CatalogVersion.catalog} } WHERE {Product.varianttype} is null AND NOT EXISTS ({{  	select 1  	from {PriceRow JOIN Currency ON {PriceRow.currency}={Currency.pk}}  	WHERE {Currency.isocode}='USD'  	AND {PriceRow.ug} is null  	AND {Product.pk}={PriceRow.product}  	AND {CatalogVersion.pk} = {PriceRow.catalogVersion}  }})  

SELECT DISTINCT {Product.code} as Product_code 
FROM {Product} 
WHERE {Product.varianttype} is null 
AND NOT EXISTS ({{ 	
	SELECT 1 	FROM {StockLevel as s JOIN Warehouse as w ON {s.warehouse}={w.pk}} 	WHERE {w.code}='default' 	AND {Product.code} = {s.productcode} 
}})

select SOLDTO.pk FROM ( {{ 	select {b.pk} as pk 	FROM {b2bunit as b JOIN VistaB2BUnitAttributes as a ON {b.b2bUnitAttributes}={a.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={a.b2bUnitType}} 	WHERE {e.code}='SOLDTO'}}) as SOLDTO LEFT JOIN ({{ 	select {b.pk} as pk, {b.reportingOrganization} as reportingOrganization 	FROM {b2bunit as b JOIN VistaB2BUnitAttributes as a ON {b.b2bUnitAttributes}={a.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={a.b2bUnitType}} 	WHERE {e.code}='SHIPTO' }}) as SHIPTO ON SHIPTO.reportingOrganization = SOLDTO.pk WHERE SHIPTO.pk is null

select SHIPTO.uid as shipto_uid, SHIPTO.name as shipto_name 
FROM ( {{

select {b.uid} as uid, {b.name} as name, {b.pk} as pk, {b.reportingOrganization} as reportingOrganization 	FROM {b2bunit as b JOIN VistaB2BUnitAttributes as a ON {b.b2bUnitAttributes}={a.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={a.b2bUnitType}} 	
		WHERE {e.code}='SHIPTO'

	}}) as SHIPTO 
	LEFT JOIN ({{ 	
	select {b.pk} as pk
		FROM {b2bunit as b JOIN VistaB2BUnitAttributes as a ON {b.b2bUnitAttributes}={a.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={a.b2bUnitType}}
		WHERE {e.code}='SOLDTO'
		 }}) as SOLDTO ON SHIPTO.reportingOrganization = SOLDTO.pk 
WHERE SOLDTO.pk is null

SELECT 
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
  {Product.code} as Product_code
 FROM   {Product    JOIN CatalogVersion        ON {CatalogVersion.pk} = {Product.catalogVersion}    JOIN Catalog        ON {Catalog.pk} = {CatalogVersion.catalog} } WHERE {Product.varianttype} is null AND NOT EXISTS ({{  	select 1  	from {PriceRow JOIN UserPriceGroup ON {PriceRow.ug}={UserPriceGroup.pk} JOIN Currency ON {PriceRow.currency}={Currency.pk}}  	WHERE {Currency.isocode}='USD'  	AND {UserPriceGroup.code}='B2B_DEFAULT_PRICE_GROUP'  	AND {Product.pk}={PriceRow.product}  	AND {CatalogVersion.pk} = {PriceRow.catalogVersion} }})

SELECT 
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
  {p.code} as Product_code
FROM {
	Product as p
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {p.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {p.description} is null
ORDER BY 
	{Catalog.id},
	{CatalogVersion.version},
  {p.code}

SELECT 
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
  {p.code} as Product_code
FROM {
	Product as p
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {p.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE NOT EXISTS ({{
select 1 from {CategoryProductRelation as r}
where {r.target}={p.pk}
}})
and {Catalog.id} in ('giroProductCatalog','blackburnProductCatalog','actionsportsProductCatalog','bellhelmetsProductCatalog')
ORDER BY 
	{Catalog.id},
	{CatalogVersion.version},
  {p.code}

/* err_product_wo_name */
SELECT 
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
  {p.code} as Product_code
FROM {
	Product as p
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {p.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {p.name} is null
ORDER BY 
	{Catalog.id},
	{CatalogVersion.version},
  {p.code}

/* err_category_wo_name */
SELECT 
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
  {p.code} as Category_code
FROM {
	Category as p
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {p.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE NOT EXISTS ({{
	select 1 from {CategoryCategoryRelation as r}
	where {p.pk}={r.target}
}})
AND {p.code} NOT IN ('categories','collections')
ORDER BY 
	{Catalog.id},
	{CatalogVersion.version},
  {p.code}



SELECT 
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
  {p.name} as Product_name,
  {p.code} as Product_code,
  {size.size} as Variant_color,
  {p.size} as Variant_size,
  {StockLevel.available} as StockLevel_B2C_available,
  {StockLevel_b2b.available} as StockLevel_B2B_available,
	{PriceRow_B2C.price} as PriceRow_price,
  {Currency.isocode} as PriceRow_currency
FROM {
	ApparelSizeVariantProduct as p
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {p.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
		LEFT JOIN StockLevel
			ON {StockLevel.productcode} = {p.code}
		LEFT JOIN Warehouse
			ON {Warehouse.pk} = {StockLevel.warehouse}
		LEFT JOIN StockLevel as StockLevel_b2b
			ON {StockLevel_b2b.productcode} = {p.code}
		LEFT JOIN Warehouse as Warehouse_b2b
			ON {Warehouse_b2b.pk} = {StockLevel_b2b.warehouse}
		LEFT JOIN PriceRow as PriceRow_B2C
			ON {p.pk} = {PriceRow_B2C.product}
				AND {PriceRow_B2C.catalogversion} = {CatalogVersion.pk}
		LEFT JOIN Currency
			ON {PriceRow_B2C.currency}={Currency.pk}
		LEFT JOIN ApparelsizeVariantProduct as size
			ON {p.baseproduct}={size.pk}
				AND {size.catalogversion} = {CatalogVersion.pk}
}
WHERE {Catalog.id}='vistaMasterProductCatalog' AND {CatalogVersion.version}='Staged'
AND {p.varianttype} IS NULL
AND {Warehouse.code}='default'
AND {Warehouse_b2b.code}='b2bWarehouse'
ORDER BY 
	{Catalog.id},
	{CatalogVersion.version},
  {p.name},
  {p.code},
	{Currency.isocode}


SELECT *
FROM {B2BUnit}
WHERE NOT EXISTS ({{
	SELECT 1 FROM {Address} WHERE {Address.owner}={B2BUnit.pk}
}})


SELECT DISTINCT tbl.pk, tbl.code FROM (
	{{
		SELECT DISTINCT {p:PK} AS pk, {p:code} AS code
		FROM {Product AS p}
		WHERE {p:varianttype} IS NULL AND ({p:modifiedtime} >= ?lastIndexTime OR {cr:modifiedtime} >= ?lastIndexTime)
	}}
	UNION
	{{
		SELECT DISTINCT {p:PK} AS pk, {p:code} AS code
		FROM {VariantProduct AS p JOIN Product AS bp1 ON {p:baseProduct}={bp1:PK} }
		WHERE {p:varianttype} IS NULL AND ({bp1:modifiedtime} >= ?lastIndexTime OR {cr:modifiedtime} >= ?lastIndexTime)
	}}
	UNION
	{{
		SELECT DISTINCT {p:PK} AS pk, {p:code} AS code
		FROM {VariantProduct AS p JOIN VariantProduct AS bp1 ON {p:baseProduct}={bp1:PK} JOIN Product AS bp2 ON {bp1:baseProduct}={bp2:PK} }
		WHERE {p:varianttype} IS NULL AND ({bp2:modifiedtime} >= ?lastIndexTime OR {cr:modifiedtime} >= ?lastIndexTime)
	}}
	UNION
	{{
		SELECT {p:PK}  AS pk, {p:code} AS code 
		FROM {Product AS p} 
		WHERE {p:code} IN (
			{{
				SELECT DISTINCT {sl:productCode} FROM {StockLevel AS sl} WHERE {sl:modifiedtime} >= ?lastIndexTime
			}}
		)
	}}
) tbl ORDER BY tbl.code


SELECT
	{Catalog.id} as catalog_id,
	{CatalogVersion.version} as version,
	{prodCat.code} as category_code,
	{p.code} as product_code,
	{style.code} as styleVariant_code,
	{styleCat.code} as styleCat_code,
	{size.code} as sizeVariant_code,
	{sizeCat.code} as sizeCat_code
FROM {
	Product! as p
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {p.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
		JOIN CategoryProductRelation
			ON {CategoryProductRelation.target}={p.pk}
		JOIN Category as prodCat
			ON {CategoryProductRelation.source}={prodCat.pk}
				AND {CatalogVersion.pk} = {prodCat.catalogVersion}
		LEFT JOIN ApparelStyleVariantProduct! as style
			ON {style.baseproduct}={p.pk}
				AND {CatalogVersion.pk} = {style.catalogVersion}
		LEFT JOIN CategoryProductRelation as styleRel
			ON {styleRel.target}={style.pk}
		LEFT JOIN Category as styleCat
			ON {styleRel.source}={styleCat.pk}
				AND {CatalogVersion.pk} = {styleCat.catalogVersion}
		LEFT JOIN ApparelSizeVariantProduct! as size
			ON {size.baseproduct}={style.pk}
				AND {CatalogVersion.pk} = {size.catalogVersion}
		LEFT JOIN CategoryProductRelation as sizeRel
			ON {sizeRel.target}={size.pk}
		LEFT JOIN Category as sizeCat
			ON {sizeRel.source}={sizeCat.pk}
				AND {CatalogVersion.pk} = {sizeCat.catalogVersion}
}
WHERE ( {style.code} IS NULL OR {styleCat.code} IS NULL 
OR {size.code} IS NULL OR {sizeCat.code} IS NULL )
ORDER BY
	{Catalog.id},
	{CatalogVersion.version},
	{prodCat.code},
	{p.code},
	{style.code},
	{styleCat.code},
	{size.code},
	{sizeCat.code}


SELECT distinct
	{Catalog.id} as catalog_id,
	{CatalogVersion.version} as version,
	{sizeCat.code} as sizeCat_code,
	{Product.code} as product_code,
	{style.code} as styleVariant_code,
	{size.code} as sizeVariant_code
FROM {
	Product!
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {Product.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
		JOIN ApparelStyleVariantProduct! as style
			ON {style.baseproduct}={Product.pk}
				AND {CatalogVersion.pk} = {style.catalogVersion}
		JOIN ApparelSizeVariantProduct! as size
			ON {size.baseproduct}={style.pk}
				AND {CatalogVersion.pk} = {size.catalogVersion}

		JOIN CategoryProductRelation as sizeRel
			ON {sizeRel.target}={size.pk}
		JOIN Category as sizeCat
			ON {sizeRel.source}={sizeCat.pk}
				AND {CatalogVersion.pk} = {sizeCat.catalogVersion}
}
WHERE {Catalog.id}='blackburnProductCatalog' AND {CatalogVersion.version}='Online'
ORDER BY
	{Catalog.id},
	{CatalogVersion.version},
	{sizeCat.code},
	{Product.code},
	{style.code},
	{sizeCat.code}


SELECT 
	{Catalog.id} as catalog_id,
	{CatalogVersion.version} as version,
	{Product.code} as product_code,
	{style.code} as styleVariant_code,
	{size.code} as sizeVariant_code,
	{size.name} as sizeVariant_name,
	{size.description} as sizeCat_description
FROM {
	Product!
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {Product.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
		LEFT JOIN ApparelStyleVariantProduct! as style
			ON {style.baseproduct}={Product.pk}
				AND {CatalogVersion.pk} = {style.catalogVersion}
		LEFT JOIN ApparelSizeVariantProduct! as size
			ON {size.baseproduct}={style.pk}
				AND {CatalogVersion.pk} = {size.catalogVersion}
}
WHERE {Catalog.id}='blackburnProductCatalog' AND {CatalogVersion.version}='Online'
AND {size.name} is not null
ORDER BY
	{Catalog.id},
	{CatalogVersion.version},
	{size.code}




SELECT
	{Category.code},
	{Product.code}
FROM {
	Product!
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {Product.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
		JOIN CategoryProductRelation
			ON {CategoryProductRelation.target}={Product.pk}
		JOIN Category
			ON {CategoryProductRelation.source}={Category.pk}
				AND {CatalogVersion.pk} = {Category.catalogVersion}
}
WHERE {Catalog.id}='actionsportsProductCatalog' AND {CatalogVersion.version}='Online'


SELECT 
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
  {p.code} as Product_code,
	{PriceRow_B2C.price} as PriceRow_B2C_price
FROM {
	ApparelSizeVariantProduct as p
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {p.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
		LEFT JOIN PriceRow as PriceRow_B2C
			ON {p.pk} = {PriceRow_B2C.product}
				AND {PriceRow_B2C.catalogversion} = {CatalogVersion.pk}
}
WHERE {CatalogVersion.active} = 1
ORDER BY 
	{Catalog.id},
	{CatalogVersion.version},
  {p.code}



SELECT 
	{b.uid}
	,{a.soldToNumber}
	,{b.locName}
	,{a.isAccountPaymentType}
	,{a.dropShipFlag}
	,{a.creditBlockFlag}
	,{a.paymentTerms}
	,{shiptob.uid}
	,{shiptoa.shipToNumber}
FROM {
	B2bUnit as b
		JOIN VistaB2BUnitAttributes as a
			ON {a.owner}={b.pk}
		JOIN B2bUnit as shiptob
			ON {shiptob.reportingOrganization}={b.pk}
		JOIN VistaB2BUnitAttributes as shiptoa
			ON {shiptoa.owner}={shiptob.pk}
}
WHERE {shiptoa.shiptonumber} IS NOT NULL
AND {b.uid} NOT IN ('1008133')
ORDER BY {b.uid}, {shiptob.uid}


SELECT 
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
  {p.code} as Product_code,
	count({PriceRow_B2C.pk}) as PriceRow_cnt
FROM {
	ApparelSizeVariantProduct as p
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {p.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
		JOIN PriceRow as PriceRow_B2C
			ON {p.pk} = {PriceRow_B2C.product}
				AND {PriceRow_B2C.catalogversion} = {CatalogVersion.pk}
}
WHERE {Catalog.id}='giroProductCatalog' AND {CatalogVersion.version}='Online'
GROUP BY 
	{Catalog.id},
	{CatalogVersion.version},
  {p.code}
HAVING count({PriceRow_B2C.pk}) > 1


select * from {PriceRow},{Product} where {PriceRow.product}={Product.pk} and {Product.code}='112254'

({{ SELECT {price} FROM {PriceRow},{PrincipalGroup} WHERE {p.pk} = {product} AND {PrincipalGroup.pk} = {ug} AND {uid} = 'b2bcustomergroup'  }}) as PriceRow_price_b2b

		LEFT JOIN PriceRow as PriceRow_B2C
			ON {p.pk} = {PriceRow_B2C.product}
				AND {PriceRow_B2C.catalogversion} = {CatalogVersion.pk}
				AND {PriceRow_B2C.ug} IS NULL
		LEFT JOIN PriceRow as PriceRow_B2B
			ON {p.pk} = {PriceRow_B2B.product}
				AND {PriceRow_B2B.catalogversion} = {CatalogVersion.pk}
				AND {PriceRow_B2B.ug} IS NULL
		LEFT JOIN PrincipalGroup
			ON {PrincipalGroup.pk} = {PriceRow_B2B.ug}
				AND {PrincipalGroup.uid} = 'b2bcustomergroup'


SELECT 
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
  {Warehouse.code} as Warehouse_code,
  {p.code} as Product_code,
  {StockLevel.available} as StockLevel_available,
  {PriceRow.price} as PriceRow_price_b2c
FROM
  {PriceRow
   JOIN CatalogVersion
       ON {CatalogVersion.pk} = {PriceRow.catalogVersion}
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
   LEFT JOIN ApparelSizeVariantProduct as p
       ON {p.pk} = {PriceRow.product}
   LEFT JOIN StockLevel
       ON {StockLevel.productcode} = {p.code}
   LEFT JOIN Warehouse
       ON {Warehouse.pk} = {StockLevel.warehouse}
}
WHERE {CatalogVersion.active} = 1
AND {PriceRow.ug} IS NULL
ORDER BY 
	{Catalog.id},
	{CatalogVersion.version},
  {Warehouse.code},
  {p.code},
  {PriceRow.price}


SELECT 
  {Product.code} as Product_code,
  count(*) as Warehouse_cnt
FROM
  {CatalogVersion
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
   JOIN Product
       ON {CatalogVersion.pk}={Product.catalogVersion}
   JOIN StockLevel
       ON {Product.code}={StockLevel.productCode}
   JOIN Warehouse
       ON {StockLevel.warehouse}={Warehouse.pk}
}
WHERE {CatalogVersion.active} = 1
GROUP BY
  {Product.code}


SELECT *
FROM {B2bUnit}
WHERE NOT EXISTS ({{
	SELECT 1 FROM {Address} WHERE {Address.owner}={B2bUnit.pk}
}})


SELECT {p.code}
FROM {Product! as p}
WHERE NOT EXISTS 
({{ SELECT 1 FROM {ApparelsizeVariantProduct! as b} WHERE {b.baseproduct}={p.pk} }})


SELECT {p.code}
FROM {ApparelsizeVariantProduct! as p}
WHERE NOT EXISTS 
({{ SELECT 1 FROM {ApparelSizeVariantProduct! as b} WHERE {b.baseproduct}={p.pk} }})
AND NOT EXISTS
({{ SELECT 1 FROM {VistaTintVariantProduct! as b} WHERE {b.baseproduct}={p.pk} }})



SELECT 
	{p.code}
	,({{  SELECT count(*) FROM {ApparelsizeVariantProduct} WHERE {ApparelsizeVariantProduct.baseproduct}={p.pk} }})
FROM {Product as p
	JOIN CatalogVersion as cv
		ON {p.catalogversion}={cv.pk}
	JOIN Catalog as c
		ON {cv.catalog}={c.pk}
}
WHERE {c.id}='actionsportsProductCatalog' AND {cv.version}='Online'


	SELECT 
		{p.code}
	FROM {ApparelsizeVariantProduct! as p
		JOIN CatalogVersion as cv
			ON {p.catalogversion}={cv.pk}
		JOIN Catalog as c
			ON {cv.catalog}={c.pk}
	}
	WHERE {c.id}='actionsportsProductCatalog' AND {cv.version}='Online'
	AND NOT EXISTS ({{ SELECT 1 FROM {Product! as b} WHERE {p.baseproduct}={b.pk} AND {b.catalogversion}={cv.pk} }})


SELECT 
	{p.code}
FROM {ApparelSizeVariantProduct! as p
	JOIN CatalogVersion as cv
		ON {p.catalogversion}={cv.pk}
	JOIN Catalog as c
		ON {cv.catalog}={c.pk}
}
WHERE {c.id}='actionsportsProductCatalog' AND {cv.version}='Online'
AND NOT EXISTS ({{ SELECT 1 FROM {ApparelsizeVariantProduct! as b} WHERE {p.baseproduct}={b.pk} AND {b.catalogversion}={cv.pk} }})



/* admin users */
SELECT 
	{B2bUnit.uid} as B2bUnit_SOLDTO_uid
	,MAX({SHIPTO.uid}) as B2bUnit_SHIPTO_uid_max
FROM
  {B2bUnit
  JOIN VistaB2BUnitAttributes
  	ON {VistaB2BUnitAttributes.owner}={B2bUnit.pk}
  JOIN B2bUnit as SHIPTO
  	ON {SHIPTO.reportingOrganization}={B2bUnit.pk}
}
WHERE {B2bUnit.active}=1
AND {VistaB2BUnitAttributes.shipToNumber} IS NULL
GROUP BY {B2bUnit.uid}
ORDER BY {B2bUnit.uid}

/* PrincipalGroupRelation */
SELECT 
	{B2bUnit.uid} as B2bUnit_SOLDTO_uid
	,{SHIPTO.uid} as B2bUnit_SHIPTO_uid
FROM
  {B2bUnit
  JOIN VistaB2BUnitAttributes
  	ON {VistaB2BUnitAttributes.owner}={B2bUnit.pk}
  JOIN B2bUnit as SHIPTO
  	ON {SHIPTO.reportingOrganization}={B2bUnit.pk}
}
WHERE {B2bUnit.active}=1
AND {VistaB2BUnitAttributes.shipToNumber} IS NULL
ORDER BY {B2bUnit.uid}

/* report on SHIPTOs */
SELECT 
	{B2bUnit.uid} as B2bUnit_SOLDTO_uid
	,count({SHIPTO.uid}) as SHIPTO_cnt
FROM
  {B2bUnit
  JOIN B2bUnit as SHIPTO
  	ON {SHIPTO.reportingOrganization}={B2bUnit.pk}
}
WHERE {B2bUnit.active}=1
GROUP BY {B2bUnit.uid}
ORDER BY count({SHIPTO.uid}) DESC


SELECT 
  {B2bUnit.uid} as B2bUnit_uid
  ,{VistaB2BUnitAttributes.soldToNumber} as VistaB2BUnitAttributes_soldToNumber
  ,{VistaB2BUnitAttributes.shipToNumber} as VistaB2BUnitAttributes_shipToNumber
  ,{VistaB2BUnitAttributes.isAccountPaymentType} as VistaB2BUnitAttributes_isAccountPaymentType
  ,{Currency.isocode} as VistaB2BUnitAttributes_currency_isocode
  ,{VistaB2BUnitAttributes.dropshipFlag} as VistaB2BUnitAttributes_dropshipFlag
  ,{VistaB2BUnitAttributes.creditBlockFlag} as VistaB2BUnitAttributes_creditBlockFlag
  ,{VistaB2BUnitAttributes.paymentTerms} as VistaB2BUnitAttributes_paymentTerms
FROM
  {B2bUnit
  JOIN VistaB2BUnitAttributes
  	ON {VistaB2BUnitAttributes.owner}={B2bUnit.pk}
	LEFT JOIN Currency
		ON {VistaB2BUnitAttributes.currency}={Currency.pk}
}
WHERE {B2bUnit.active}=1
ORDER BY {VistaB2BUnitAttributes.soldToNumber}, {VistaB2BUnitAttributes.shipToNumber}


SELECT 
	{SOLDTO.uid} as B2BUnit_SOLDTO_uid
  ,{SHIPTO.uid} as B2BUnit_SHIPTO_uid
  ,{a.soldToNumber} as VistaB2BUnitAttributes_soldToNumber
  ,{a.shipToNumber} as VistaB2BUnitAttributes_shipToNumber
FROM
  {B2BUnit as SHIPTO
  JOIN VistaB2BUnitAttributes as a
  	ON {a.pk} = {SHIPTO.b2bUnitAttributes}
  JOIN Address as SHIPTO_addr
  	ON {SHIPTO_addr.owner} = {SHIPTO.pk}
  JOIN B2BUnit as SOLDTO
  	ON {SOLDTO.pk}={SHIPTO.reportingOrganization}
  JOIN VistaB2BUnitAttributes
  	ON {VistaB2BUnitAttributes.pk} = {SOLDTO.b2bUnitAttributes}
  JOIN Address as SOLDTO_addr
  	ON {SOLDTO_addr.owner} = {SOLDTO.pk}
}
WHERE {SHIPTO.active}=1 AND {SOLDTO.active}=1
AND {a.shipToNumber} IS NOT NULL
ORDER BY {a.soldToNumber}, {a.shipToNumber}


SELECT DISTINCT tbl.pk, tbl.code FROM (
	{{                            
		SELECT DISTINCT {p:PK} AS pk, {p:code} AS code, {p:varianttype} AS varianttype
		FROM {Product AS p JOIN CatalogVersion AS cv ON {cv:pk}={p:catalogVersion} JOIN Catalog AS c ON {c:pk}={cv:catalog} LEFT JOIN CustomerReview AS cr ON {cr:product}={p:PK} }
		WHERE {p:disabled}=0 AND {cv:active}=1
	}}                            
	UNION                         
	{{                            
		SELECT {p:PK} AS pk, {p:code} AS code, {p:varianttype} AS varianttype FROM {Product AS p JOIN CatalogVersion AS cv ON {cv:pk}={p:catalogVersion} JOIN Catalog AS c ON {c:pk}={cv:catalog} } 
  WHERE {p:disabled}=0 AND {cv:active}=1 AND {p:code} IN (
			{{                          
				SELECT DISTINCT {sl:productCode} FROM {StockLevel AS sl} WHERE {p:disabled}=0
			}}                          
		)                            
	}}                            
) tbl 
WHERE (tbl.varianttype IS NULL OR tbl.varianttype NOT IN ( {{ SELECT {PK} FROM {varianttype} WHERE {code} = 'MeijerColorVariantProduct'}}) ) 
AND tbl.code NOT IN({{ SELECT {code} FROM {GenericVariantProduct} }}) 
ORDER BY tbl.code


/*err_baseb2bunit_soldto_wo_shipto*/
select SOLDTO.pk FROM (
{{
	select {b.pk} as pk
	FROM {b2bunit as b JOIN VistaB2BUnitAttributes as a ON {b.b2bUnitAttributes}={a.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={a.b2bUnitType}}
	WHERE {e.code}='SOLDTO'}}) as SOLDTO LEFT JOIN
({{
	select {b.pk} as pk, {b.reportingOrganization} as reportingOrganization
	FROM {b2bunit as b JOIN VistaB2BUnitAttributes as a ON {b.b2bUnitAttributes}={a.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={a.b2bUnitType}}
	WHERE {e.code}='SHIPTO'
}}) as SHIPTO
ON SHIPTO.reportingOrganization = SOLDTO.pk
WHERE SHIPTO.pk is null


/*err_baseb2bunit_invalid_groups*/
select SHIPTO.pk FROM
({{
	select {b.pk} as pk, {b.reportingOrganization} as reportingOrganization
	FROM {b2bunit as b JOIN VistaB2BUnitAttributes as a ON {b.b2bUnitAttributes}={a.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={a.b2bUnitType}}
	WHERE {e.code}='SHIPTO'
}}) as SHIPTO LEFT JOIN 
({{
	select {b.pk} as pk
	FROM {b2bunit as b JOIN VistaB2BUnitAttributes as a ON {b.b2bUnitAttributes}={a.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={a.b2bUnitType}}
	WHERE {e.code}='SOLDTO'
}}) as SOLDTO
ON SHIPTO.reportingOrganization = SOLDTO.pk
WHERE SOLDTO.pk is null

SELECT  item_t0.p_uid  as uid, item_t1.p_uid  as site, item_t0.p_name  as name 
FROM users item_t0 
	JOIN cmssite item_t1 ON  item_t0.p_site = item_t1.PK  
	JOIN addresses item_t2 ON  item_t2.OwnerPkString = item_t0.PK  
WHERE (( item_t2.p_streetname  IS NULL OR  item_t2.p_postalcode  IS NULL OR  item_t2.p_town  IS NULL OR  item_t2.p_region  IS NULL OR  item_t2.p_country  IS NULL) AND  item_t0.p_uid  NOT IN ('anonymous')) AND ((item_t0.TypePkString=8796097151058  AND item_t1.TypePkString IN  (8796107374674, 8796094988370)  AND item_t2.TypePkString=8796094234706 ))


/*err_baseb2bunit_invalid_groups*/
select x.uid, x.name FROM
({{
	select {b.uid} as uid, {b.name} as name
	FROM {b2bunit as b JOIN VistaB2BUnitAttributes as a ON {b.b2bUnitAttributes}={a.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={a.b2bUnitType}}
	WHERE {e.code}='SHIPTO'
	AND NOT EXISTS ({{
		SELECT 1 FROM {PrincipalGroupRelation as r} WHERE {r.target}={b.reportingOrganization}
	}})
}}
UNION
{{
	select {b.uid} as uid, {b.name} as name
	FROM {b2bunit as b JOIN VistaB2BUnitAttributes as a ON {b.b2bUnitAttributes}={a.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={a.b2bUnitType}}
	WHERE {e.code}='SOLDTO'
	AND EXISTS ({{
		SELECT 1 FROM {PrincipalGroupRelation as r} WHERE {r.source}={b.pk}
	}})
}}) as x


/*err_address_missing_fields*/
select {a.pk} from {address as a JOIN b2bunit as b ON {a.owner}={b.pk}} where ({streetname} is null OR {postalcode} is null OR {town} is null OR {region} is null OR {country} is null)

/*err_baseb2bunit_missing_address*/
select {b.pk} from {b2bunit as b} where not exists ({{ select 1 from {address as a} where {a.owner}={b.pk} }})


/*err_baseproduct_wo_stylevariant*/
SELECT
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
	{Product.code},
	{Product.name},
	{VariantType.code}
FROM
  {Product!
   JOIN CatalogVersion
       ON {CatalogVersion.pk} = {Product.catalogVersion}
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
   JOIN VariantType ON {Product.varianttype}={VariantType.pk} 
}
where {VariantType.code} in ('ApparelStyleVariantProduct') 
and not exists ({{ select 1 from {VariantProduct as v} where {Product.pk}={v.baseproduct} }})

/*err_stylevariant_wo_sizevariant*/
SELECT
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
	{p.code},
	{p.name},
	{VariantType.code}
FROM
  {ApparelStyleVariantProduct! as p
   JOIN CatalogVersion
       ON {CatalogVersion.pk} = {p.catalogVersion}
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
   JOIN VariantType ON {p.varianttype}={VariantType.pk} 
}
where {VariantType.code} in ('ApparelSizeVariantProduct') 
and not exists ({{ select 1 from {ApparelSizeVariantProduct as v} where {p.pk}={v.baseproduct} }})


/*err_stylevariant_wo_tintvariant*/
SELECT
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
	{p.code},
	{p.name},
	{VariantType.code}
FROM
  {ApparelStyleVariantProduct! as p
   JOIN CatalogVersion
       ON {CatalogVersion.pk} = {p.catalogVersion}
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
   JOIN VariantType ON {p.varianttype}={VariantType.pk} 
}
where {VariantType.code} in ('VistaTintVariantProduct') 
and not exists ({{ select 1 from {VistaTintVariantProduct! as v} where {p.pk}={v.baseproduct} and {CatalogVersion.pk} = {v.catalogVersion} }})


/*err_tintvariant_wo_stylevariant*/
SELECT
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
	{v.code},
	{v.name},
	{VariantType.code}
FROM
  {VistaTintVariantProduct! as v
   JOIN CatalogVersion
       ON {CatalogVersion.pk} = {v.catalogVersion}
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
}
where not exists ({{ select 1 from {ApparelStyleVariantProduct as p JOIN VariantType ON {p.varianttype}={VariantType.pk}} where {p.pk}={v.baseproduct} and {VariantType.code} in ('VistaTintVariantProduct') and {CatalogVersion.pk} = {p.catalogVersion} }})

/*err_sizevariant_wo_stylevariant*/
SELECT
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
	{v.code},
	{v.name},
	{VariantType.code}
FROM
  {ApparelSizeVariantProduct! as v
   JOIN CatalogVersion
       ON {CatalogVersion.pk} = {v.catalogVersion}
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
}
where not exists ({{ select 1 from {ApparelStyleVariantProduct as p JOIN VariantType ON {p.varianttype}={VariantType.pk}} where {p.pk}={v.baseproduct} and {VariantType.code} in ('ApparelSizeVariantProduct') and {CatalogVersion.pk} = {p.catalogVersion} }})
and {v.name} not like 'GR AETHER MIPS CUSTOM%'

/*err_stylevariant_wo_baseproduct*/
SELECT
	{Catalog.id} as Catalog_id,
	{CatalogVersion.version} as CatalogVersion_version,
	{v.code},
	{v.name},
	{VariantType.code}
FROM
  {ApparelStyleVariantProduct! as v
   JOIN CatalogVersion
       ON {CatalogVersion.pk} = {v.catalogVersion}
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
}
where not exists ({{ select 1 from {Product as p JOIN VariantType ON {p.varianttype}={VariantType.pk}} where {p.pk}={v.baseproduct} and {VariantType.code} in ('ApparelStyleVariantProduct') and {CatalogVersion.pk} = {p.catalogVersion} }})


select x.pk FROM ({{ 	select {b.pk} as pk 	FROM {b2bunit as b JOIN VistaB2BUnitAttributes as a ON {b.b2bUnitAttributes}={a.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={a.b2bUnitType}} 	WHERE {e.code}='SHIPTO' 	AND NOT EXISTS ({{ 		SELECT 1 FROM {PrincipalGroupRelation as r} WHERE {r.target}={b.reportingOrganization} 	}}) }} UNION {{ 	select {b.pk} as pk 	FROM {b2bunit as b JOIN VistaB2BUnitAttributes as a ON {b.b2bUnitAttributes}={a.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={a.b2bUnitType}} 	WHERE {e.code}='SOLDTO' 	AND EXISTS ({{ 		SELECT 1 FROM {PrincipalGroupRelation as r} WHERE {r.source}={b.pk} 	}}) }}) as x

select {VistaB2BUnitAttributes.pk} from {b2bunit JOIN VistaB2BUnitAttributes ON {b2bunit.b2bUnitAttributes}={VistaB2BUnitAttributes.pk}}  where not exists ({{ select 1 from {address as a} where {a.owner}={b2bunit.pk} }})

select {b2bunit.uid},{b2bunit.name} from {b2bunit JOIN VistaB2BUnitAttributes ON {b2bunit.b2bUnitAttributes}={VistaB2BUnitAttributes.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={VistaB2BUnitAttributes.b2bUnitType}} WHERE {e.code} not in ('SHIPTO','SOLDTO')

/*err_baseb2bunit_soldto_missing_soldto*/
select {b2bunit.uid},{b2bunit.name} from {b2bunit JOIN VistaB2BUnitAttributes ON {b2bunit.b2bUnitAttributes}={VistaB2BUnitAttributes.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={VistaB2BUnitAttributes.b2bUnitType}} WHERE {e.code}='SOLDTO' AND {VistaB2BUnitAttributes.soldToNumber} IS NULL

/*err_baseb2bunit_soldto_invalid_currency*/
select {b.uid},{b.name} from {b2bunit as b JOIN VistaB2BUnitAttributes as v ON {b.b2bUnitAttributes}={v.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={v.b2bUnitType} JOIN Currency as c ON {c.pk}={v.currency}} WHERE {e.code}='SOLDTO' AND {c.isocode} NOT IN ('USD','EUR')

/*err_baseb2bunit_soldto_missing_dropship*/
select {b.uid},{b.name} from {b2bunit as b JOIN VistaB2BUnitAttributes as v ON {b.b2bUnitAttributes}={v.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={v.b2bUnitType} } WHERE {e.code}='SOLDTO' AND {v.dropshipFlag} IS NULL

/*err_baseb2bunit_soldto_missing_dropship*/
select {b.uid},{b.name} from {b2bunit as b JOIN VistaB2BUnitAttributes as v ON {b.b2bUnitAttributes}={v.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={v.b2bUnitType} } WHERE {e.code}='SOLDTO' AND {v.paymentTerms} IS NULL

/*err_baseb2bunit_soldto_missing_creditBlockFlag*/
select {b.uid},{b.name} from {b2bunit as b JOIN VistaB2BUnitAttributes as v ON {b.b2bUnitAttributes}={v.pk} JOIN VistaB2BUnitTypeEnum as e ON {e.pk}={v.b2bUnitType} } WHERE {e.code}='SOLDTO' AND {v.creditBlockFlag} IS NULL

/*err_baseb2bunit_soldto_missing_fields*/
select {b.uid},{b.name} from {b2bunit as b JOIN VistaB2BUnitAttributes as v ON {b.b2bUnitAttributes}={v.pk} } WHERE {b.name} IS NULL OR {b.locName} IS NULL OR {v.soldToNumber} IS NULL OR {v.b2bUnitType} IS NULL

/*err_customer_invalid_uid*/
select {c.uid} as uid,{b.uid} as site,{c.name} as name 
from {customer! as c 
	LEFT JOIN basesite as b ON {c.site}={b.pk}
} 
where ( {c.uid} NOT LIKE '%@%' OR {c.site} IS NULL )
AND {c.uid} NOT IN ('anonymous')

/*err_b2bcustomer_invalid_uid*/
select {c.uid} as uid,{b.uid} as site,{c.name} as name from {b2bcustomer! as c JOIN basesite as b ON {c.site}={b.pk}} where {c.uid} NOT LIKE '%@%' AND {c.uid} NOT IN ('anonymous')

/*err_b2caddress_missing_fields*/
select {c.uid} as uid,{b.uid} as site,{c.name} as name 
from {customer! as c LEFT JOIN basesite as b ON {c.site}={b.pk} JOIN address as a ON {a.owner}={c.pk}} where ({a.streetname} IS NULL OR {a.postalcode} IS NULL OR {a.town} IS NULL OR {a.region} IS NULL OR {a.country} IS NULL OR {c.site} IS NULL)
AND {c.uid} NOT IN ('anonymous')

/*err_customer_wo_site*/
select {c.uid} as uid,{b.uid} as site,{c.name} as name 
from {customer! as c LEFT JOIN basesite as b ON {c.site}={b.pk} JOIN address as a ON {a.owner}={c.pk}} where ({a.streetname} IS NULL OR {a.postalcode} IS NULL OR {a.town} IS NULL OR {a.region} IS NULL OR {a.country} IS NULL OR {c.site} IS NULL)
AND {c.uid} NOT IN ('anonymous')


/*err_b2baddress_missing_fields*/
select {c.uid} as uid,{b.uid} as site,{c.name} as name from {b2bcustomer! as c JOIN basesite as b ON {c.site}={b.pk} JOIN address as a ON {a.owner}={c.pk}} where ({a.streetname} IS NULL OR {a.postalcode} IS NULL OR {a.town} IS NULL OR {a.region} IS NULL OR {a.country} IS NULL) AND {c.uid} NOT IN ('anonymous')

/*err_customer_missing_site*/
select {c.uid} as uid,{c.name} as name from {customer! as c } where {c.site} IS NULL AND {c.uid} NOT IN ('anonymous')

/*err_b2bcustomer_missing_site*/
select {c.uid} as uid,{c.name} as name from {b2bcustomer! as c } where {c.site} IS NULL AND {c.uid} NOT IN ('anonymous')

/*err_b2bcustomer_groups_has_soldto*/
SELECT {c.uid} as uid, {c.name} as name, {b.uid} as b2bunit_uid, {a.soldtoNumber} as soldto_number
FROM {b2bcustomer! as c
	JOIN PrincipalGroupRelation as r 
		ON {r.source} = {c.pk}
	JOIN b2bunit as b 
		ON {r.target} = {b.pk}
	JOIN VistaB2BUnitAttributes as a 
		ON {b.b2bUnitAttributes}={a.pk} 
	JOIN VistaB2BUnitTypeEnum as e 
		ON {e.pk}={a.b2bUnitType}
}
WHERE {e.code} = 'SOLDTO'
ORDER BY {c.uid}, {b.uid}



/*err_basecategory_missing_visibleOnSites*/
SELECT {Catalog.id} as Catalog_id, {CatalogVersion.version} as CatalogVersion_version, {c.code},{c.name} FROM {Category as c JOIN CatalogVersion ON {CatalogVersion.pk} = {c.catalogVersion} JOIN Catalog ON {Catalog.pk} = {CatalogVersion.catalog} } where NOT EXISTS ({{select 1 from {Category2ProductSite as r} where {r.source}={c.pk}}})

/*err_product_missing_visibleOnSites*/
SELECT {Catalog.id} as Catalog_id, {CatalogVersion.version} as CatalogVersion_version, {c.code},{c.name} 
FROM {Product as c 
	JOIN CatalogVersion 
		ON {CatalogVersion.pk} = {c.catalogVersion} 
	JOIN Catalog 
		ON {Catalog.pk} = {CatalogVersion.catalog} 
} 
where NOT EXISTS ({{select 1 from {Product2ProductSite as r} where {r.source}={c.pk}}})


/*err_stylevariant_missing_style*/
SELECT 
		{Catalog.id} as Catalog_id,
		{CatalogVersion.version} as CatalogVersion_version,
		{p.code},
		{p.name}
FROM
	{ApparelStyleVariantProduct! as p
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {p.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {p.style} is null

/*err_sizevariant_missing_size*/
SELECT 
		{Catalog.id} as Catalog_id,
		{CatalogVersion.version} as CatalogVersion_version,
		{p.code},
		{p.name}
FROM
	{ApparelSizeVariantProduct! as p
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {p.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {p.size} is null

/*err_tintvariant_missing_tint*/
SELECT 
		{Catalog.id} as Catalog_id,
		{CatalogVersion.version} as CatalogVersion_version,
		{p.code},
		{p.name}
FROM
	{VistaTintVariantProduct! as p
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {p.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {p.tint} is null

/*err_stylevariant_missing_swatchColors*/
SELECT 
		{Catalog.id} as Catalog_id,
		{CatalogVersion.version} as CatalogVersion_version,
		{p.code},
		{p.name}
FROM
	{ApparelStyleVariantProduct! as p
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {p.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {p.swatchColors} is null

/*err_tintvariant_missing_tintSwatchColors*/
SELECT 
		{Catalog.id} as Catalog_id,
		{CatalogVersion.version} as CatalogVersion_version,
		{p.code},
		{p.name}
FROM
	{VistaTintVariantProduct! as p
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {p.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {p.tintSwatchColors} is null


/*err_product_inwrong_catalog*/
select x.catalog_id, x.version, x.product_code, x.product_name
FROM (
	{{
	SELECT {Catalog.id} as catalog_id, {CatalogVersion.version} as version, {c.code} as product_code, {c.name} as product_name
	FROM {Product as c 
		JOIN CatalogVersion 
			ON {CatalogVersion.pk} = {c.catalogVersion} 
		JOIN Catalog 
			ON {Catalog.pk} = {CatalogVersion.catalog} 
	} 
	WHERE {Catalog.id} IN ('bellhelmetsProductCatalog')
	AND NOT EXISTS ({{
		SELECT 1 
		FROM {Product2ProductSite as r}, {ProductSite}
		WHERE {r.source} = {c.pk}
		AND {ProductSite.pk} = {r.target}
		AND {ProductSite.code} IN ('BELL_HELMETS') }})
	}} UNION {{
	SELECT {Catalog.id} as catalog_id, {CatalogVersion.version} as version, {c.code} as product_code, {c.name} as product_name
	FROM {Product as c 
		JOIN CatalogVersion 
			ON {CatalogVersion.pk} = {c.catalogVersion} 
		JOIN Catalog 
			ON {Catalog.pk} = {CatalogVersion.catalog} 
	} 
	WHERE {Catalog.id} IN ('actionsportsProductCatalog')
	AND NOT EXISTS ({{
		SELECT 1 
		FROM {Product2ProductSite as r}, {ProductSite}
		WHERE {r.source} = {c.pk}
		AND {ProductSite.pk} = {r.target}
		AND {ProductSite.code} IN ('ACTION_SPORTS') }})
	}} UNION {{
	SELECT {Catalog.id} as catalog_id, {CatalogVersion.version} as version, {c.code} as product_code, {c.name} as product_name
	FROM {Product as c 
		JOIN CatalogVersion 
			ON {CatalogVersion.pk} = {c.catalogVersion} 
		JOIN Catalog 
			ON {Catalog.pk} = {CatalogVersion.catalog} 
	} 
	WHERE {Catalog.id} IN ('giroProductCatalog')
	AND NOT EXISTS ({{
		SELECT 1 
		FROM {Product2ProductSite as r}, {ProductSite}
		WHERE {r.source} = {c.pk}
		AND {ProductSite.pk} = {r.target}
		AND {ProductSite.code} IN ('GIRO') }})
	}} UNION {{
	SELECT {Catalog.id} as catalog_id, {CatalogVersion.version} as version, {c.code} as product_code, {c.name} as product_name
	FROM {Product as c 
		JOIN CatalogVersion 
			ON {CatalogVersion.pk} = {c.catalogVersion} 
		JOIN Catalog 
			ON {Catalog.pk} = {CatalogVersion.catalog} 
	} 
	WHERE {Catalog.id} IN ('blackburnProductCatalog')
	AND NOT EXISTS ({{
		SELECT 1 
		FROM {Product2ProductSite as r}, {ProductSite}
		WHERE {r.source} = {c.pk}
		AND {ProductSite.pk} = {r.target}
		AND {ProductSite.code} IN ('BLACKBURN') }})
	}}) as x
ORDER BY x.catalog_id, x.version, x.product_code


/*err_sizevariant_has_style*/
SELECT {Catalog.id} as catalog_id, {CatalogVersion.version} as version, {c.code}, {c.style}, {c.size}
FROM {ApparelSizeVariantProduct! as c 
	JOIN CatalogVersion 
		ON {CatalogVersion.pk} = {c.catalogVersion} 
	JOIN Catalog 
		ON {Catalog.pk} = {CatalogVersion.catalog} 
} 
WHERE {c.style} is not null
ORDER BY {Catalog.id}, {CatalogVersion.version}, {c.code}


/*err_sizevariant_missing_size*/
SELECT {Catalog.id} as catalog_id, {CatalogVersion.version} as version, {c.code}, {c.size}
FROM {ApparelSizeVariantProduct! as c 
	JOIN CatalogVersion 
		ON {CatalogVersion.pk} = {c.catalogVersion} 
	JOIN Catalog 
		ON {Catalog.pk} = {CatalogVersion.catalog} 
} 
WHERE {c.size} is null
ORDER BY {Catalog.id}, {CatalogVersion.version}, {c.code}

/*err_stylevariant_missing_style*/
SELECT {Catalog.id} as catalog_id, {CatalogVersion.version} as version, {c.code}, {c.style}
FROM {ApparelStyleVariantProduct! as c 
	JOIN CatalogVersion 
		ON {CatalogVersion.pk} = {c.catalogVersion} 
	JOIN Catalog 
		ON {Catalog.pk} = {CatalogVersion.catalog} 
} 
WHERE {c.style} is null
ORDER BY {Catalog.id}, {CatalogVersion.version}, {c.code}

/*err_tintvariant_missing_tint*/
SELECT {Catalog.id} as catalog_id, {CatalogVersion.version} as version, {c.code}, {c.tint}
FROM {VistaTintVariantProduct! as c 
	JOIN CatalogVersion 
		ON {CatalogVersion.pk} = {c.catalogVersion} 
	JOIN Catalog 
		ON {Catalog.pk} = {CatalogVersion.catalog} 
} 
WHERE {c.tint} is null
ORDER BY {Catalog.id}, {CatalogVersion.version}, {c.code}


/*info_product_attr_features*/
SELECT 
		{Catalog.id} as Catalog_id,
		{CatalogVersion.version} as CatalogVersion_version,
		{p.code} as product_code, {p.name} as product_name,
		{a.code} as attr_code, {e.code} as attr_type, {a.name} as attr_name, {a.value} as attr_value
FROM
	{Product! as p
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {p.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
		JOIN VistaProductAttribute as a 
			ON {a.product}={p.pk}
		JOIN VistaProductAttrEnum as e 
			ON {a.productAttrType}={e.pk} 
}
WHERE {a.image} IS NOT NULL
AND {e.code} = 'FEATURE'
and {Catalog.id} IN ('giroProductCatalog','blackburnProductCatalog','actionsportsProductCatalog','bellhelmetsProductCatalog')
AND {CatalogVersion.version}='Online'
ORDER BY {Catalog.id}, {CatalogVersion.version}, {p.code}, {a.code}, {a.name}

/*info_product_canonicalName*/
select
	{Catalog.id} as catalog_id,
    {CatalogVersion.version} as version,
    {ProductSite.code} as site_code,
    {p.code} as product_code,
    {p.canonicalName} as canonicalName,
    {p.name} as product_name
FROM
  {Product! as p
   JOIN CatalogVersion
       ON {CatalogVersion.pk} = {p.catalogVersion}
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
	JOIN Product2ProductSite as r
    	ON {r.source} = {p.pk}
    JOIN ProductSite
    	ON {r.target} = {ProductSite.pk}
}
WHERE {Catalog.id} IN ('giroProductCatalog','blackburnProductCatalog','actionsportsProductCatalog','bellhelmetsProductCatalog')
AND {CatalogVersion.version}='Online'
ORDER BY 	{Catalog.id},{CatalogVersion.version},{ProductSite.code}, {p.name}

/*info_product_canonicalName2*/
select
	{Catalog.id} as catalog_id,
    {CatalogVersion.version} as version,
    {p.code} as product_code,
    {p.canonicalName} as canonicalName,
    {p.name} as product_name
FROM
  {Product! as p
   JOIN CatalogVersion
       ON {CatalogVersion.pk} = {p.catalogVersion}
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {Catalog.id} IN ('giroProductCatalog','blackburnProductCatalog','bellhelmetsProductCatalog','actionsportsProductCatalog')
AND {CatalogVersion.version}='Online'
ORDER BY 	{Catalog.id},{CatalogVersion.version}, {p.name}, {p.canonicalName}


/*err_product_wo_price_b2c*/
select
	{Catalog.id} as catalog_id,
    {CatalogVersion.version} as version,
    {p.code} as product_code,
    {p.name} as product_name
FROM
  {VariantProduct! as p
   JOIN CatalogVersion
       ON {CatalogVersion.pk} = {p.catalogVersion}
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {p.varianttype} IS NULL
AND NOT EXISTS ({{
	SELECT 1 FROM {PriceRow JOIN Currency ON {PriceRow.currency}={Currency.pk}} 
	WHERE {Currency.isocode}='USD' 
	AND {PriceRow.ug} is null 
	AND {p.pk}={PriceRow.product} 
	AND {CatalogVersion.pk} = {PriceRow.catalogVersion}
}})
ORDER BY 	{Catalog.id},{CatalogVersion.version}, {p.code}

/*err_product_wo_price_b2b*/
select
	{Catalog.id} as catalog_id,
    {CatalogVersion.version} as version,
    {p.code} as product_code,
    {p.name} as product_name
FROM
  {VariantProduct! as p
   JOIN CatalogVersion
       ON {CatalogVersion.pk} = {p.catalogVersion}
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {p.varianttype} IS NULL
AND NOT EXISTS ({{
	SELECT 1 FROM {PriceRow JOIN UserPriceGroup ON {PriceRow.ug}={UserPriceGroup.pk} JOIN Currency ON {PriceRow.currency}={Currency.pk}} 
	WHERE {Currency.isocode}='USD' 
	AND {UserPriceGroup.code}='B2B_DEFAULT_PRICE_GROUP' 
	AND {p.pk}={PriceRow.product} 
	AND {CatalogVersion.pk} = {PriceRow.catalogVersion}
}})
ORDER BY 	{Catalog.id},{CatalogVersion.version}, {p.code}


/*err_product_wo_stock_b2c*/
select
	{Catalog.id} as catalog_id, {CatalogVersion.version} as version, {p.code} as product_code, {p.name} as product_name
FROM
  {Product as p
   JOIN CatalogVersion
       ON {CatalogVersion.pk} = {p.catalogVersion}
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {p.varianttype} IS NULL
AND NOT EXISTS ({{
	SELECT 1 FROM {StockLevel as s JOIN Warehouse as w ON {s.warehouse}={w.pk}}
	WHERE {s.productcode} = {p.code}
	AND {w.code}='default'
}})
ORDER BY 	{Catalog.id},{CatalogVersion.version}, {p.code}


/*warn_order*/
SELECT
	{BaseSite.uid} as site_uid,
	{o.code} as hybris_order_nbr,
	{o.versionID} as hybris_order_versionID,
	{a.sapOrderNumber} as sap_order_nbr,
	{OrderStatus.code} as order_status,
	{OrderProcess.code} as order_process_code,
	{OrderProcess.processDefinitionName} as order_process_name,
	TO_ALPHANUM( {OrderProcess.endMessage} ) as order_process_msg,
	{o.date} as order_create_date,
	{Currency.isocode} as currency,
	{User.uid} as user_uid,
	{o.purchaseOrderNumber} as po_nbr,
	{a.proratedOrderDiscount},
	{a.proratedItemDiscount},
	{a.proratedDeliveryCost},
	{a.proratedTaxAmount},
	{a.catalogTypes},
	{shipto.name} as shipto,
	{soldto.name} as soldto,
	{OrderType.code} as orderType,
	{o.deliveryCost},
	{DeliveryMode.code} as delivery_mode_code,
	{DeliveryStatus.code} as delivery_status,
	{o.totalPrice},
	{o.totalDiscounts},
	{o.totalTax},
	{o.subtotal},
	{o.discountsIncludeDeliveryCost},
	{o.discountsIncludePaymentCost},
	{Comment.text} as comment_text
FROM {
	Order as o
	LEFT JOIN VistaAbstractOrderAttributes as a
		ON {o.attributes} = {a.pk}
	LEFT JOIN B2BUnit as soldto
		ON {a.soldTo} = {soldto.pk}
	LEFT JOIN B2BUnit as shipto
		ON {a.shipTo} = {shipto.pk}
	LEFT JOIN OrderType
		ON {OrderType.pk} = {a.orderType}
	LEFT JOIN Currency
		ON {Currency.pk} = {o.currency}
	LEFT JOIN BaseSite
		ON {BaseSite.pk} = {o.site}
	LEFT JOIN User
		ON {User.pk} = {o.user}
	LEFT JOIN OrderStatus
		ON {OrderStatus.pk} = {o.status}
	LEFT JOIN CommentItemRelation
		ON {CommentItemRelation.target} = {o.pk}
	LEFT JOIN Comment
		ON {CommentItemRelation.source} = {Comment.pk}
	LEFT JOIN DeliveryStatus
		ON {DeliveryStatus.pk} = {o.deliveryStatus}
	LEFT JOIN DeliveryMode
		ON {DeliveryMode.pk} = {o.deliveryMode}
	LEFT JOIN OrderProcess
		ON {OrderProcess.order} = {o.pk}
	LEFT JOIN ProcessState
		ON {OrderProcess.state} = {ProcessState.pk}
}
WHERE {OrderStatus.code} NOT IN ('OPEN','PARTIALLY_PROCESSED','COMPLETED')
AND {OrderProcess.processDefinitionName} LIKE '%order-process'
ORDER BY {o.code} DESC


/*warn_order_process*/
SELECT  item_t6.p_uid  as site_uid,
	 item_t0.p_code  as hybris_order_nbr,
item_t0.p_versionid  as hybris_order_versionID,
	 item_t1.p_sapordernumber  as sap_order_nbr,
	 item_t8.Code  as order_status,
	 item_t13.p_code  as order_process_code,
	 item_t15.p_actionid  as order_process_log_action,
	 item_t15.p_enddate as order_process_log_date,
	 REPLACE_REGEXPR( '[^[:print:]]' IN REPLACE( REPLACE( SUBSTR_AFTER( cast(  item_t15.p_logmessages  as varchar), 'ERROR '), '"', ''''), ',', ' ') WITH ' ' OCCURRENCE ALL) as order_process_log_msg,
	 item_t15.p_returncode  as order_process_log_returncode,
	 item_t0.createdTS  as order_create_date,
item_t5.p_isocode  as currency,
	 item_t7.p_uid  as user_uid,
item_t0.p_purchaseordernumber  as po_nbr,
	 item_t1.p_proratedorderdiscount as proratedorderdiscount,
	 item_t1.p_prorateditemdiscount as prorateditemdiscount,
	 item_t1.p_prorateddeliverycost as prorateddeliverycost,
	 item_t1.p_proratedtaxamount as proratedtaxamount,
	 item_t1.p_catalogtypes as catalogtypes,
item_t3.p_name  as shipto,
item_t2.p_name  as soldto,
	 item_t4.Code  as orderType,
	 item_t0.p_deliverycost ,
	 item_t12.p_code  as delivery_mode_code,
	 item_t11.Code  as delivery_status,
	 item_t0.p_totalprice as total_price,
	 item_t0.p_totaldiscounts as total_discounts,
	 item_t0.p_totaltax as total_tax,
	 item_t0.p_subtotal as subtotal,
	 item_t0.p_discountsincludedeliverycost as discountsincludedeliverycost,
	 item_t0.p_discountsincludepaymentcost as discountsincludepaymentcost,
	 prop_t10_p0.VALUESTRING1  as comment_text
FROM orders item_t0 
LEFT JOIN vstabstractordattr item_t1 ON  item_t0.p_attributes  =  item_t1.PK  
LEFT JOIN usergroups item_t2 ON  item_t1.p_soldto  =  item_t2.PK  
LEFT JOIN usergroups item_t3 ON  item_t1.p_shipto  =  item_t3.PK  
LEFT JOIN enumerationvalues item_t4 ON  item_t4.PK  =  item_t1.p_ordertype  
LEFT JOIN currencies item_t5 ON  item_t5.PK  =  item_t0.p_currency  
LEFT JOIN cmssite item_t6 ON  item_t6.PK  =  item_t0.p_site  
LEFT JOIN users item_t7 ON  item_t7.PK  =  item_t0.p_user  
LEFT JOIN enumerationvalues item_t8 ON  item_t8.PK  =  item_t0.p_status  
LEFT JOIN commentitemrelations item_t9 ON  item_t9.TargetPK  =  item_t0.PK  
LEFT JOIN props prop_t10_p0 ON  item_t9.SourcePK  =  prop_t10_p0.ITEMPK  AND prop_t10_p0.NAME='text'  AND prop_t10_p0.LANGPK= 0  
LEFT JOIN enumerationvalues item_t11 ON  item_t11.PK  =  item_t0.p_deliverystatus  
LEFT JOIN deliverymodes item_t12 ON  item_t12.PK  =  item_t0.p_deliverymode  
LEFT JOIN processes item_t13 ON  item_t13.p_order  =  item_t0.PK  
LEFT JOIN enumerationvalues item_t14 ON  item_t13.p_state  =  item_t14.PK  
LEFT JOIN tasklogs item_t15 ON  item_t15.p_process  =  item_t13.PK  
WHERE ( item_t8.Code  NOT IN ('COMPLETED')
AND ( item_t15.p_returncode IN ('NOK') OR item_t15.p_returncode IS NULL )
AND  item_t13.p_processdefinitionname  LIKE '%order-process') 
AND ((item_t0.TypePkString IN  ( 8796098723922, 8796098789458, 8796094169170)  AND (item_t1.TypePkString IS NULL OR ( item_t1.TypePkString= 8796098166866 ) ) AND (item_t2.TypePkString IS NULL OR ( item_t2.TypePkString= 8796095512658 ) ) AND (item_t3.TypePkString IS NULL OR ( item_t3.TypePkString= 8796095512658 ) ) AND (item_t4.TypePkString IS NULL OR ( item_t4.TypePkString= 8796140240978 ) ) AND (item_t5.TypePkString IS NULL OR ( item_t5.TypePkString= 8796096397394 ) ) AND (item_t6.TypePkString IS NULL OR item_t6.TypePkString IN  ( 8796107374674, 8796094988370))  AND (item_t7.TypePkString IS NULL OR item_t7.TypePkString IN  ( 8796097052754, 8796095807570, 8796097151058, 8796097019986, 8796093939794))  AND (item_t8.TypePkString IS NULL OR ( item_t8.TypePkString= 8796097740882 ) ) AND (item_t9.TypePkString IS NULL OR ( item_t9.TypePkString= 8796093251666 ) ) AND (prop_t10_p0.ITEMTYPEPK IS NULL OR prop_t10_p0.ITEMTYPEPK IN  ( 8796115337298, 8796115468370, 8796115566674, 8796115107922))  AND (item_t11.TypePkString IS NULL OR ( item_t11.TypePkString= 8796097642578 ) ) AND (item_t12.TypePkString IS NULL OR item_t12.TypePkString IN  ( 8796099838034, 8796099772498, 8796097609810))  AND (item_t13.TypePkString IS NULL OR item_t13.TypePkString IN  ( 8796109504594, 8796109439058, 8796109340754))  AND (item_t14.TypePkString IS NULL OR ( item_t14.TypePkString= 8796109144146 ) ) AND (item_t15.TypePkString IS NULL OR ( item_t15.TypePkString= 8796110061650 ) ))) 
ORDER BY item_t0.p_code DESC, item_t15.p_enddate DESC


/*info_order*/
SELECT
	{BaseSite.uid} as site_uid,
	{o.code} as hybris_order_nbr,
	{o.versionID} as hybris_order_versionID,
	{a.sapOrderNumber} as sap_order_nbr,
	{OrderStatus.code} as order_status,
	{o.date} as order_create_date,
	{Currency.isocode} as currency,
	{User.uid} as user_uid,
	{o.purchaseOrderNumber} as po_nbr,
	{a.proratedOrderDiscount},
	{a.proratedItemDiscount},
	{a.proratedDeliveryCost},
	{a.proratedTaxAmount},
	{a.catalogTypes},
	{shipto.name} as shipto,
	{soldto.name} as soldto,
	{OrderType.code} as orderType,
	{o.deliveryCost},
	{DeliveryMode.code} as delivery_mode_code,
	{DeliveryStatus.code} as delivery_status,
	{o.totalPrice},
	{o.totalDiscounts},
	{o.totalTax},
	{o.subtotal},
	{o.discountsIncludeDeliveryCost},
	{o.discountsIncludePaymentCost},
	{Comment.text} as comment_text
FROM {
	Order as o
	LEFT JOIN VistaAbstractOrderAttributes as a
		ON {o.attributes} = {a.pk}
	LEFT JOIN B2BUnit as soldto
		ON {a.soldTo} = {soldto.pk}
	LEFT JOIN B2BUnit as shipto
		ON {a.shipTo} = {shipto.pk}
	LEFT JOIN OrderType
		ON {OrderType.pk} = {a.orderType}
	LEFT JOIN Currency
		ON {Currency.pk} = {o.currency}
	LEFT JOIN BaseSite
		ON {BaseSite.pk} = {o.site}
	LEFT JOIN User
		ON {User.pk} = {o.user}
	LEFT JOIN OrderStatus
		ON {OrderStatus.pk} = {o.status}
	LEFT JOIN CommentItemRelation
		ON {CommentItemRelation.target} = {o.pk}
	LEFT JOIN Comment
		ON {CommentItemRelation.source} = {Comment.pk}
	LEFT JOIN DeliveryStatus
		ON {DeliveryStatus.pk} = {o.deliveryStatus}
	LEFT JOIN DeliveryMode
		ON {DeliveryMode.pk} = {o.deliveryMode}
}
ORDER BY {o.code} DESC


/*info_error_summary*/
	SELECT
	{BaseSite.uid} as site_uid,
	{OrderStatus.code} as order_status,
	count(*) as count
	FROM {
		Order as o
		LEFT JOIN BaseSite
			ON {BaseSite.pk} = {o.site}
		LEFT JOIN OrderStatus
			ON {OrderStatus.pk} = {o.status}
	}
	GROUP BY 
	{BaseSite.uid},
	{OrderStatus.code}
	ORDER BY
	{BaseSite.uid},
	{OrderStatus.code}


/*err_order_process*/
SELECT
	{BaseSite.uid} as site_uid,
	{Order.code} as hybris_order_nbr,
	{OrderStatus.code} as order_status,
	{ProcessState.code} as process_state,
	TO_ALPHANUM( {OrderProcess.endMessage} ) as process_msg,
	{OrderProcess.modifiedtime} as process_timestamp
FROM {
		Order
		LEFT JOIN BaseSite
			ON {BaseSite.pk} = {Order.site}
		LEFT JOIN OrderStatus
			ON {OrderStatus.pk} = {Order.status}
		LEFT JOIN OrderProcess
			ON {Order.pk} = {OrderProcess.order}
		LEFT JOIN ProcessState
			ON {ProcessState.pk} = {OrderProcess.state}
		LEFT JOIN ProcessTask
			ON {ProcessTask.pk} = {OrderProcess.}
	}
WHERE {ProcessState.code} IN ('ERROR','FAILED')
ORDER BY
	{BaseSite.uid},
	{Order.code},
	{OrderProcess.modifiedtime} DESC


/*err_order_process_task*/
SELECT
	{BaseSite.uid} as site_uid,
	{Order.code} as hybris_order_nbr,
	{OrderStatus.code} as order_status,
	{ProcessState.code} as process_state,
	TO_ALPHANUM( {OrderProcess.endMessage} ) as process_msg,
	{OrderProcess.modifiedtime} as process_timestamp,
	{ProcessTask.failed} as task_failed,
	{ProcessTask.modifiedtime} as task_timestamp
FROM {
		Order
		LEFT JOIN BaseSite
			ON {BaseSite.pk} = {Order.site}
		LEFT JOIN OrderStatus
			ON {OrderStatus.pk} = {Order.status}
		LEFT JOIN OrderProcess
			ON {Order.pk} = {OrderProcess.order}
		LEFT JOIN ProcessState
			ON {ProcessState.pk} = {OrderProcess.state}
		LEFT JOIN ProcessTask
			ON {ProcessTask.process} = {OrderProcess.pk}
	}
WHERE {ProcessState.code} IN ('ERROR','FAILED')
ORDER BY
	{BaseSite.uid},
	{Order.code},
	{ProcessTask.modifiedtime} DESC


/*warn_dup_category_name*/
SELECT {Catalog.id} as catalog_id, {CatalogVersion.version} as version, {c.name} as category_name, count(*) as cnt
FROM
	{Category as c
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {c.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
}
GROUP BY {Catalog.id}, {CatalogVersion.version}, {c.name}
HAVING count(*)>1


SELECT {m.code}, {m.mime}, {f.qualifier}, {m.modifiedtime}, {m.realfilename}, {m.internalUrl}
FROM {Media as m
   JOIN CatalogVersion
       ON {CatalogVersion.pk} = {m.catalogVersion}
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
	LEFT JOIN MediaFolder as f
		ON {f.pk} = {m.folder}
}
WHERE {Catalog.id} IN ('vistaMasterProductCatalog')
AND {CatalogVersion.version}='Staged'
AND {m.internalUrl} NOT LIKE '%di.shotfarm.com%'
ORDER BY {m.code}


SELECT
{c.uid}, {c.name}, 
({{
select {composedType.code} from {ComposedType as composedType} where {c.itemtype}={composedType.pk}
}}) as cmsitem_type
FROM {CMSItem as c
   JOIN CatalogVersion
       ON {CatalogVersion.pk} = {c.catalogVersion}
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {Catalog.id} IN ('blackburnContentCatalog')
AND {CatalogVersion.version}='Online'


SELECT
distinct 
({{
select {composedType.code} from {ComposedType as composedType} where {c.itemtype}={composedType.pk}
}}) as cmsitem_type
FROM {CMSItem as c
   JOIN CatalogVersion
       ON {CatalogVersion.pk} = {c.catalogVersion}
   JOIN Catalog
       ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {Catalog.id} IN ('blackburnContentCatalog','giroContentCatalog','actionsportsContentCatalog','bellhelmetsContentCatalog')
AND {CatalogVersion.version}='Online'




/*err_dup_categoryproductrelation*/
SELECT {Catalog.id} as catalog_id, {CatalogVersion.version} as version, {c.code} as category_code, {p.code} as product_code, count(*) as cnt
FROM
	{Category as c
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {c.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
		JOIN CategoryProductRelation as r
			ON {r.source} = {c.pk}
		JOIN Product as p
			ON {r.target} = {p.pk}
				AND {CatalogVersion.pk} = {c.catalogVersion}
}
GROUP BY {Catalog.id}, {CatalogVersion.version}, {c.code}, {p.code}
HAVING count(*) > 1

HAVING count(*)>1


/*info_cronjob*/
select {c.PK} as cronjob_pk
,{j.code} as job_code
,{c.CODE} as cronjob_code
,{s.code} as cronjob_status
,{u.name} || ' (' || {u.uid} || ')' as cronjob_sessionUser
,{c.STARTTIME} as cronjob_starttime
,{c.ENDTIME} as cronjob_endtime
,{c.creationTime} as cronjob_createtime
,{c.modifiedTime} as cronjob_updatetime
FROM {Cronjob as c 
	LEFT JOIN User as u ON {u.pk} = {c.SESSIONUSER}
	LEFT JOIN Job as j ON {j.pk} = {c.JOB}
	LEFT JOIN CronjobStatus as s ON {s.pk} = {c.status}
}
ORDER BY {c.STARTTIME}


SELECT 
to_date({c.starttime}) as cronjob_starttime
,{u.name} || ' (' || {u.uid} || ')' as cronjob_sessionUser
,{j.code} as job_code
,count(*) as cronjob_run_cnt
FROM {Cronjob as c 
	LEFT JOIN User as u ON {u.pk} = {c.SESSIONUSER}
	LEFT JOIN Job as j ON {j.pk} = {c.JOB}
}
WHERE {u.uid} is not null
AND {u.uid} not in ('admin')
GROUP BY to_date({c.STARTTIME}), {u.name} || ' (' || {u.uid} || ')', {j.code}
ORDER BY to_date({c.STARTTIME}) DESC, {u.name} || ' (' || {u.uid} || ')', {j.code}


/*info_contentpage*/
SELECT 
{Catalog.id} as Catalog_id
,{CatalogVersion.version} as version
,{c.uid} as uid
,{c.name} as name
,{c.defaultpage} as isdefault
,{c.includeinsitemap} as includeinsitemap
,{c.index} as index
FROM
	{ContentPage as c
		JOIN CatalogVersion
			ON {CatalogVersion.pk} = {c.catalogVersion}
		JOIN Catalog
			ON {Catalog.pk} = {CatalogVersion.catalog}
}
ORDER BY {Catalog.id}, {CatalogVersion.version}, {c.uid}


/*task*/
SELECT {pk} 
FROM {Task AS t}
WHERE {failed} = ?false 
AND {executionTimeMillis} <= ?now 
AND {runningOnClusterNode} = ?noNode 
AND ({nodeId} = ?nodeId OR {nodeId} IS NULL)  
AND {nodeGroup} IS NULL 
AND NOT EXISTS ({{   	
	SELECT {task} FROM {TaskCondition}    	
	WHERE {task}={t.pk}      	
	AND {fulfilled} = ?false 
}}) 

/*taskcondition*/
SELECT {tc.pk} as taskcondition_pk
,{t.pk} as task_pk
,{t.runnerbean} as task_runnerbean
,{tc.uniqueID}
,{tc.expirationTimeMillis}
,{tc.processedDate}
,{tc.fulfilled}
,{tc.consumed}
,{tc.choice}
,{tc.counter}
FROM {TaskCondition AS tc
	LEFT JOIN Task as t ON {t.pk} = {tc.task}
}
ORDER BY {t.runnerbean}, {t.pk}, {tc.pk}


SELECT {t.PK}, {t.owner}
,{t.RUNNERBEAN} as runnerbean
,{composedType.code} as task_composedtype_code
,{t.creationtime} as creationtime
,{t.modifiedtime} as modifiedtime
,{t.FAILED} as FAILED
,{t.RETRY} as RETRY
,{t.EXECUTIONTIMEMILLIS} as EXECUTIONTIMEMILLIS
,{t.EXECUTIONHOURMILLIS} as EXECUTIONHOURMILLIS
,{t.EXPIRATIONTIMEMILLIS} as EXPIRATIONTIMEMILLIS
,{t.CONTEXT} as CONTEXT
,{t.CONTEXTITEM} as CONTEXTITEM
,{t.NODEID} as NODEID
,{t.NODEGROUP} as NODEGROUP
,{t.RUNNINGONCLUSTERNODE} as RUNNINGONCLUSTERNODE
FROM {Task AS t
	LEFT JOIN ComposedType as composedType ON {composedType.pk} = {t.itemtype}
}

/*taskstats*/
SELECT {t.RUNNERBEAN} as runnerbean
,{composedType.code} as task_composedtype_code
,count(*)
FROM {Task AS t
	LEFT JOIN ComposedType as composedType ON {composedType.pk} = {t.itemtype}
}
GROUP BY {t.runnerbean}, {composedType.code}


/*businessprocess*/
nothing


/*customproductcatalog*/
SELECT
	{c.code} as customproductcatalog_code
	,{p.code} as product_code
	,{p.name} as product_name
FROM
  {CustomProductCatalog as c
	JOIN ProductsInCustomPrdCatalog as r
		ON {r.source} = {c.pk}
	JOIN Product! as p
		ON {p.pk} = {r.target}
	JOIN CatalogVersion
		ON {CatalogVersion.pk} = {p.catalogVersion}
	JOIN Catalog
		ON {Catalog.pk} = {CatalogVersion.catalog}
	JOIN UsersCustomPrdCatalog
		ON {c.pk} = {UsersCustomPrdCatalog.source}
	JOIN Principal
		ON {Principal.pk} = {UsersCustomPrdCatalog.target}
}
WHERE {Catalog.id} = 'actionsportsProductCatalog'
AND {CatalogVersion.version} = 'Online'
AND {Principal.uid} in ('10221882063261')
ORDER BY {c.code}, {p.code}


UsersCustomPrdCatalog
		<relation code="UsersCustomPrdCatalog" generate="true" localized="false" >
			<description>Principal User to Custom Product Catalog relation</description>
			<deployment table="CustomPrdCatalogUsers" typecode="10102"/>
			<sourceElement type="CustomProductCatalog" qualifier="customProductCatalogs" cardinality="many"></sourceElement>
			<targetElement type="Principal" qualifier="principals" cardinality="many"></targetElement>
		</relation>


/*err_customproductcatalog_product_not_baseproduct*/
SELECT
	{Catalog.id} as catalog_id
	,{CatalogVersion.version} as catalog_version
	,{c.code} as customproductcatalog_code
	,{p.code} as product_code
	,{p.name} as product_name
FROM
  {CustomProductCatalog as c
	JOIN ProductsInCustomPrdCatalog as r
		ON {r.source} = {c.pk}
	JOIN VariantProduct as p
		ON {p.pk} = {r.target}
	JOIN CatalogVersion
		ON {CatalogVersion.pk} = {p.catalogVersion}
	JOIN Catalog
		ON {Catalog.pk} = {CatalogVersion.catalog}
}


/*err_customproductcatalog_product_not_actionsportsonline*/
SELECT
	{Catalog.id} as catalog_id
	,{CatalogVersion.version} as catalog_version
	,{c.code} as customproductcatalog_code
	,{p.code} as product_code
	,{p.name} as product_name
FROM
  {CustomProductCatalog as c
	JOIN ProductsInCustomPrdCatalog as r
		ON {r.source} = {c.pk}
	JOIN Product! as p
		ON {p.pk} = {r.target}
	JOIN CatalogVersion
		ON {CatalogVersion.pk} = {p.catalogVersion}
	JOIN Catalog
		ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {Catalog.id} NOT IN ('actionsportsProductCatalog')
OR {CatalogVersion.version} <> 'Online'


/*err_customproductcatalog_shipto_wo_customproductcatalog*/
SELECT DISTINCT
  {SHIPTO.uid} as B2BUnit_SHIPTO_uid
FROM
  {B2BUnit as SHIPTO
  JOIN VistaB2BUnitAttributes as a
  	ON {a.pk} = {SHIPTO.b2bUnitAttributes}
  JOIN VistaB2BUnitTypeEnum as e 
  	ON {e.pk}={a.b2bUnitType}
}
WHERE {SHIPTO.active}=1 
AND {e.code} = 'SHIPTO'
AND NOT EXISTS ({{
	SELECT 1 FROM {UsersCustomPrdCatalog} WHERE {UsersCustomPrdCatalog.target} = {SHIPTO.pk}
}})
ORDER BY {SHIPTO.uid}


/*err_product_wo_stock_b2b*/
SELECT DISTINCT {p.code}
FROM {Product as p}
WHERE {p.variantType} IS NULL
AND NOT EXISTS ({{
	SELECT 1
	FROM {StockLevel as s}, {Warehouse as w}
	WHERE {w.code} = 'b2bWarehouse'
	AND {s.productcode} = {p.code}
AND {w.pk} = {s.warehouse}
}})


/*err_product_wo_stock_b2c*/
SELECT DISTINCT {p.code}
FROM {Product as p}
WHERE {p.variantType} IS NULL
AND NOT EXISTS ({{
	SELECT 1
	FROM {StockLevel as s}, {Warehouse as w}
	WHERE {w.code} = 'default'
	AND {s.productcode} = {p.code}
AND {w.pk} = {s.warehouse}
}})



SELECT
	{Catalog.id} as catalog_id
	,{CatalogVersion.version} as catalog_version
	,{c.code} as customproductcatalog_code
	,{p.code} as product_code
	,{p.name} as product_name
FROM
	{B2BUnit as b
	???
	JOIN 
}

  {CustomProductCatalog as c
	JOIN ProductsInCustomPrdCatalog as r
		ON {r.source} = {c.pk}
	JOIN Product! as p
		ON {p.pk} = {r.target}
	JOIN CatalogVersion
		ON {CatalogVersion.pk} = {p.catalogVersion}
	JOIN Catalog
		ON {Catalog.pk} = {CatalogVersion.catalog}
}
WHERE {Catalog.id} NOT IN ('actionsportsProductCatalog')
OR {CatalogVersion.version} <> 'Online'



		<relation code="ProductsInCustomPrdCatalog" generate="true" localized="false" >
			<description>Product to Custom Product Catalog relation</description>
			<deployment table="CustomPrdCatalogProducts" typecode="10101"/>
			<sourceElement type="CustomProductCatalog" qualifier="customProductCatalogs" cardinality="many"></sourceElement>
			<targetElement type="Product" qualifier="products" cardinality="many"></targetElement>
		</relation>
	
		<relation code="UsersCustomPrdCatalog" generate="true" localized="false" >
			<description>Principal User to Custom Product Catalog relation</description>
			<deployment table="CustomPrdCatalogUsers" typecode="10102"/>
			<sourceElement type="CustomProductCatalog" qualifier="customProductCatalogs" cardinality="many"></sourceElement>
			<targetElement type="Principal" qualifier="principals" cardinality="many"></targetElement>
		</relation>


/* MISC */
"date_column" >= ADD_DAYS(CURRENT_DATE,-(WEEKDAY(CURRENT_DATE)+7))
"date_column" < ADD_DAYS(CURRENT_DATE,-(WEEKDAY(CURRENT_DATE)))

AND (
	( to_date({c.starttime}) >= ADD_DAYS(CURRENT_DATE,-(WEEKDAY(CURRENT_DATE)+7)) AND to_date({c.starttime}) < ADD_DAYS(CURRENT_DATE,-(WEEKDAY(CURRENT_DATE))) )
	OR ( to_date({c.creationTime}) >= ADD_DAYS(CURRENT_DATE,-(WEEKDAY(CURRENT_DATE)+7)) AND to_date({c.creationTime}) < ADD_DAYS(CURRENT_DATE,-(WEEKDAY(CURRENT_DATE))) )
)


GROUP BY to_date({c.STARTTIME}), {u.name} || ' (' || {u.uid} || ')', {j.code}
ORDER BY to_date({c.STARTTIME}) DESC, {u.name} || ' (' || {u.uid} || ')', {j.code}


SELECT {u.uid} as user_uid, {s.uid} as basesite_uid
FROM {Customer as u
	LEFT JOIN BaseSite as s ON {s.pk} = {u.site}
}
WHERE {s.uid} is null


SELECT {r.pk}
FROM {PriceRow as r
	JOIN UserPriceGroup 
		ON {r.ug}={UserPriceGroup.pk}
}
WHERE {r.ug} IS NOT NULL


/*err_dup_pricing*/
SELECT
	{Catalog.id}, {CatalogVersion.version}, {p.code}, {r.currency}, {r.ug}, count(*)
FROM {PriceRow as r
	JOIN CatalogVersion
		ON {CatalogVersion.pk} = {r.catalogVersion}
	JOIN Catalog
		ON {Catalog.pk} = {CatalogVersion.catalog}
	JOIN Product as p
		ON {p.pk} = {r.product}
		AND {CatalogVersion.pk} = {p.catalogVersion}
}
GROUP BY {Catalog.id}, {CatalogVersion.version}, {p.code}, {r.currency}, {r.ug}
HAVING count(*) > 1


SELECT
	{Catalog.id}, {CatalogVersion.version}, {p.code}, {Currency.isocode}, {UserPriceGroup.code}
FROM {PriceRow as r
	JOIN CatalogVersion
		ON {CatalogVersion.pk} = {r.catalogVersion}
	JOIN Catalog
		ON {Catalog.pk} = {CatalogVersion.catalog}
	JOIN Product as p
		ON {p.pk} = {r.product}
		AND {CatalogVersion.pk} = {p.catalogVersion}
	LEFT JOIN UserPriceGroup 
		ON {r.ug}={UserPriceGroup.pk}
	JOIN Currency 
		ON {Currency.pk} = {r.currency}
}
GROUP BY {Catalog.id}, {CatalogVersion.version}, {p.code}, {Currency.isocode}, {UserPriceGroup.code}
HAVING count(*) > 1


/*info_consignment*/
SELECT
{Order.pk} as order_pk,
{Order.code} as order_code,
{Order.versionid} as order_versionid,
{Order.originalversion} as order_originalversion,
{OrderStatus1.code} as order_status,
{Order.purchaseordernumber} as order_purchaseordernumber,
{Order.guid} as order_guid,
{OrderUser.uid} as order_user_uid,
{Order.modifiedtime} as order_modifiedtime,
{Order.creationtime} as order_creationtime,
{Order.calculated} as order_calculated,
{Currency.isocode} as order_currency_isocode,
{Order.expirationtime} as order_expirationtime,
{Order.name} as order_name,
{Order.description} as order_description,
{Order.net} as order_net,
{Order.paymentaddress} as order_paymentaddress,
{Order.paymentcost} as order_paymentcost,
{Order.paymentinfo} as order_paymentinfo,
{Order.paymentmode} as order_paymentmode,
{Order.paymentstatus} as order_paymentstatus,
{Order.exportstatus} as order_exportstatus,
{Order.statusinfo} as order_statusinfo,
{Order.totalprice} as order_totalprice,
{Order.totaldiscounts} as order_totaldiscounts,
{Order.totaltax} as order_totaltax,
{Order.totaltaxvaluesinternal} as order_totaltaxvaluesinternal,
{Order.subtotal} as order_subtotal,
{Order.discountsincludedeliverycost} as order_discountsincludedeliverycost,
{Order.discountsincludepaymentcost} as order_discountsincludepaymentcost,
{Order.site} as order_site,
{Order.store} as order_store,
{Order.quotediscountvaluesinternal} as order_quotediscountvaluesinternal,
{Order.locale} as order_locale,
{Order.workflow} as order_workflow,
{Order.quoteexpirationdate} as order_quoteexpirationdate,
{Order.unit} as order_unit,
{Order.paymenttype} as order_paymenttype,
{Order.punchoutorder} as order_punchoutorder,
{Order.appliedcouponcodes} as order_appliedcouponcodes,
{Order.fraudulent} as order_fraudulent,
{Order.potentiallyfraudulent} as order_potentiallyfraudulent,
{Order.salesapplication} as order_salesapplication,
{Order.language} as order_language,
{Order.placedby} as order_placedby,
{OrderDeliveryStatus1.code} as order_ship_status,
{Order.deliverycost} as order_deliverycost,
{OrderDeliveryMode1.code} as order_deliverymode,
{OrderShipAddr.streetname} as order_shipaddr_line1,
{OrderShipAddr.streetnumber} as order_shipaddr_line2,
{OrderShipAddr.town} as order_shipaddr_town,
{OrderShipAddr.postalcode} as order_shipaddr_postalcode,
{OrderShipAddr.region} as order_shipaddr_region,

{Consignment.pk} as consignment_pk,
{Consignment.code} as consignment_code,
{Consignment.shippingaddress} as consignment_shippingaddress,
{ConsignmentDeliveryMode1.code} as consignment_deliverymode,
{Consignment.nameddeliverydate} as consignment_nameddeliverydate,
{Consignment.shippingdate} as consignment_shippingdate,
{Consignment.trackingid} as consignment_trackingid,
{Consignment.carrier} as consignment_carrier,
{ConsignmentCarrier.code} as consignment_carrierdetails,
{ConsignmentStatus.code} as consignment_status,
{ConsignmentWarehouse.code} as consignment_warehouse,
{ConsignmentPointOfService.name} as consignment_deliverypointofservice

FROM {Order
	LEFT JOIN Currency
		ON {Currency.pk} = {Order.currency}
	LEFT JOIN Address as OrderShipAddr
		ON {OrderShipAddr.pk} = {Order.deliveryaddress}
	LEFT JOIN OrderStatus as OrderStatus1
		ON {OrderStatus1.pk} = {Order.status}
	LEFT JOIN DeliveryStatus as OrderDeliveryStatus1
		ON {OrderDeliveryStatus1.pk} = {Order.deliveryStatus}
	LEFT JOIN DeliveryMode as OrderDeliveryMode1
		ON {OrderDeliveryMode1.pk} = {Order.deliveryMode}
	LEFT JOIN User as OrderUser
		ON {OrderUser.pk} = {Order.user}

	LEFT JOIN Consignment
		ON {Consignment.order} = {Order.pk}
	LEFT JOIN DeliveryMode as ConsignmentDeliveryMode1
		ON {ConsignmentDeliveryMode1.pk} = {Consignment.deliveryMode}
	LEFT JOIN Carrier as ConsignmentCarrier
		ON {ConsignmentCarrier.pk} = {Consignment.carrierDetails}
	LEFT JOIN Warehouse as ConsignmentWarehouse
		ON {ConsignmentWarehouse.pk} = {Consignment.warehouse}
	LEFT JOIN ConsignmentStatus
		ON {ConsignmentStatus.pk} = {Consignment.status}
	LEFT JOIN PointOfService as ConsignmentPointOfService
		ON {ConsignmentPointOfService.pk} = {Consignment.deliveryPointOfService}
}
WHERE {Order.code} = '00001110'
ORDER BY {Order.modifiedtime} DESC


/*info_order_history_detail*/
SELECT
{Order.code} as order_code,
{OrderEntry.entryNumber} as orderentry_entrynumber,
{Product.code} as product_code,
{OrderBaseSite.uid} as order_basesite_uid,
{OrderBaseStore.uid} as order_basestore_uid,
{Order.versionid} as order_versionid,
{Order.originalversion} as order_originalversion,
{OrderStatus1.code} as order_status,
{OrderDeliveryStatus.code} as order_ship_status,
{Order.purchaseordernumber} as order_purchaseordernumber,
{Order.guid} as order_guid,
{OrderUser.uid} as order_user_uid,
{Order.modifiedtime} as order_modifiedtime,
{Order.creationtime} as order_creationtime,
{Currency.isocode} as order_currency_isocode,
{Order.net} as order_net,
{Order.totalprice} as order_totalprice,
{Order.totaldiscounts} as order_totaldiscounts,
{Order.totaltax} as order_totaltax,
{Order.subtotal} as order_subtotal,
{Order.deliverycost} as order_deliverycost,
{CheckoutPaymentType.code} as order_payment_type,
{PaymentStatus.code} as order_payment_status,
{Order.paymentaddress} as order_paymentaddress,

{Consignment.code} as consignment_code,
{Consignment.shippingaddress} as consignment_shippingaddress,
{ConsignmentDeliveryMode1.code} as consignment_deliverymode,
{Consignment.nameddeliverydate} as consignment_nameddeliverydate,
{Consignment.shippingdate} as consignment_shippingdate,
{Consignment.trackingid} as consignment_trackingid,
{Consignment.carrier} as consignment_carrier,
{ConsignmentCarrier.code} as consignment_carrierdetails,
{ConsignmentStatus.code} as consignment_status,
{ConsignmentWarehouse.code} as consignment_warehouse,
{ConsignmentPointOfService.name} as consignment_deliverypointofservice,

{Product.name} as product_name,
{OrderEntry.quantity} as orderentry_quantity,
{OrderEntry.totalPrice} as orderentry_totalPrice,
{OrderEntry.unit} as orderentry_unit,

{ConsignmentEntry.quantity} as orderentry_quantity,
{ConsignmentEntry.shippedQuantity} as ConsignmentEntry_shippedQuantity,

{OrderEntryDeliveryMode.code} as orderEntry_deliverymode,
{OrderEntryShipAddress.streetname} as orderEntry_shipaddr_line1,
{OrderEntryShipAddress.streetnumber} as orderEntry_shipaddr_line2,
{OrderEntryShipAddress.town} as orderEntry_shipaddr_town,
{OrderEntryShipAddress.postalcode} as orderEntry_shipaddr_postalcode,
{OrderEntryShipAddress.region} as orderEntry_shipaddr_region

FROM {Order
	LEFT JOIN Currency
		ON {Currency.pk} = {Order.currency}
	LEFT JOIN OrderStatus as OrderStatus1
		ON {OrderStatus1.pk} = {Order.status}
	LEFT JOIN DeliveryStatus as OrderDeliveryStatus
		ON {OrderDeliveryStatus.pk} = {Order.deliveryStatus}
	LEFT JOIN User as OrderUser
		ON {OrderUser.pk} = {Order.user}
	LEFT JOIN BaseSite as OrderBaseSite
		ON {OrderBaseSite.pk} = {Order.site}
	LEFT JOIN BaseStore as OrderBaseStore
		ON {OrderBaseStore.pk} = {Order.store}
	LEFT JOIN PaymentStatus
		ON {Order.paymentStatus} = {PaymentStatus.pk}
	LEFT JOIN CheckoutPaymentType
		ON {CheckoutPaymentType.pk} = {Order.paymentType}

	LEFT JOIN Consignment
		ON {Consignment.order} = {Order.pk}
	LEFT JOIN DeliveryMode as ConsignmentDeliveryMode1
		ON {ConsignmentDeliveryMode1.pk} = {Consignment.deliveryMode}
	LEFT JOIN Carrier as ConsignmentCarrier
		ON {ConsignmentCarrier.pk} = {Consignment.carrierDetails}
	LEFT JOIN Warehouse as ConsignmentWarehouse
		ON {ConsignmentWarehouse.pk} = {Consignment.warehouse}
	LEFT JOIN ConsignmentStatus
		ON {ConsignmentStatus.pk} = {Consignment.status}
	LEFT JOIN PointOfService as ConsignmentPointOfService
		ON {ConsignmentPointOfService.pk} = {Consignment.deliveryPointOfService}

	LEFT JOIN OrderEntry
		ON {OrderEntry.order} = {Order.pk}
	LEFT JOIN DeliveryMode as OrderEntryDeliveryMode
		ON {OrderEntryDeliveryMode.pk} = {OrderEntry.deliveryMode}
	LEFT JOIN Address as OrderEntryShipAddress
		ON {OrderEntryShipAddress.pk} = {OrderEntry.deliveryAddress}

	LEFT JOIN Product
		ON {Product.pk} = {OrderEntry.product}

	JOIN ConsignmentEntry
		ON {ConsignmentEntry.orderEntry} = {OrderEntry.pk}
		AND {ConsignmentEntry.consignment} = {Consignment.pk}
}
WHERE {Order.code} = '00001110'
AND {Order.versionid} IS NULL
ORDER BY {Order.code}, {OrderEntry.entryNumber}
