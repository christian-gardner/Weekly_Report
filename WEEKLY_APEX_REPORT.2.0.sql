CREATE OR REPLACE procedure IPP$LIBRARIAN.WEEKLY_APEX_REPORT
is


cursor c1
is
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

R1   C1%rowtype;

CURSOR C2
IS
SELECT APP_ID,
 TO_CHAR(( REPORT_DATE -7),'mm/dd/yy')||' to '||to_char(REPORT_DATE,'mm/dd/yy') period,
     APEX_APPLICATION,
     EMPLOYEES_ADDED,
     ACTIVE_EMPLOYEES,
     DEACTIVATED_EMPLOYEES,
     TERMINATED_EMPLOYEES
from APEX_APPLICATION_USAGE
WHERE TRUNC(REPORT_DATE) = TRUNC(SYSDATE);

R2  C2%rowtype;


  SQLCOUNTS  number;
  email_id   number;
  Rcode      number;
  SQL_STMT   VARCHAR2(32000);
  MSG        VARCHAR2(1000);
  PROC       VARCHAR2(1000);
  SubProc    VARCHAR2(1000);


   workspace_id   NUMBER;
   WORKSPACENAME  varchar2(100);
   Ebody          VARCHAR2(32000);
   Ebody_html     VARCHAR2(32000);
   Eto            VARCHAR2(1000);
   Efrom          VARCHAR2(1000);
   Ecc            VARCHAR2(1000);
   CREATE_N       NUMBER;
   CATEGORY_N     NUMBER;
   COMMENT_N      NUMBER;
   BAD_DATA       EXCEPTION;

   ------ version # 5 move to apexd1

BEGIN

     PROC      :=  'WEEKLY_APEX_REPORT';
     MSG       :=  'Process Starting...';
     sqlcounts :=  0;


        Ebody := 'To view the content of this message, please use an HTML enabled mail client.';


          Ebody_html := '<html>';
          Ebody_html := Ebody_html||'<head>';
          Ebody_html := Ebody_html||'<style type="text/css"> ';
          Ebody_html := Ebody_html||'#mytable .left {text-align:left;} ';
          Ebody_html := Ebody_html||'#mytable .right {text-align:right;}';

          Ebody_html := Ebody_html||'body{font-family: Arial, Helvetica, sans-serif;';
          Ebody_html := Ebody_html||'font-size:10pt;';
          Ebody_html := Ebody_html||'margin:30px;';
          Ebody_html := Ebody_html||'background-color:#ffffff;} ';
          Ebody_html := Ebody_html||' ';
          Ebody_html := Ebody_html||'span.sig{font-style:italic; ';
          Ebody_html := Ebody_html||'   font-weight:bold; ';
          Ebody_html := Ebody_html||'   color:#811919;} ';
          Ebody_html := Ebody_html||'</style>';
          Ebody_html := Ebody_html||'</head> ';
          Ebody_html := Ebody_html||'</html>'||utl_tcp.crlf;


          Ebody_html := Ebody_html||'<body>';
          Ebody_html := Ebody_html||'<p> ';
          Ebody_html := Ebody_html||' <h3>APEX Weekly Data Process Report</h3> ';
          Ebody_html := Ebody_html||'<table id ="mytable", border="1">';
          Ebody_html := Ebody_html||'  <tr> ';
          Ebody_html := Ebody_html||'     <th>Time period of report</th>';
          Ebody_html := Ebody_html||'     <th>APEX Application name </th>';
          Ebody_html := Ebody_html||'     <th>Application expected input </th>';
          Ebody_html := Ebody_html||'     <th>Application expected completed</th>';
          Ebody_html := Ebody_html||'     <th>Application expected number of users</th>';
          Ebody_html := Ebody_html||'     <th>Number of records loaded <br> by the application</th>';
          Ebody_html := Ebody_html||'     <th>Number of records <br> being processed</th>';
          Ebody_html := Ebody_html||'     <th>Number of records <br> processed</th>';
          Ebody_html := Ebody_html||'  </tr>';

open c1;
      LOOP
        FETCH C1 INTO R1;
        EXIT WHEN C1%NOTFOUND;
        Ebody_html := Ebody_html||'<tr> ';
            Ebody_html := Ebody_html||'<td class="left">'||R1.period||'</td>';
            Ebody_html := Ebody_html||'<td class="left">'||R1.Module||'</td>';
            Ebody_html := Ebody_html||'<td class="left">'||R1.APP_EXPECT_INPUT||'</td>';
            Ebody_html := Ebody_html||'<td class="left">'||R1.APP_EXPECT_COMPLETED||'</td>';
            Ebody_html := Ebody_html||'<td class="left">'||R1.APP_EXPECT_NBR_USERS||'</td>';

            Ebody_html := CASE WHEN R1.ACTIVE = 1 THEN Ebody_html||'<td class="right">'||to_char(R1.LOADED,'9,999,999')||'</td>' ELSE Ebody_html||'<td class="right">'||'N/A'||'</td>' END;

            Ebody_html := CASE WHEN R1.ACTIVE = 1 and R1.APP_ID NOT IN (10) THEN Ebody_html||'<td class="right">'||to_char(R1.WORKING,'9,999,999')||'</td>' ELSE Ebody_html||'<td class="right">'||'N/A'||'</td>' END;
            Ebody_html := CASE WHEN R1.ACTIVE = 1 THEN Ebody_html||'<td class="right">'||TO_CHAR(R1.COMPLETED,'9,999,999')||'</td>' ELSE Ebody_html||'<td class="right">'||'N/A'||'</td>' END;
        Ebody_html := Ebody_html||'</tr>'||utl_tcp.crlf;
      END LOOP;
