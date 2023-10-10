/*
Title: bg_CaseEmailsReparent_Controller_Test
Date: 16/09/2020
Author: JAG
Description: Test class for bg_CaseEmailsReparent_Controller.
*/
@isTest
public with sharing class bg_CaseEmailsReparent_Controller_Test 
{
    @isTest
    private static void testGetEmails()
    {
        Case cs = new Case();
        cs.subject = 'abctest';
        insert cs;

        EmailMessage em = new EmailMessage();
        em.Subject = 'testabc';
        em.ParentId = cs.Id;
        insert em;

        List<EmailMessage> ems = bg_CaseEmailsReparent_Controller.getEmails(cs.Id);
        System.assertEquals(1, ems.size());
    }

    @isTest
    private static void testTransferEmails()
    {
        Case cs = new Case();
        cs.subject = 'abctest';
        insert cs;

        Case cs2 = new Case();
        cs2.subject = 'abctest2';
        insert cs2;

        EmailMessage em = new EmailMessage();
        em.Subject = 'testabc';
        em.ParentId = cs.Id;
        insert em;

        Map<String, String> emMap = new Map<String, String>{'Id' => em.Id};
        List<Map<String, String>> emListMap = new List<Map<String, String>>();
        emListMap.add(emMap);

        bg_CaseEmailsReparent_Controller.transferEmails(cs.Id, cs2.Id, emListMap);

        //EmailMessage is cloned and original deleted during transfer.
        EmailMessage emTransferred = [SELECT Id, ParentId FROM EmailMessage LIMIT 1];

        System.assertNotEquals(cs.Id, emTransferred.ParentId);
        System.assertEquals(cs2.Id, emTransferred.ParentId);
    }
}