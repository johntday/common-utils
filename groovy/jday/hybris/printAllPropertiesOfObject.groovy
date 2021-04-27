package jday.hybris

result = spring.getBean("flexibleSearchService").search("select {pk} from {Language}")
// properties
result.properties.each { println "$it.key -> $it.value" }
