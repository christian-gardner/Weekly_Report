create or replace procedure WEEKLY_SQA_REPORT
is


cursor c1
is
select to_char((REPORT_DATE - 7),'mm/dd/yy')||' to '||to_char(REPORT_DATE,'mm/dd/yy')  period, MODULE, LOADED,WORKING, COMPLETED
from SQA_WEEKLY_REPORT
order by  Module, report_date desc;

R1   C1%rowtype;



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

     PROC      :=  'WEEKLY_SQA_REPORT';
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
          Ebody_html := Ebody_html||' <h3>APEX IssueTrak Weekly Usage Report</h3> ';


          Ebody_html := Ebody_html||'<table id ="mytable", border="1">';
          Ebody_html := Ebody_html||'  <tr> ';
          Ebody_html := Ebody_html||'     <th>Period</th>';
          Ebody_html := Ebody_html||'     <th>Module</th>';
          Ebody_html := Ebody_html||'     <th>Loaded</th>';
          Ebody_html := Ebody_html||'     <th>Working</th>';
          Ebody_html := Ebody_html||'     <th>Completed</th>';
          Ebody_html := Ebody_html||'  </tr>';

open c1;
      LOOP
        FETCH C1 INTO R1;
        EXIT WHEN C1%NOTFOUND;
        Ebody_html := Ebody_html||'<tr> ';
            Ebody_html := Ebody_html||'<td class="left">'||R1.period||'</td>';        
            Ebody_html := Ebody_html||'<td class="left">'||R1.Module||'</td>';
            Ebody_html := Ebody_html||'<td class="right">'||to_char(R1.LOADED,'9,999,999')||'</td>';
            Ebody_html := Ebody_html||'<td class="right">'||to_char(R1.WORKING,'9,999,999')||'</td>';
            Ebody_html := Ebody_html||'<td class="right">'||TO_CHAR(R1.COMPLETED,'9,999,999')||'</td>';
        Ebody_html := Ebody_html||'</tr>'||utl_tcp.crlf;
      END LOOP;
close c1;

         Ebody_html := Ebody_html ||'</table> ';
         Ebody_html := Ebody_html||'<br /><br /><br />';
         Ebody_html := Ebody_html ||'  Sincerely,<br />';
         Ebody_html := Ebody_html ||'  <span class="sig">APEX Reporting</span><br />';
         Ebody_html := Ebody_html||'</body>';
         Ebody_html := Ebody_html||'<br />';
         Ebody_html := Ebody_html||'<p> Date/Time: '||TO_CHAR(SYSDATE,'DD MONTH YYYY HH24:MI:SS')||'</p>'||utl_tcp.crlf;



    SQL_STMT := 'INSERT INTO RDM.RDM_EMAIL_OUTBOX@APXP01.PROP.SGPCORP.LOCAL ( TEAM, APP, SUBJECT, EBODY, EBODY_HTML)';
    SQL_STMT := SQL_STMT||' VALUES ( :1, :2, :3, :4, :5) ' ;

    EXECUTE IMMEDIATE SQL_STMT USING  'SYS Cancel','Weekly SQA Report','APEX IssueTrak Weekly Usage Report' ,Ebody,Ebody_html;
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

