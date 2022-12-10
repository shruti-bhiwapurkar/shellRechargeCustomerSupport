public with sharing class OmniSupervisorController {
    
    public static final String ACTIVE_STATUS = 'Active';
    public static final String INACTIVE_STATUS = 'Inactive';

    //This method gets summary for all agents
    @AuraEnabled
    public static List<AllAgentsSummaryWrapper> getAllAgentsSummary(){
        try {
            //Get UserServicePresence records for users which gives information about the status configuration etc
            List<UserServicePresence> userspList = getUserServicePresence(null);
            
            if(userspList != null && !userspList.isEmpty()) {

                List<Id> userIdList = new List<Id>();
                for(UserServicePresence usersp : userspList) {
                    userIdList.add(usersp.UserId);
                }
                
                Map<Id, List<String>> userVsQueueMap = new Map<Id, List<String>>();
                Map<Id, List<String>> userVsSkillMap = new Map<Id, List<String>>();
                Map<Id, Integer> userVsCaseMap = new Map<Id, Integer>();

                if(!userIdList.isEmpty()) {
                    //Get the queue membership of the Agent
                    userVsQueueMap = getUserQueueMembership(userIdList);
                    
                    //Get the assigned skills of the agent
                    userVsSkillMap = getUserSkillMapping(userIdList);
                    
                    //Get the assigned cases to the agent
                    userVsCaseMap = getUserOpenCaseCount(userIdList);                    
                }
                //Prepare response wrapper
                List<AllAgentsSummaryWrapper> agentSumWrpList = new List<AllAgentsSummaryWrapper>();

                for(UserServicePresence usersp : userspList) {
                    AllAgentsSummaryWrapper agentSumWrp = new AllAgentsSummaryWrapper();
                    agentSumWrp.agentId = usersp.UserId;
                    agentSumWrp.agentName = usersp.User.Name;
                    
                    //Since only last record is saved which could be or not be the current status of the user
                    if(usersp.ServicePresenceStatus.DeveloperName == ACTIVE_STATUS) {

                        if(usersp.IsCurrentState) {
                            agentSumWrp.status = usersp.ServicePresenceStatus.DeveloperName;
                        } else{
                            agentSumWrp.status = INACTIVE_STATUS;
                        }
                    } else {
                        agentSumWrp.status = usersp.ServicePresenceStatus.DeveloperName;
                    }

                    agentSumWrp.since = usersp.StatusStartDate.format('dd-MM-yyyy hh:mm:ss a');
                    agentSumWrp.configuredCapacity = usersp.ConfiguredCapacity;
                    agentSumWrp.assignedQueue = userVsQueueMap.get(usersp.UserId);
                    agentSumWrp.skillsList = userVsSkillMap.get(usersp.UserId);
                    
                    if(userVsCaseMap.containsKey(usersp.UserId)) {
                        agentSumWrp.assignedCases = userVsCaseMap.get(usersp.UserId);
                        Decimal capacity = (Decimal) ( (Decimal) userVsCaseMap.get(usersp.UserId) / (Decimal)usersp.ConfiguredCapacity) * 100;
                        agentSumWrp.capacity = capacity;
                    } else {
                        agentSumWrp.assignedCases = 0;
                        agentSumWrp.capacity = 0;
                    }

                    agentSumWrpList.add(agentSumWrp);
                }
                
                return agentSumWrpList;
            }

            return null;
 
        } catch (Exception ex) {
            System.debug('*** ex : ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //This method gets summary for per agent
    @AuraEnabled
    public static PerAgentsSummaryWrapper getPerAgentSummary(String userId){
        try {
            PerAgentsSummaryWrapper perAgtWrp;

            if(!String.isBlank(userId)) {
                //Get UserServicePresence record for the user (userId) which gives information about the status configuration etc
                List<UserServicePresence> userspList = getUserServicePresence(userId);
                
                //Prepare response wrapper
                if(userspList != null && !userspList.isEmpty()) {
                    perAgtWrp = new PerAgentsSummaryWrapper();
                    perAgtWrp.agentName = userspList[0].User.Name;
                    perAgtWrp.agentId = userspList[0].UserId;

                    //Since only last record is saved which could be or not be the current status of the user                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ```````
                    if(userspList[0].ServicePresenceStatus.DeveloperName == ACTIVE_STATUS) {

                        if(userspList[0].IsCurrentState) {
                            perAgtWrp.status = userspList[0].ServicePresenceStatus.DeveloperName;
                        } else{
                            perAgtWrp.status = INACTIVE_STATUS;
                        }
                    } else {
                        perAgtWrp.status = userspList[0].ServicePresenceStatus.DeveloperName;
                    }
                    perAgtWrp.since = userspList[0].StatusStartDate.format('dd-MM-yyyy hh:mm:ss a');

                    List<Id> userIdList = new List<Id>();
                    userIdList.add(userId);

                    Map<Id, Integer> openCaseCountMap = getUserOpenCaseCount(userIdList);
                    Integer openCaseCount = (!openCaseCountMap.isEmpty() && openCaseCountMap.containsKey(Id.valueOf(userId)) && openCaseCountMap.get(Id.valueOf(userId)) != null) ? openCaseCountMap.get(Id.valueOf(userId)) : 0;
                    perAgtWrp.openCases = openCaseCount;
                    
                    perAgtWrp.configuredCapacity = userspList[0].ConfiguredCapacity;
                    perAgtWrp.assignedQueue = getUserQueueMembership(userIdList).get(Id.valueOf(userId));
                    perAgtWrp.skillsList = getUserSkillMapping(userIdList).get(Id.valueOf(userId));
                    perAgtWrp.openCasesList = getUserOpenCases(userId);
                    perAgtWrp.closedCasesList = getUserClosedCases(userId);
                    perAgtWrp.closedCases = getUserClosedCaseCount(perAgtWrp.closedCasesList);
                    perAgtWrp.avgTimeToCloseCase = getAvgTimeToCloseCases(perAgtWrp.closedCasesList);
                }
            }

            return perAgtWrp;
        } catch (Exception ex) {
            System.debug('*** ex : ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //This method gets list of all agents 
    @AuraEnabled
    public static List<Option> getAgentsList(){
        try {
            List<UserServicePresence> userspList = getUserServicePresence(null);
            List<Option> agentsList = new List<Option>();
            
            if(userspList != null && !userspList.isEmpty()) {
                for(UserServicePresence usp : userspList) {
                    Option agent = new Option();
                    agent.value = usp.UserId;
                    agent.label = usp.User.Name;

                    agentsList.add(agent);
                }
            }
            
            return agentsList;

        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //This method gets list of users who have Customer: Support Profile and System Administrator(this profile is added only for comparision purpose due to lack of licenses)
    @AuraEnabled
    public static List<Option> getCaseOwners(){
        List<Option> userOptionList = new List<Option>();
        try {
            //Add default option as placeholder disparrears once a value is selected in the combobox
            Option usrPh = new Option();
            usrPh.value = null;
            usrPh.label = 'Choose Value';
            userOptionList.add(usrPh);

            List<User> userList = [SELECT Id, Name FROM User 
                                    WHERE IsActive = true
                                        AND UserType = 'Standard'
                                        AND Profile.Name IN ('Custom: Support Profile', 'System Administrator')];

            if(userList != null && !userList.isEmpty()) {
                for(User usr : userList) {
                    Option usrOpt = new Option();
                    usrOpt.value = usr.Id;
                    usrOpt.label = usr.Name;

                    userOptionList.add(usrOpt);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return userOptionList;
    }

    //This method searches cases based on filter
    @AuraEnabled
    public static List<CaseWrapper> searchCasesBasedOnFilter(String filter){
        //Prepare response
        List<CaseWrapper> caseWrpList = new List<CaseWrapper>();
        try {
            String query;
            if(filter != null && !String.isBlank(filter.trim())) {
                query = 'SELECT Id, CaseNumber, Type, Status, Reason, Origin, Subject, Priority, ClosedDate, CreatedDate, isClosed FROM Case WHERE ' + filter;
            }else{ 
                query = 'SELECT Id, CaseNumber, Type, Status, Reason, Origin, Subject, Priority, ClosedDate, CreatedDate, isClosed FROM Case';
            }
            
            List<Case> caseList = Database.query(query);

            if(caseList != null && !caseList.isEmpty()) {
                for(Case cs : caseList) {
                    CaseWrapper csWrp = new CaseWrapper();
                    csWrp.caseId = cs.Id;
                    csWrp.caseNumber = cs.CaseNumber;
                    csWrp.type = cs.Type;
                    csWrp.status = cs.Status;
                    csWrp.reason = cs.Reason;
                    csWrp.origin = cs.Origin;
                    csWrp.subject = cs.Subject;
                    csWrp.priority = cs.Priority;
                    csWrp.createdDate = cs.ClosedDate;
                    csWrp.closedDate = cs.CreatedDate;
                    caseWrpList.add(csWrp);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return caseWrpList;
    }

    //This method gets UserServicePresence data for the user Id supplied, if User Id is not supplied it gets data for all users
    private static List<UserServicePresence> getUserServicePresence(Id userId) {
        List<UserServicePresence> userspList;
        List<AggregateResult> aggUserspList;

        if(userId != null) {
            aggUserspList = [SELECT MAX(Id) spId, MAX(CreatedDate) FROM UserServicePresence WHERE userId = :userId];
        } else {
            aggUserspList = [SELECT MAX(Id) spId, User.Name, MAX(CreatedDate) FROM UserServicePresence GROUP BY User.Name];
        }
        
        List<Id> userspIdList = new List<Id>();

        if(aggUserspList != null && !aggUserspList.isEmpty()){
            for(AggregateResult agg : aggUserspList) {
                userspIdList.add((Id) agg.get('spId'));
            }
        }
        
        userspList = [SELECT Id, UserId, User.Name, ServicePresenceStatus.DeveloperName, StatusStartDate, ConfiguredCapacity, IsCurrentState 
                        FROM UserServicePresence 
                        WHERE Id IN :userspIdList];
        
        return userspList;
    }

    //This method gets queue assignment for provided user Id list
    private static Map<Id, List<String>> getUserQueueMembership(List<Id> userIdList) {
        Map<Id, List<String>> userVsQueueMap = new Map<Id, List<String>>();

        if(userIdList != null && !userIdList.isEmpty()) {

            List<GroupMember> queueList = [SELECT Id, Group.name, UserOrGroupId 
                                            FROM GroupMember 
                                            WHERE UserOrGroupId IN :userIdList AND Group.Type = 'Queue'];
         
            if(queueList != null && !queueList.isEmpty()) {
                for(GroupMember queue : queueList) {
                    if(userVsQueueMap.containsKey(queue.UserOrGroupId)) {
                        userVsQueueMap.get(queue.UserOrGroupId).add(queue.Group.name);
                    } else {
                        List<String> userQueueList = new List<String>();
                        userQueueList.add(queue.Group.name);
                        userVsQueueMap.put(queue.UserOrGroupId, userQueueList);
                        //Run time exception - Attempt to de-reference null object
                        //userVsQueueMap.put(queue.UserOrGroupId, (List<String>) new List<String>().add(queue.Group.name));
                    }
                }
            }
        }
        return userVsQueueMap;
    }

    //This method gets skill assignment for provided user Id list
    private static Map<Id, List<String>> getUserSkillMapping(List<Id> userIdList) {
        Map<Id, List<String>> userVsSkillMap = new Map<Id, List<String>>();

        if(userIdList != null && !userIdList.isEmpty()) {
            List<ServiceResourceSkill> serResSkillList = [SELECT Id, ServiceResource.RelatedRecord.Name, ServiceResource.RelatedRecordId, Skill.MasterLabel, SkillLevel 
                                                                    FROM ServiceResourceSkill
                                                                    WHERE ServiceResource.RelatedRecordId IN :userIdList 
                                                                        AND ServiceResource.IsActive = true];
            
            if(serResSkillList != null && !serResSkillList.isEmpty()) {
                for(ServiceResourceSkill serResSkill : serResSkillList) {
                    if(userVsSkillMap.containsKey(serResSkill.ServiceResource.RelatedRecordId)) {
                        userVsSkillMap.get(serResSkill.ServiceResource.RelatedRecordId).add(serResSkill.Skill.MasterLabel + '(' + serResSkill.SkillLevel + ')');
                    } else {
                        List<String> userSkillList = new List<String>();
                        userSkillList.add(serResSkill.Skill.MasterLabel);
                        userVsSkillMap.put(serResSkill.ServiceResource.RelatedRecordId, userSkillList);
                        //Run time exception - Attempt to de-reference null object
                        //userVsSkillMap.put(serResSkill.ServiceResource.RelatedRecordId, (List<String>) new List<String>().add(serResSkill.Skill.MasterLabel));
                    }
                }
            }
        }
        return userVsSkillMap;
    }

    //This method gets open case count for provided user Id list
    private static Map<Id, Integer> getUserOpenCaseCount(List<Id> userIdList) {
        Map<Id, Integer> userVsCaseMap = new Map<Id, Integer>();

        if(userIdList != null && !userIdList.isEmpty()) {
            List<AggregateResult> caseList = [SELECT OwnerId, count(Id) ct
                                                FROM Case 
                                                WHERE isClosed = false AND OwnerId IN :userIdList
                                                GROUP BY OwnerId];
                        
            if(caseList != null && !caseList.isEmpty()) {
                for(AggregateResult cs : caseList) {
                    userVsCaseMap.put((Id) cs.get('OwnerId'), (Integer) cs.get('ct'));
                }        
            }
        }
        return userVsCaseMap;
    }

    //This method gets list of open cases for provided user Id
    private static List<CaseWrapper> getUserOpenCases(Id userId) {
        List<CaseWrapper> caseWrpList = new List<CaseWrapper>();

        if(userId != null) {
            List<Case> caseList = [SELECT Id, CaseNumber, Type, Status, Reason, Origin, Subject, Priority, ClosedDate, CreatedDate, isClosed 
                                    FROM Case 
                                    WHERE isClosed = false AND OwnerId = :userId];
           
            if(caseList != null && !caseList.isEmpty()) {
                for(Case cs : caseList) { 
                    CaseWrapper csWrp = wrapCase(cs);
                    caseWrpList.add(csWrp);
                }
            }
        }
        return caseWrpList;
    }

    //This method gets closed case count for provided user Id list
    private static Integer getUserClosedCaseCount(List<CaseWrapper> caseList) {
        
        if(caseList != null && !caseList.isEmpty()) {
            return caseList.size();
        }
        return 0;
    }

    //This method gets list of closed cases for provided user Id
    public static List<CaseWrapper> getUserClosedCases(Id userId) {
        List<CaseWrapper> caseWrpList = new List<CaseWrapper>();
        if(userId != null) {
            List<Case> caseList = [SELECT Id, CaseNumber, Type, Status, Reason, Origin, Subject, Priority, ClosedDate, CreatedDate, isClosed
                                    FROM Case 
                                    WHERE isClosed = true AND OwnerId = :userId];
            System.debug('*** close case caseList : ' + caseList);            
            if(caseList != null && !caseList.isEmpty()) {
                for(Case cs : caseList) { 
                    CaseWrapper csWrp = wrapCase(cs);
                    caseWrpList.add(csWrp);
                }
            }
        }
        return caseWrpList;
    }
    
    //This method calculates the average time for an agent to close a case
    private static Decimal getAvgTimeToCloseCases(List<CaseWrapper> caseList) {
        Decimal avgDiffInHour;
        if(caseList != null && !caseList.isEmpty()) {
            Decimal minutesDifference = 0;
            for(CaseWrapper cs : caseList) {
                minutesDifference += calculateDatetimeDifference(cs.closedDate, cs.createdDate);
            }

            avgDiffInHour = Math.floor(minutesDifference / 60 / caseList.size());
        }
        return avgDiffInHour;
    }

    //This method populates the Case wrapper since direct case was not readable in LWC component as it can get extra information like API calls
    private static CaseWrapper wrapCase(Case cs) {
        CaseWrapper caseWrp = new CaseWrapper();
        
        if(cs != null) {
            caseWrp.caseId = cs.Id;
            caseWrp.caseNumber = cs.CaseNumber;
            caseWrp.type = cs.Type;
            caseWrp.status = cs.Status;
            caseWrp.reason = cs.Reason;
            caseWrp.origin = cs.Origin;
            caseWrp.subject = cs.Subject;
            caseWrp.priority = cs.Priority;
            caseWrp.createdDate = cs.CreatedDate;
            if(cs.IsClosed) {
                caseWrp.closedDate = cs.ClosedDate;
            }
        }
        
        return caseWrp;
    }

    //This method calculates the difference between two datetimes
    private static Decimal calculateDatetimeDifference(Datetime startDatetime, Datetime endDatetime) {
        
        Integer daysDiff = startDatetime.Date().daysBetween(endDatetime.Date());
        
        Datetime sameDayEndDate = startDatetime.addDays(daysDiff);
        
        Decimal decHours = ((endDatetime.getTime())/1000/60/60) - ((sameDayEndDate.getTime())/1000/60/60);
       
        Decimal minutesDiff;
        if(daysDiff >= 1) { 
            minutesDiff = (((daysDiff - 1) * 24) * 60) + ((24 - decHours) * 60);
        } else {
            minutesDiff = decHours * 60;
        }
        
        return minutesDiff;
    }

    public class AllAgentsSummaryWrapper {
        @AuraEnabled
        public String agentName;
        @AuraEnabled
        public Id agentId;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String since;
        @AuraEnabled
        public Decimal capacity;
        @AuraEnabled
        public Integer assignedCases;
        @AuraEnabled
        public Integer configuredCapacity;
        @AuraEnabled
        public List<String> assignedQueue;
        @AuraEnabled
        public List<String> skillsList;
    }

    public class PerAgentsSummaryWrapper {
        @AuraEnabled
        public String agentName;
        @AuraEnabled
        public Id agentId;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String since;
        @AuraEnabled
        public Integer openCases;
        @AuraEnabled
        public Integer closedCases;
        @AuraEnabled
        public Integer configuredCapacity;
        @AuraEnabled
        public List<String> assignedQueue;
        @AuraEnabled
        public List<String> skillsList;
        @AuraEnabled
        public List<CaseWrapper> openCasesList;
        @AuraEnabled
        public List<CaseWrapper> closedCasesList;
        @AuraEnabled
        public Decimal avgTimeToCloseCase;
    }

    public class Option {
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String label;
    }

    public class CaseWrapper {
        @AuraEnabled
        public Id caseId;
        @AuraEnabled
        public String caseNumber;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String reason;
        @AuraEnabled
        public String origin;
        @AuraEnabled
        public String subject;
        @AuraEnabled
        public String priority;
        @AuraEnabled
        public Datetime createdDate;
        @AuraEnabled
        public Datetime closedDate; 
    }
}
