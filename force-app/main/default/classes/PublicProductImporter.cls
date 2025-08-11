public without sharing class PublicProductImporter {
    public static void fetchAndInsertProducts() {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.restful-api.dev/objects');
        req.setMethod('GET');

        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            System.debug('API Response: ' + res.getBody());

            List<Object> rawList = (List<Object>) JSON.deserializeUntyped(res.getBody());
            List<Product2> productList = new List<Product2>();

            Set<String> extIdSet = new Set<String>();

            // Collect external IDs to avoid duplicates
            for (Object obj : rawList) {
                Map<String, Object> productMap = (Map<String, Object>) obj;
                String extId = (String) productMap.get('id');
                if (!String.isBlank(extId)) {
                    extIdSet.add(extId);
                }
            }

            // Query existing products to prevent duplicates
            Map<String, Product2> existingProducts = new Map<String, Product2>(
                [SELECT Id, ExternalId FROM Product2 WHERE ExternalId IN :extIdSet]
            );

            for (Object obj : rawList) {
                Map<String, Object> productMap = (Map<String, Object>) obj;
                String name = (String) productMap.get('name');
                String extId = (String) productMap.get('id');
                Object data = productMap.get('data');

                // Skip duplicates or missing external IDs
                if (String.isBlank(extId) || existingProducts.containsKey(extId)) {
                    continue;
                }

                

                // Create Product2 record
                Product2 p = new Product2();
                p.Name = name;
                p.IsActive = true;
                p.ExternalId = extId;
                p.Family = 'Smartphones';
                
                

                // Build Description from API data
                String descp = '';
                if (data != null && data instanceof Map<String, Object>) {
                    Map<String, Object> dataMap = (Map<String, Object>) data;
                    if (dataMap.containsKey('color')) {
                        descp += 'Color: ' + String.valueOf(dataMap.get('color')) + '; ';
                    }
                    if (dataMap.containsKey('capacity')) {
                        descp += 'Capacity: ' + String.valueOf(dataMap.get('capacity')) + '; ';
                    }
                }
                if (String.isBlank(descp)) {
                    descp = 'Imported product';
                }

                p.Description = descp; // ✅ Using standard field

                productList.add(p);
            }

            // Insert new products
            if (!productList.isEmpty()) {
                insert productList;
                System.debug('Inserted ' + productList.size() + ' new products.');
            } else {
                System.debug('No new products to insert.');
            }
        } else {
            System.debug('API call failed with status: ' + res.getStatusCode());
        }
    }
}