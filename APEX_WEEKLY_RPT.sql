create or replace procedure APEX_WEEKLY_RPT
IS


  SQLCOUNTS      number;
  Rcode          number;
  
  nbr_COMPLETED  NUMBER;
  nbr_WORKING    NUMBER;
  nbr_LOADED     NUMBER;
  nbr_REJECTIONS NUMBER;
  nbr_VARIANCE   NUMBER;
  
  SQL_STMT   VARCHAR2(32000);
  MSG        VARCHAR2(1000);
  PROC       VARCHAR2(1000);
  SubProc    VARCHAR2(1000);

  BAD_DATA       EXCEPTION;


BEGIN

     PROC      :=  'APEX_WEEKLY_RPT';
     MSG       :=  'Process Starting...';
     sqlcounts :=  0;

      INSERT INTO BOA_PROCESS_LOG
      (
        PROCESS,
        SUB_PROCESS,
        ENTRYDTE,
        ROWCOUNTS,
        MESSAGE
      )
      VALUES ( proc,'Collect data process',SYSDATE, sqlcounts, MSG);

      COMMIT;

DELETE APEX_WEEKLY_REPORT WHERE TRUNC(REPORT_DATE)  = TRUNC(SYSDATE);

COMMIT;

INSERT INTO APEX_WEEKLY_REPORT ( MODULE, LOADED,WORKING, COMPLETED,ACTIVE, APP_ID)
SELECT 'SQA ICC' AS MODULE,
       COUNT(A.LOANNUMBER) AS LOADED_CNT, 
       SUM(CASE WHEN A.COMPLETED = 0  then 1 ELSE 0 END) AS WORKING_CNT,
       SUM(CASE WHEN b.pid is not null then 1 ELSE 0 END) AS COMPLETED_CNT,
       1 AS ACTIVE, 
       1 AS APP_ID 
from RDM.SQA_ICC_BACKLOG@APXP01.PROP.SGPCORP.LOCAL A
left join ( select * from RDM.SQA_ICC_PRIOR_LOAN_HISTORY@APXP01.PROP.SGPCORP.LOCAL
                     ) b on (a.pid = b.pid)
where TRUNC(a.DATE_UPLOADED) > TRUNC(SYSDATE) - 7
UNION ALL
SELECT 'SQA QC' AS MODULE, 
        COUNT(LOAN_NUMBER) AS LOAD_CNT,
        NVL(SUM(CASE WHEN A.WORKING > 0  then 1 ELSE 0 END),0) AS WORKING_CNT,
        NVL(SUM(CASE WHEN A.COMPLETED IS NOT NULL THEN 1 ELSE 0 END),0) COMPLETE_CNT,
        1 AS ACTIVE, 
        3 AS APP_ID
        FROM RDM.SQA_QC_DETAILS@APXP01.PROP.SGPCORP.LOCAL A
WHERE TRUNC(START_DATE) > TRUNC(SYSDATE) - 7     
UNION ALL
SELECT 'BILLED AT LOSS',
       count(work_order) LOADED_CNT,
       sum(CASE WHEN STATUS NOT IN ('Completed' ) AND PROCESSOR IS NOT NULL THEN 1 ELSE 0 END ) WORKING_CNT, 
       sum(CASE WHEN STATUS IN ('Completed' ) THEN 1 ELSE 0 END) COMPLETED_CNT,
       1 AS ACTIVE,
       8 AS APP_ID
 from rdm.bal_data@APXP01.PROP.SGPCORP.LOCAL 
 WHERE  TRUNC(file_upload_dt) > TRUNC(SYSDATE) - 7 
UNION ALL 
SELECT 'CHL CANCEL' AS MODULE,
       SUM(A.ROWCOUNTS) AS LOADED_CNT, 
       SUM(CASE WHEN A.PROCESS_DATE IS NULL  then A.ROWCOUNTS ELSE 0 END) AS WORKING_CNT,
       SUM(CASE WHEN A.PROCESS_DATE IS NOT NULL then A.ROWCOUNTS ELSE 0 END) AS COMPLETED_CNT,
       1 AS ACTIVE,
       6 AS APP_ID
