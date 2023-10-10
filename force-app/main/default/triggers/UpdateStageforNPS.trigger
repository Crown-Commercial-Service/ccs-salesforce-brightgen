trigger UpdateStageforNPS on Case (before update) {
     for ( Case c : trigger.new){
        if(c.Stage_with_seq__c == '090-Closing Actions') {
            (c.Survey_Required__c = true);
                }
     }
}