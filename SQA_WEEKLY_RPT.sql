create or replace procedure SQA_WEEKLY_RPT
IS


  SQLCOUNTS  number;
  Rcode      number;
  SQL_STMT   VARCHAR2(32000);
  MSG        VARCHAR2(1000);
  PROC       VARCHAR2(1000);
  SubProc    VARCHAR2(1000);

   BAD_DATA       EXCEPTION;


BEGIN

     PROC      :=  'WEEKLY_SQA_RPT';
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

DELETE SQA_WEEKLY_REPORT WHERE TRUNC(REPORT_DATE)  = TRUNC(SYSDATE);

COMMIT;


INSERT INTO SQA_WEEKLY_REPORT ( MODULE, LOADED,WORKING, COMPLETED)
SELECT 'SQA_ICC' AS MODULE,
       COUNT(A.LOANNUMBER) AS LOADED_CNT, 
       SUM(CASE WHEN A.COMPLETED = 0  then 1 ELSE 0 END) AS WORKING_CNT,
       SUM(CASE WHEN b.pid is not null then 1 ELSE 0 END) AS COMPLETED_CNT
from RDM.SQA_ICC_BACKLOG@APXP01.PROP.SGPCORP.LOCAL A
left join ( select * from RDM.SQA_ICC_PRIOR_LOAN_HISTORY@APXP01.PROP.SGPCORP.LOCAL
                     ) b on (a.pid = b.pid)
where TRUNC(a.DATE_UPLOADED) > TRUNC(SYSDATE) - 7
UNION ALL
SELECT 'SQA_TDA' AS MODULE, 
SUM(A.NBR_WORKORDERS) AS LOADED_CNT,
       SUM(CASE WHEN B.WORKING = 'Y' AND B.COMPLETED IS NULL THEN 1 ELSE 0 END) WORKING_CNT,
       SUM(CASE WHEN B.WORKING = 'Y' AND B.COMPLETED = 'Y'   THEN 1 ELSE 0 END)  COMPLETED_CNT
from rdm.sqa_vendor_list@APXP01.PROP.SGPCORP.LOCAL A  
left join ( select WORKING, COMPLETED, BATCH_NO from RDM.SQA_TD_DATA@APXP01.PROP.SGPCORP.LOCAL
                     ) b on (a.BATCH_NO = b.BATCH_NO)
UNION ALL                    
SELECT 'SQA_QC' AS MODULE, 
        COUNT(LOAN_NUMBER) AS LOAD_CNT,
        NVL(SUM(CASE WHEN A.WORKING > 0  then 1 ELSE 0 END),0) AS WORKING_CNT,
        NVL(SUM(CASE WHEN A.COMPLETED IS NOT NULL THEN 1 ELSE 0 END),0) COMPLETE_CNT
        FROM RDM.SQA_QC_DETAILS@APXP01.PROP.SGPCORP.LOCAL A
WHERE TRUNC(START_DATE) > TRUNC(SYSDATE) - 7     
UNION ALL                 
SELECT 'SQA_REOINT' AS MODULE,
       COUNT(LOAN_NUM) AS LOADED_CNT, 
       SUM(CASE WHEN WORKING = 'Y' then 1 ELSE 0 END) AS WORKING_CNT,
       SUM(CASE WHEN COMPLETED = 'Y' then 1 ELSE 0 END) AS COMPLETED_CNT
FROM RDM.SQA_REOINT_DATA@APXP01.PROP.SGPCORP.LOCAL A
WHERE TRUNC(FILE_UPLOAD_DT) > TRUNC(SYSDATE)-7;

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