from RDM.XCL_PROCESS_LOG@APXP01.PROP.SGPCORP.LOCAL A
where TRUNC(a.ENTRY_DATE) > TRUNC(SYSDATE) - 7;

COMMIT;

/*****************************************
   BOA INVOICE RECON
 ***************************************/


SELECT   SUM(A.RECORDCNT)
    INTO NBR_LOADED
    FROM BOFA_FILES_PROCESSED a
where trunc(entry_date) > trunc(sysdate) - 7
AND CLIENT IN ('CHL','BANA')
AND A.FILE_NAME NOT LIKE 'DuplicateOrderCheckSGP_%';

SELECT COUNT(*) 
    INTO NBR_REJECTIONS   
    FROM BOFA_FILES_PROCESSED a
    LEFT JOIN ( SELECT SOURCE_FILE FROM RDM.BOA_SUMMARY@APXP01.PROP.SGPCORP.LOCAL ) C ON ( C.SOURCE_FILE = A.FILE_NAME) 
WHERE A.CLIENT IN ('BANA','CHL')
AND C.SOURCE_FILE IS NOT NULL;

SELECT COUNT(*)
INTO NBR_VARIANCE 
FROM RDM.BOA_FEE_VARIANCE@APXP01.PROP.SGPCORP.LOCAL;

NBR_WORKING := NBR_REJECTIONS + NBR_VARIANCE;

 
SELECT  COUNT(*)     
    INTO NBR_COMPLETED
    FROM BOFA_FILES_PROCESSED a
    LEFT JOIN ( SELECT SOURCE_FILE FROM RDM.BOA_SUMMARY_GOOD@APXP01.PROP.SGPCORP.LOCAL ) C ON ( C.SOURCE_FILE = A.FILE_NAME) 
WHERE A.CLIENT IN ('BANA','CHL')
AND  trunc(entry_date) > trunc(sysdate) - 7
AND C.SOURCE_FILE IS NOT NULL;
  
INSERT INTO APEX_WEEKLY_REPORT ( MODULE, LOADED,WORKING, COMPLETED, ACTIVE, APP_ID)
VALUES ( 'BOA INV RECON',nbr_LOADED,nbr_WORKING, nbr_COMPLETED, 1, 7);

COMMIT;

/*****************************************
   SQA REOINT
 ***************************************/


select count(*)
 INTO nbr_LOADED    
FROM RDM.SQA_REOINT_DATA@APXP01.PROP.SGPCORP.LOCAL A 
where trunc(file_upload_dt) > trunc(sysdate) - 7;


select COUNT(*)
INTO nbr_COMPLETED 
FROM RDM.SQA_REOINT_DATA@APXP01.PROP.SGPCORP.LOCAL A 
where trunc(last_update_dt) > trunc(sysdate) - 7;


INSERT INTO APEX_WEEKLY_REPORT ( MODULE, LOADED,WORKING, COMPLETED,ACTIVE,APP_ID)
VALUES ( 'SQA REOINT',nbr_LOADED,0, nbr_COMPLETED,1, 4);

COMMIT;

/*****************************************
   VENDOR DISPUTE
 ***************************************/


select COUNT(*)
INTO nbr_loaded
from rdm.CORP_VENDOR_DISPUTE_DETAILS@APXP01.PROP.SGPCORP.LOCAL
WHERE TRUNC(LOAD_DT) > TRUNC(SYSDATE) - 7;

select  COUNT(*)
  into nbr_WORKING
  from RDM.CORP_VENDOR_DISPUTES@APXP01.PROP.SGPCORP.LOCAL
WHERE TRUNC(DATEOFSGRESPONSE) > TRUNC(SYSDATE) -7
and SGRESPONSE IN ('Pending','Payment Inquiry');

select  COUNT(*)
  into nbr_COMPLETED
  from RDM.CORP_VENDOR_DISPUTES@APXP01.PROP.SGPCORP.LOCAL
