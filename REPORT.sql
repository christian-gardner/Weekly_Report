select 
A.APP_ID,
to_char((A.REPORT_DATE - 7),'mm/dd/yy')||' to '||to_char(A.REPORT_DATE,'mm/dd/yy')  period, 
A.MODULE||'-'||B.APP_DESCRIPTION AS MODULE, 
B.APP_EXPECT_INPUT,
B.APP_EXPECT_COMPLETED,
B.APP_EXPECT_NBR_USERS,
A.LOADED,
A.WORKING, 
A.COMPLETED,
A.ACTIVE
from APEX_WEEKLY_REPORT A
LEFT JOIN ( SELECT *  FROM SG_APEX_APPLICATIONS ) B ON (A.APP_ID = B.APP_ID)
WHERE TRUNC(A.REPORT_DATE) = TRUNC(SYSDATE)
order by  A.APP_ID, A.report_date desc;


SELECT A.APP_ID,
 TO_CHAR(( A.REPORT_DATE -7),'mm/dd/yy')||' to '||to_char(A.REPORT_DATE,'mm/dd/yy') period, 
     A.APEX_APPLICATION,
     A.EMPLOYEES_ADDED, 
     A.ACTIVE_EMPLOYEES,
     A.DEACTIVATED_EMPLOYEES,
     A.TERMINATED_EMPLOYEES 
from APEX_APPLICATION_USAGE A
LEFT JOIN ( SELECT APP_ID, APP_DESCRIPTION  FROM SG_APEX_APPLICATIONS ) B ON (A.APP_ID = B.APP_ID)
WHERE TRUNC(REPORT_DATE) = TRUNC(SYSDATE);
/


select *
FROM RDM.RDM_EMAIL_OUTBOX@APXP01.PROP.SGPCORP.LOCAL 
--WHERE TRUNC(entry_date) > TRUNC(SYSDATE) -7
/

INSERT INTO APEX_WEEKLY_REPORT ( MODULE, LOADED,WORKING, COMPLETED,ACTIVE, APP_ID)
VALUES ( 'HOURS WORKED',328,0, 0,1, 10);

COMMIT;


SELECT SUM(A.RECORDCNT)
    FROM BOFA_FILES_PROCESSED a
    WHERE A.CLIENT IN ('BACFS')    
    AND trunc(entry_date) > trunc(sysdate) - 30;
/



---- loaded 
select count(*)
from RDM.sqa_td_data@APXP01.PROP.SGPCORP.LOCAL
where trunc(data_dt) > trunc(sysdate) - 7;

select NVL(SUM(A.NBR_WORKORDERS),0) AS completed
from rdm.sqa_vendor_list@APXP01.PROP.SGPCORP.LOCAL A
where TRUNC(LAST_REVIEW) > trunc(sysdate) - 7;


SELECT 'SQA TDA' AS MODULE, 
SUM(A.NBR_WORKORDERS) AS LOADED_CNT,
       SUM(CASE WHEN B.WORKING = 'Y' AND B.COMPLETED IS NULL THEN 1 ELSE 0 END) WORKING_CNT,
       SUM(CASE WHEN B.WORKING = 'Y' AND B.COMPLETED = 'Y'   THEN 1 ELSE 0 END)  COMPLETED_CNT,
       0 AS ACTIVE, 
       2 AS APP_ID
from rdm.sqa_vendor_list@APXP01.PROP.SGPCORP.LOCAL A  
left join ( select WORKING, COMPLETED, BATCH_NO from RDM.SQA_TD_DATA@APXP01.PROP.SGPCORP.LOCAL
                     ) b on (a.BATCH_NO = b.BATCH_NO)
/


edit SG_APEX_APPLICATIONS
/


SELECT TRUNC(SYSDATE) AS REPORT_DATE, 
 'Safeguard Access Tracker' AS APEX_APPLICATION,
       COUNT(RECORD_ID) AS EMPLOYEES_ADDED, 
       sum(CASE 
            WHEN EMPLOYEE_ACTIVATION_DT IS NOT NULL AND NVL(EMPLOYEE_DEACTIVATION_DT, SYSDATE + 10) > TRUNC(SYSDATE) AND NVL(EMPLOYEE_TERM_DT, SYSDATE + 10) > TRUNC(SYSDATE) THEN 
                1 
            ELSE 
                0 
            END) AS ACTIVE_EMPLOYEES,
       sum(CASE 
            WHEN EMPLOYEE_DEACTIVATION_DT IS NOT NULL AND NVL(EMPLOYEE_TERM_DT, SYSDATE + 10) > TRUNC(SYSDATE) THEN 
                1 
            ELSE 
                0 
            END) AS DEACTIVATED_EMPLOYEES,
       sum(CASE 
            WHEN EMPLOYEE_TERM_DT IS NOT NULL THEN 
                1 
            ELSE 
                0 
            END) AS TERMINATED_EMPLOYEES,
            9 AS APP_ID 
FROM RDM.SAT_EMPLOYEES@APXP01.PROP.SGPCORP.LOCAL
WHERE TRUNC(DATA_DT) > TRUNC(SYSDATE)-7;
/
select
 TO_CHAR(( REPORT_DATE -7),'mm/dd/yy')||' to '||to_char(REPORT_DATE,'mm/dd/yy') period,
     APEX_APPLICATION,
     EMPLOYEES_ADDED,
     ACTIVE_EMPLOYEES,
     DEACTIVATED_EMPLOYEES,
     TERMINATED_EMPLOYEES
from APEX_APPLICATION_USAGE
--WHERE TRUNC(REPORT_DATE) = TRUNC(SYSDATE);

----