close c1;

         Ebody_html := Ebody_html ||'</table> ';
         Ebody_html := Ebody_html ||'</p> ';
         Ebody_html := Ebody_html||'<br/><br/><br/><br/>';


          Ebody_html := Ebody_html ||'<p> ';
          Ebody_html := Ebody_html||' <h3>APEX Weekly End User Report</h3> ';


          Ebody_html := Ebody_html||'<table id ="mytable", border="1">';
          Ebody_html := Ebody_html||'  <tr> ';
          Ebody_html := Ebody_html||'     <th>Time period of report</th>';
          Ebody_html := Ebody_html||'     <th>APEX Application name </th>';
          Ebody_html := Ebody_html||'     <th>Number of<br>Employees added</th>';
          Ebody_html := Ebody_html||'     <th>Number of<br>Active Employees</th>';
          Ebody_html := Ebody_html||'     <th>Number of<br>Inactive Employees</th>';
          Ebody_html := Ebody_html||'     <th>Number of<br>Terminated Employees</th>';
          Ebody_html := Ebody_html||'  </tr>';

open c2;
      LOOP
        FETCH C2 INTO R2;
        EXIT WHEN C2%NOTFOUND;
        Ebody_html := Ebody_html||'<tr> ';
            Ebody_html := Ebody_html||'<td class="left">'||R2.period||'</td>';
            Ebody_html := Ebody_html||'<td class="left">'||R2.APEX_APPLICATION||'</td>';
            Ebody_html := Ebody_html||'<td class="right">'||to_char(R2.EMPLOYEES_ADDED,'9,999,999')||'</td>';
            Ebody_html := Ebody_html||'<td class="right">'||to_char(R2.ACTIVE_EMPLOYEES,'9,999,999')||'</td>';
            Ebody_html := Ebody_html||'<td class="right">'||TO_CHAR(R2.DEACTIVATED_EMPLOYEES,'9,999,999')||'</td>';
            Ebody_html := Ebody_html||'<td class="right">'||TO_CHAR(R2.TERMINATED_EMPLOYEES,'9,999,999')||'</td>';
          Ebody_html := Ebody_html||'</tr>'||utl_tcp.crlf;
      END LOOP;
close c2;

         Ebody_html := Ebody_html ||'</table> ';

         Ebody_html := Ebody_html ||'</p> ';






         Ebody_html := Ebody_html||'<br /><br /><br />';
         Ebody_html := Ebody_html ||'  Sincerely,<br />';
         Ebody_html := Ebody_html ||'  <span class="sig">APEX Reporting</span><br />';
         Ebody_html := Ebody_html||'</body>';
         Ebody_html := Ebody_html||'<br />';
         Ebody_html := Ebody_html||'<p> Date/Time: '||TO_CHAR(SYSDATE,'DD MONTH YYYY HH24:MI:SS')||'</p>'||utl_tcp.crlf;



    SQL_STMT := 'INSERT INTO RDM.RDM_EMAIL_OUTBOX@APXP01.PROP.SGPCORP.LOCAL ( TEAM, APP, SUBJECT, EBODY, EBODY_HTML)';
    SQL_STMT := SQL_STMT||' VALUES ( :1, :2, :3, :4, :5) ' ;

    EXECUTE IMMEDIATE SQL_STMT USING  'APEX','Weekly APEX Report','APEX IssueTrak Weekly Usage Report' ,Ebody,Ebody_html;
    commit;




      INSERT INTO BOA_PROCESS_LOG
      (
        PROCESS,
        SUB_PROCESS,
        ENTRYDTE,
        ROWCOUNTS,
        MESSAGE
      )
      VALUES ( proc,'Email process',SYSDATE, sqlcounts, MSG);

      COMMIT;




/*
           INSERT INTO SHOW_STMT VALUES (Ebody_html);
           commit;
*/


exception
    WHEN BAD_DATA THEN

      INSERT INTO BOA_PROCESS_LOG
      (
        PROCESS,
        SUB_PROCESS,
        ENTRYDTE,
        ROWCOUNTS,
        MESSAGE
      )
      VALUES ( proc,SubProc, SYSDATE, rcode, MSG);

      COMMIT;

    when others then
    msg   := sqlerrm;
    rcode := sqlcode;

      INSERT INTO BOA_PROCESS_LOG
      (
        PROCESS,
        SUB_PROCESS,
        ENTRYDTE,
        ROWCOUNTS,
        MESSAGE
      )
      VALUES ( proc,SubProc, SYSDATE, rcode, MSG);

      COMMIT;


END;
/