WHERE TRUNC(DATEOFSGRESPONSE) > TRUNC(SYSDATE) -7
and SGRESPONSE NOT IN ('Pending','Payment Inquiry');


INSERT INTO APEX_WEEKLY_REPORT ( MODULE, LOADED,WORKING, COMPLETED,ACTIVE, APP_ID)
VALUES ( 'VENDOR DISPUTE',nbr_LOADED,nbr_WORKING, nbr_COMPLETED,1, 5);

COMMIT;

/*****************************************
   HOURS WORKED
 ***************************************/

SELECT COUNT(*)
INTO nbr_loaded
FROM RDM.HE_DATA@APXP01.PROP.SGPCORP.LOCAL 
WHERE TRUNC(DATE_WORKED) > TRUNC(SYSDATE) -7;

INSERT INTO APEX_WEEKLY_REPORT ( MODULE, LOADED,WORKING, COMPLETED,ACTIVE, APP_ID)
VALUES ( 'HOURS WORKED',nbr_LOADED,0, nbr_LOADED,1, 10);

COMMIT;

/*****************************************
   SQA TDA
 ***************************************/

select count(*)
into NBR_LOADED
from RDM.sqa_td_data@APXP01.PROP.SGPCORP.LOCAL
where trunc(data_dt) > trunc(sysdate) - 7;

select COUNT(*)
into NBR_WORKING
from RDM.SQA_TD_DATA@APXP01.PROP.SGPCORP.LOCAL A
LEFT JOIN ( SELECT  HISTORY_ID, CALC_CMPT 
               FROM  RDM.SQA_VENDOR_HISTORY@APXP01.PROP.SGPCORP.LOCAL 
              WHERE trunc(review_dte) > trunc(sysdate) - 7 
                AND calc_cmpt = 0 ) B ON ( A.REVIEW_ID = B.HISTORY_ID)
WHERE  A.REVIEW_ID = B.HISTORY_ID                
AND A.WORKING = 'Y'
AND A.COMPLETED IS NULL; 

select nvl(sum(nbr_reviewed),0) 
into nbr_COMPLETED 
from RDM.SQA_VENDOR_HISTORY@APXP01.PROP.SGPCORP.LOCAL 
where calc_cmpt = 1 
and trunc(review_dte) > trunc(sysdate) - 7;

INSERT INTO APEX_WEEKLY_REPORT ( MODULE, LOADED,WORKING, COMPLETED,ACTIVE, APP_ID)
VALUES ( 'SQA TD',nbr_LOADED,NBR_WORKING, nbr_COMPLETED,0, 2);

COMMIT;

------- 

-------

DELETE APEX_APPLICATION_USAGE WHERE TRUNC(REPORT_DATE)  = TRUNC(SYSDATE);

COMMIT;

insert INTO APEX_APPLICATION_USAGE ( REPORT_DATE, APEX_APPLICATION, EMPLOYEES_ADDED, ACTIVE_EMPLOYEES, DEACTIVATED_EMPLOYEES, TERMINATED_EMPLOYEES, APP_ID)
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

COMMIT;


sqlcounts :=SQL%ROWCOUNT;

     MSG       :=  'Process complete...';
     sqlcounts :=  0;

      INSERT INTO BOA_PROCESS_LOG
      (
        PROCESS,
        SUB_PROCESS,
        ENTRYDTE,
        ROWCOUNTS,
        MESSAGE
      )
      VALUES ( proc,'Collect data process',SYSDATE, sqlcounts, MSG);

      COMMIT;

EXCEPTION 
     WHEN OTHERS THEN 
     MSG       := SQLERRM;
     SQLCOUNTS := SQLCODE;

      INSERT INTO BOA_PROCESS_LOG
      (
        PROCESS,
        SUB_PROCESS,
        ENTRYDTE,
        ROWCOUNTS,
        MESSAGE
      )
      VALUES ( proc,'Collect data process',SYSDATE, sqlcounts, MSG);

      COMMIT;


END;
/

SHOW ERRORS;
