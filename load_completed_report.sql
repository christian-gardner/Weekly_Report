SELECT 'SQA_ICC' AS MODULE,
       COUNT(A.LOANNUMBER) AS LOADED_CNT, 
       SUM(CASE WHEN A.COMPLETED = 0  then 1 ELSE 0 END) AS WORKING_CNT,
       SUM(CASE WHEN b.pid is not null then 1 ELSE 0 END) AS COMPLETED_CNT
from RDM.SQA_ICC_BACKLOG@APXP01.PROP.SGPCORP.LOCAL A
left join ( select * from RDM.SQA_ICC_PRIOR_LOAN_HISTORY@APXP01.PROP.SGPCORP.LOCAL
                     ) b on (a.pid = b.pid)
where TRUNC(a.DATE_UPLOADED) > TRUNC(SYSDATE) - 7
UNION
SELECT 'SQA_TDA' AS MODULE, 
SUM(A.NBR_WORKORDERS) AS LOADED_CNT,
       SUM(CASE WHEN B.WORKING = 'Y' AND B.COMPLETED IS NULL THEN 1 ELSE 0 END) WORKING_CNT,
       SUM(CASE WHEN B.WORKING = 'Y' AND B.COMPLETED = 'Y' THEN 1 ELSE 0 END)  COMPLETED_CNT
from rdm.sqa_vendor_list@APXP01.PROP.SGPCORP.LOCAL A  
left join ( select * from RDM.SQA_TD_DATA@APXP01.PROP.SGPCORP.LOCAL
                     ) b on (a.BATCH_NO = b.BATCH_NO)
/




select vENDOR_ID, VENDOR_CODE, FOLLOW_UP, FOLLOW_UP_SAT, FOLLOW_UP_DTE, STANDING, NBR_WORKORDERS, ACTIVE, LAST_REVIEW, REVIEWED_BY, SEGMENTS, CAP_HOLD, BATCH_NO, WORKCODE, ASSIGNED_TO, COMPLETED_BY, START_COUNTER_DATE, FOLLOW_UP_CAT, THIRTY_FIFTY_DAY_RULE, ASSIGN_IT, FOLLOW_UP_RES, NBR_COMPLETED, NEXT_REVIEW
from rdm.sqa_vendor_list@APXP01.PROP.SGPCORP.LOCAL A
/


SELECT 'SQA_TDA' AS MODULE, 
SUM(A.NBR_WORKORDERS) AS LOADED_CNT,
       SUM(CASE WHEN B.WORKING = 'Y' AND B.COMPLETED IS NULL THEN 1 ELSE 0 END) WORKING_CNT,
       SUM(CASE WHEN B.WORKING = 'Y' AND B.COMPLETED = 'Y' THEN 1 ELSE 0 END)  COMPLETED_CNT,
       SUM(CASE WHEN A.FOLLOW_UP_RES IN ('Pass') then 1 else 0 end) Passed_cnt,
       SUM(CASE WHEN A.FOLLOW_UP_RES not IN ('Pass') then 1 else 0 end) Failed_cnt       
from rdm.sqa_vendor_list@APXP01.PROP.SGPCORP.LOCAL A  
left join ( select * from RDM.SQA_TD_DATA@APXP01.PROP.SGPCORP.LOCAL
                     ) b on (a.BATCH_NO = b.BATCH_NO)
/



select  a.FOLLOW_UP_RES, a.LAST_REVIEW, a.REVIEWED_BY, 
  case when p.LOGIN IS NULL then 'Not Assigned' ELSE P.LOGIN  end  as assigned_to , 
  a.SEGMENTS AS AUDIT_TYPE,
  a.VENDOR_CODE, 
  case when p.LOGIN is not null and  b.current_status is null then 'Not started' else b.current_status end current_status
from rdm.sqa_vendor_list@APXP01.PROP.SGPCORP.LOCAL A
left join ( select pid, login from RDM.SQA_TD_QUEUE_PROCESSORS@APXP01.PROP.SGPCORP.LOCAL  ) p on ( p.pid = a.assigned_to )
left join (
SELECT sqa_td_rep,  CONTRACTOR, REPORT_SEGMENT, working, completed, review_status, CASE WHEN REVIEW_STATUS IN (1) THEN 'Review Not Complete' 
                                                                                        when review_status in (2) then 'Review completed'
                                                                                        end current_status
   FROM ( 
   SELECT sqa_td_rep,  CONTRACTOR, REPORT_SEGMENT, REVIEW_STATUS, working, completed, RANK() OVER ( PARTITION BY sqa_td_rep,  CONTRACTOR, REPORT_SEGMENT ORDER BY REVIEW_STATUS, ROWNUM) RK   
   FROM( 
   select  sqa_td_rep,  CONTRACTOR, REPORT_SEGMENT,working, COMPLETED, CASE WHEN WORKING = 'Y' AND SAVED IS NULL THEN 1
                                                                            WHEN WORKING = 'Y' AND SAVED = 'Y'   THEN 2 
                                                                            END AS REVIEW_STATUS              
            from rdm.sqa_td_data@APXP01.PROP.SGPCORP.LOCAL A  
            where working is not null) )
            where rk = 1 ) b                    
            on   ( B.REPORT_SEGMENT = a.segments and b.contractor = a.vendor_code)        
where a.active = 1             
and   p.LOGIN IS NOT NULL


/


select * from RDM.SQA_VENDOR_HISTORY@APXP01.PROP.SGPCORP.LOCAL A 