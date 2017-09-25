SET DEFINE OFF;
Prompt Scheduler Job APEX_WEEKLY_RPT_JOB;
BEGIN
  SYS.DBMS_SCHEDULER.CREATE_JOB
    (
       job_name        => 'APEX_WEEKLY_RPT_JOB'
      ,start_date      => TO_TIMESTAMP_TZ('2017/07/21 11:00:00.000000 -04:00','yyyy/mm/dd hh24:mi:ss.ff tzr')
      ,repeat_interval => 'FREQ=WEEKLY;BYDAY=FRI;BYHOUR=18'
      ,end_date        => NULL
      ,job_class       => 'DEFAULT_JOB_CLASS'
      ,job_type        => 'STORED_PROCEDURE'
      ,job_action      => 'WEEKLY_APEX_REPORT'
      ,comments        => 'PROCESS RESULTS FILES'
    );
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'APEX_WEEKLY_RPT_JOB'
     ,attribute => 'RESTARTABLE'
     ,value     => FALSE);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'APEX_WEEKLY_RPT_JOB'
     ,attribute => 'LOGGING_LEVEL'
     ,value     => SYS.DBMS_SCHEDULER.LOGGING_FULL);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'APEX_WEEKLY_RPT_JOB'
     ,attribute => 'MAX_FAILURES');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'APEX_WEEKLY_RPT_JOB'
     ,attribute => 'MAX_RUNS');
  BEGIN
    SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
      ( name      => 'APEX_WEEKLY_RPT_JOB'
       ,attribute => 'STOP_ON_WINDOW_CLOSE'
       ,value     => FALSE);
  EXCEPTION
    -- could fail if program is of type EXECUTABLE...
    WHEN OTHERS THEN
      NULL;
  END;
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'APEX_WEEKLY_RPT_JOB'
     ,attribute => 'JOB_PRIORITY'
     ,value     => 3);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'APEX_WEEKLY_RPT_JOB'
     ,attribute => 'SCHEDULE_LIMIT');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'APEX_WEEKLY_RPT_JOB'
     ,attribute => 'AUTO_DROP'
     ,value     => TRUE);

  SYS.DBMS_SCHEDULER.ENABLE
    (name                  => 'APEX_WEEKLY_RPT_JOB');
END;
/
