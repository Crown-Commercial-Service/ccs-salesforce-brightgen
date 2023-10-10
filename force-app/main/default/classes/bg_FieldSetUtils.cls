/******************************************************
 *  bg_FieldSetUtils
 *
 *  Utils class for field sets
 *
 *  Author: James Burgess - BrightGen Ltd
 *  Date:   14/09/2017
 *  Changes:
 *
 ******************************************************/
public class bg_FieldSetUtils {

    @testVisible private static Map<String, Map<String, Schema.FieldSet>> fieldSetMapByObjectName;

    /*
    *   Use the schema to query out the field set map for the given object, caching the result
    *   to save on execute time if needed again, then return the required field set
    */
    public static List<Schema.FieldSetMember> GetFieldSet(String objectName, String fieldSetName)
    {
        if (fieldSetMapByObjectName == null)
        {
            fieldSetMapByObjectName = new Map<String, Map<String, Schema.FieldSet>>();
        }

        if (!fieldSetMapByObjectName.containsKey(objectName))
        {
            List<String> objects = new List<String>{objectName};
            fieldSetMapByObjectName.put(objectName, Schema.describeSObjects(objects).get(0).fieldSets.getMap());
        }
        return fieldSetMapByObjectName.get(objectName).get(fieldSetName).getFields();
    }
}