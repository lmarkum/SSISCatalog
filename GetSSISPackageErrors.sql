/*
Created by Kevin Hill, Dallas DBAs LLC, 12/28/2018
Inspired by work from Jules Behrens
Index tested by Peter Schott

This queries multiple SSISDB tables to return a clear path from Top to bottom 
related to errors in an Integration Services Catalog based SSIS package.

It has not yet been tied back to job execution, nor is it set to email info out.

Use this as a backup to your normal job failure checks to tie it all together
instead of spending a full cup of coffee clicking and drilling into the cumbersome 
All Executions report.

Free to use and modify, please leave this header as a courtesy.

https://dallasdbas.com/integration-services-catalog-package-errors/

*/
USE SSISDB;


GO
SELECT DISTINCT fold.[name] AS Folder_name,
                proj.[name] AS Project_Name,
                pack.[name] AS Package_Name,
                ops.[message_time],
                mess.[message_source_name],
                ops.[message]
FROM   --,mess.[execution_path]        -- this is pretty long path if you are pasting into an email or Excel
       [internal].[projects] AS proj
       INNER JOIN
       [internal].[packages] AS pack
       ON proj.project_id = pack.project_id
       INNER JOIN
       [internal].[folders] AS fold
       ON fold.folder_id = proj.folder_id
       INNER JOIN
       [internal].[executions] AS execs
       ON execs.folder_name = fold.[name]
          AND execs.project_name = proj.[name]
          AND execs.package_name = pack.[name]
       INNER JOIN
       [internal].[operation_messages] AS ops
       ON execs.execution_id = ops.operation_id
       INNER JOIN
       [internal].[event_messages] AS mess
       ON ops.[operation_id] = mess.[operation_id]
          AND mess.event_message_id = ops.operation_message_id
          AND mess.package_name = pack.[name]
WHERE  1 = 1
       AND ops.message_type = 120 -- errors only
       AND --and mess.message_type in (120,130)  -- errors and warnings
       ops.message_time > getdate() - 1; -- adjust as necessary


/*
If you have a very large SSISDB due to activity or long retention, please consider this index:
CREATE NONCLUSTERED INDEX [NC_OpsID_MessageType_MessgeTime] ON [internal].[operation_messages]
(
    [operation_id] ASC,
    [message_time] ASC,
    [message_type] ASC
)
INCLUDE ([message])
*/
