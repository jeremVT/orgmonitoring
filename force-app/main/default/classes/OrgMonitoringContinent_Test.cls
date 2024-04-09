/*------------------------------------------------------------
Author:         Salvatore Aversano
Company:        Salesforce.com
Description:    Test Class
Test Class for  OrgMonitoringContinent
History
04/04/2024     Salvatore Aversano    Create version
------------------------------------------------------------*/
@isTest
public class OrgMonitoringContinent_Test {

    @isTest
    static void testMatchToContinent() {
        // Test cases for countries and their expected continents
        Map<String, String> testCases = new Map<String, String>{
            'United States' => 'North America',
            'Canada' => 'North America',
            'Mexico' => 'North America',
            'India' => 'Asia',
            'Brazil' => 'South America'
        };
        
        // Iterate through test cases
        for (String country : testCases.keySet()) {
            String expectedContinent = testCases.get(country);
            String actualContinent = OrgMonitoringContinent.matchToContinent(country);
            System.assertEquals(expectedContinent, actualContinent, 'Failed for country: ' + country);
        }
    }

    @isTest
    static void testMatchToContinent_InvalidCountry() {
        // Test case for an invalid country
        String invalidCountry = 'Invalid Country';
        String expectedContinent = 'Unknown';
        String actualContinent = OrgMonitoringContinent.matchToContinent(invalidCountry);
        System.assertEquals(expectedContinent, actualContinent, 'Failed for invalid country');
    }
}
