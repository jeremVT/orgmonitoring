import { LightningElement, wire } from 'lwc';
import { gql, graphql} from "lightning/uiGraphQLApi" ;

export default class GraphqlContacts extends LightningElement {
  @wire(graphql, {
    query: gql`
      query getContacts {
        uiapi {
          query {
            Contact(first: 5, orderBy: { Name: { order: ASC } }) {  
              edges {
                node {
                  Name {
                    value
                    displayValue
                  }
                }
              }
            }
          }
        }
    }
  `
})
graphql;

get contacts()
  {
    return this.graphql.data.uiapi.query.Contact.edges.map((edge) => ({
      Name: edge.node.Name.value  
    }));
  }
}