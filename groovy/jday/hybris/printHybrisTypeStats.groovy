package jday.hybris

import de.hybris.platform.servicelayer.search.FlexibleSearchQuery
//import de.hybris.platform.hac.facade.impl.DefaultFlexibleSearchFacade;
import de.hybris.platform.servicelayer.search.SearchResult;

flexibleSearch = spring.getBean("flexibleSearchService")
//flexibleSearchFacade = new DefaultFlexibleSearchFacade();
typeService = spring.getBean("typeService");

result = flexibleSearch.search(/select {pk} from {ComposedType}/).getResult()
hybris.clone.Tree tree = new hybris.clone.Tree();
result.each {
    hybris.clone.Node node = new hybris.clone.Node(it.getCode(), it.getSuperType()?.getCode());
    type = it.getClass().getSimpleName();
    isabstract = it.getAbstract() ? "<abstract>" : "";
    isjaloonly = it.getJaloonly() ? "<jaloonly>" : "";
    type = type.replace("ComposedTypeModel", "<Composed>");
    type = type.replace("RelationMetaTypeModel", "<Relation>");
    type = type.replace("EnumerationMetaTypeModel", "<ENUM>");
    type = type.replace("TypeModel", "");
    node.setDetails(type + isabstract + isjaloonly);
    tree.getElements().add(node);
}

for (element in tree.getElements()) {
    node1 = tree.find(element.getValue());
    node2 = tree.find(element.getParentValue());
    if (node1 != null) {
        node1.setParent(node2);
    }
    if (node2 != null) {
        node2.addChild(node1);
    }
    if (element.getParentValue() == null) {
        root = node1;
    }
}

displaySubTree(tree, 0, root, root.getValue());

void printANode(level, hybris.clone.Node item, String history) {
    count = "-";

    if (!item.getNotLeaf() && !item.getDetails().contains("<abstract>")
            && !item.getDetails().contains("<jaloonly>")) {
        count = calculateCount(item.getValue())
    }

    println history + "\t" + item.getValue() + "(" + item.getDetails() + ") \t" + count;

}

void displaySubTree(hybris.clone.Tree tree, int level, hybris.clone.Node node, String history) {
    List<hybris.clone.Node> subItems = node.getChildren();
    if (subItems.size() == 0) {
        printANode(level, node, history);
    }
    for (item in subItems) {
        printANode(level + 1, item, history);
        if (item.getChildren().size() != 0) {
            displaySubTree(tree, level + 1, item, history + "=>" + item.getValue());
        }
    }
}

public class Tree {
    List<hybris.clone.Node> elements;

    public List<hybris.clone.Node> getElements() { return elements; }

    public Tree() {
        elements = new ArrayList();
    }

    public void add(hybris.clone.Node element) {
        elements.add(element);
    }

    public hybris.clone.Node find(String value) {
        for (it in elements) {
            if (it.getValue() == value) {
                return it;
            }
        }
    }
}

public class Node {
    private hybris.clone.Node parent = null;
    private List<hybris.clone.Node> children = null;
    private String value;
    private String details = "";
    private String parentValue = "";
    private Boolean notLeaf = false;

    public Node(String value, String parent) {
        this.children = new ArrayList<>();
        this.value = value;
        this.parentValue = parent;
    }

    public setNotLeaf(Boolean itIsNotALeaf) {
        notLeaf = itIsNotALeaf;
    }

    public getNotLeaf(Boolean itIsNotALeaf) {
        return notLeaf;
    }

    public List<hybris.clone.Node> getChildren() {
        return children;
    }

    public void addChild(hybris.clone.Node child) {
        children.add(child);
        child.addParent(this);
    }

    public addParent(hybris.clone.Node parentNode) {
        parent = parentNode;
    }

    public getValue() {
        return value;
    }

    public String getParentValue() {
        return parentValue;
    }

    public setParent(hybris.clone.Node node) {
        parent = node;
    }

    public getParent() {
        return parent;
    }

    public setDetails(String nodeDetails) {
        details = nodeDetails;
    }

    public getDetails() { return details; }
}

String calculateCount(component) {
    query = "select count({pk}) from {" + component + "}";
    FlexibleSearchQuery fquery = new FlexibleSearchQuery(query);
    fquery.setResultClassList(Arrays.asList(String.class));
    fquery.setCount(1);
    SearchResult<String> result = flexibleSearch.search(fquery);
    return (result.getResult()?.get(0));
}
