
IF exists(
select * from sys.objects where name = 'CKB_TMS_ALERT_TRIGGER' and type	=	'TR'
) 
begin 
drop trigger CKB_TMS_ALERT_TRIGGER
end 
go
create TRIGGER  CKB_TMS_ALERT_TRIGGER ON tms_pltph_trip_plan_hdr
FOR UPDATE 
AS
BEGIN
set nocount on 
DECLARE @trip_plan_id  nvarchar(200)
DECLARE @ou  int
DECLARE @status varchar(200)



SELECT @trip_plan_id = plpth_trip_plan_id FROM INSERTED I;
SELECT @ou  = plpth_ouinstance FROM INSERTED I;


DECLARE @CKB_TMS_ALERT_TBL TABLE 
(
OU                           int,
TRIP_PLAN                    varchar(200),
LOCATION_FROM                VARCHAR(200),
VEHICLE_NO                   VARCHAR(200),
PRIMARY_REF_DOC              VARCHAR(200),
CUSTOMER_NAME                VARCHAR(200),
ITEM_CODE                    VARCHAR(200),
ORDER_QTY                    UDD_QUANTITY,
ESTIMATED_DEPART_TIME        DATETIME,
ESTIMATED_ARRIVAL_TIME       DATETIME,
BOOKING_INFORMATION          VARCHAR(200),
STATUS VARCHAR(200),
WEIGHTT  UDD_QUANTITY 
)

INSERT INTO @CKB_TMS_ALERT_TBL

(

 OU                           
,TRIP_PLAN                    
,LOCATION_FROM                
,VEHICLE_NO                   
,PRIMARY_REF_DOC              
,CUSTOMER_NAME                
,ITEM_CODE                    
,ORDER_QTY                    
,ESTIMATED_DEPART_TIME        
,ESTIMATED_ARRIVAL_TIME       
,BOOKING_INFORMATION 
, STATUS        

)

SELECT 
        plpth_ouinstance
	   ,plpth_trip_plan_id
	   ,plpth_trip_plan_from
	   ,plpth_vehicle_id
	   ,null
	   ,null
	   ,null
	   ,null
	   ,plpth_trip_plan_date
	   ,plpth_trip_plan_end_date
	   ,null
	   ,plpth_trip_plan_status

FROM tms_pltph_trip_plan_hdr(NOLOCK)
 where	plpth_trip_plan_status			=	'RL'
	 and	plpth_trip_plan_id		=	@trip_plan_id
	 and	plpth_ouinstance		=	@ou

	 
	 select @status = STATUS
	 From @CKB_TMS_ALERT_TBL


 update tmp 
	 set	CUSTOMER_NAME		=	wms_customer_name
	 from   @CKB_TMS_ALERT_TBL tmp
	        ,tms_pltpd_trip_planning_details(nolock) a
			,tms_br_booking_request_hdr(nolock)b
			,wms_customer_hdr cus (nolock)
     where  tmp.TRIP_PLAN = a.plptd_trip_plan_id
	 and    tmp.ou = a.plptd_ouinstance
	 and  b.br_ouinstance=a.plptd_ouinstance
	 and b.br_request_Id=a.plptd_bk_req_id
	 and cus.wms_customer_ou=b.br_ouinstance
	 and cus.wms_customer_id=b.br_customer_id

UPDATE TMP
set PRIMARY_REF_DOC = ddh_dispatch_doc_no
From @CKB_TMS_ALERT_TBL tmp
     ,tms_pltpd_trip_planning_details(nolock) a
	 ,tms_br_booking_request_hdr(nolock)b
     ,tms_ddh_dispatch_document_hdr(nolock) c
	 where  tmp.TRIP_PLAN = a.plptd_trip_plan_id
	 and    tmp.ou = a.plptd_ouinstance
	 and  b.br_ouinstance=a.plptd_ouinstance
	 and b.br_request_Id=a.plptd_bk_req_id
	 and b.br_request_Id = c.ddh_reference_doc_no
	 and b.br_ouinstance=c.ddh_ouinstance

UPDATE TMP
SET ITEM_CODE = cd_thu_id
    ,ORDER_QTY = cd_thu_qty
	,WEIGHTT = cd_gross_weight

FROM @CKB_TMS_ALERT_TBL tmp
     ,tms_pltpd_trip_planning_details(nolock) a
	 ,tms_br_booking_request_hdr(nolock)b
     ,tms_brcd_consgt_details(nolock) c
	 where  tmp.TRIP_PLAN = a.plptd_trip_plan_id
	 and    tmp.ou = a.plptd_ouinstance
	 and  b.br_ouinstance=a.plptd_ouinstance
	 and b.br_request_Id=a.plptd_bk_req_id
	 and b.br_request_Id = c.cd_br_id
     and b.br_ouinstance=c.cd_ouinstance



UPDATE TMP
SET BOOKING_INFORMATION = CONCAT(TMP.ORDER_QTY,',',TMP.WEIGHTT)
FROM @CKB_TMS_ALERT_TBL TMP
    

        Declare	@sub			nvarchar(max)
		Declare	@sub1			nvarchar(max)
		Declare	@sub2			nvarchar(max)
		Declare	@sub3			nvarchar(max)
		Declare	@body			nvarchar(max)
		Declare	@body_dtl		nvarchar(max)
		Declare	@mail_body		nvarchar(max)
		Declare	@emailid		nvarchar(max)
		Declare	@body_footer	nvarchar(max)
		Declare @mail1          udd_email
		Declare @mail2          udd_email
		Declare @mail3          udd_email


select @mail1 =b.wms_emp_email
From @CKB_TMS_ALERT_TBL TMP
join wms_loc_location_hdr a (nolock)
on tmp.LOCATION_FROM = a.wms_loc_code
join wms_employee_hdr b
on a.wms_loc_code = b.wms_emp_default_location
where wms_emp_group = 'Manager'
and wms_emp_department = 'WMS'

select @mail2 =b.wms_emp_email
From @CKB_TMS_ALERT_TBL TMP
join wms_loc_location_hdr a (nolock)
on tmp.LOCATION_FROM = a.wms_loc_code
join wms_employee_hdr b
on a.wms_loc_code = b.wms_emp_default_location
--where wms_emp_group = 'Manager'
where wms_emp_department = 'COM'

select @mail3 = concat(@mail1,';',@mail2)
FROM @CKB_TMS_ALERT_TBL



select @sub = TRIP_PLAN
from @CKB_TMS_ALERT_TBL

select @sub1 = VEHICLE_NO
from @CKB_TMS_ALERT_TBL

select @sub2 = ESTIMATED_ARRIVAL_TIME
from @CKB_TMS_ALERT_TBL

	select @sub = 'Trip Plan id ('+@sub +')'

	select @sub1 = 'with Vehicle No ('+@sub1 +')'

	select @sub2 = 'Estimated Arrival Time ('+@sub2 +')'	

	select @sub3 = concat(@sub,@sub1,@sub2)
    FROM @CKB_TMS_ALERT_TBL

		select @body	=	N'<!DOCTYPE html>
								<html>
								<head>
								<style>
								table, th, td {
												border: 1px solid black;font-weight: normal;font-family:Calibri;
											  }
								</style>
								</head>
								<body>
								Dear CKB Team Member,<br><br>
								This is to bring to your notice that a new trip is destined for your location. Below are the trip details.<br><br>
								</br>
								</body>
								</html>'

		select @body_dtl = N'<HTML><BODY><span style="font-family:Calibri;              
								font-size:12px"> '+''+ '<BR/><tr>             
								</tr>' +             
								N'<table border="1" cellpadding="0" cellspacing="0" width="200px" style="border-collapse:collapse;">' +                       
								N'<tr>             
								<th><b><i>Trip </b></i></th>                         
								<th><b><i>From location </b></i></th>
								<th><b><i>vehicle No </b></i></th>
								<th><b><i>Primary Ref.Doc.No. </b></i></th>
								<th><b><i>Customer </b></i></th>
								<th><b><i>Item code </b></i></th>
								<th><b><i>Order quantity </b></i></th>
								<th><b><i>Estimated Departure Time </b></i></th>
								<th><b><i>Estimated Arrival Time </b></i></th>
								<th><b><i>Booking Inforrmation </b></i></th>
								</tr>' +    
								CAST (( SELECT  
								            [td/@align]='center',td = isnull(cast([TRIP_PLAN]as nvarchar(500)),' '), '',              
											[td/@align]='center',td = isnull(cast([LOCATION_FROM]as nvarchar(500)),' '), '',
											[td/@align]='center',td = isnull(cast([VEHICLE_NO ]as nvarchar(500)),' '), '',  
											[td/@align]='center',td = isnull(cast([PRIMARY_REF_DOC]as nvarchar(500)),' '), '',
											[td/@align]='center',td = isnull(cast([CUSTOMER_NAME ]as nvarchar(500)),' '), '',
											[td/@align]='center',td = isnull(cast([ITEM_CODE ]as nvarchar(500)),' '), '',
											[td/@align]='center',td = isnull(cast([ORDER_QTY]as nvarchar(500)),' '), '',
											[td/@align]='center',td = isnull(cast([ESTIMATED_DEPART_TIME]as nvarchar(500)),' '), '',
											[td/@align]='center',td = isnull(cast([ESTIMATED_ARRIVAL_TIME ]as nvarchar(500)),' '), '',
											[td/@align]='center',td = isnull(cast([BOOKING_INFORMATION]as nvarchar(500)),' '), ''
								
								
								
								
								 From @CKB_TMS_ALERT_TBL
								 FOR XML PATH('tr'), TYPE                
										) AS NVARCHAR(MAX)                
										) +               
								N'</table>' +             
								N'<br/>' +'<br/>'+'<br/>'+'</span><BR/>'

		select @body_footer  = 	N'<!DOCTYPE html>
									<html>
									<head>
									<style>
									table, th, td {
													border: 1px solid black;font-weight: normal;font-family:Calibri;
												  }
									</style>
									</head>
									<body>
									<br><br>
									<i>*This is an auto-generated email, please do not reply to this message.</i>
									
									</br>
									</body>
									</html>'

                            select @mail_body = @body+@body_dtl + @body_footer

							

							if @status = 'RL'
						begin
							exec msdb..sp_send_dbmail 
									@profile_name	=   'ckbdev', 
									@subject		=	@sub3,
									@body			=	@mail_body,
									@body_format	=	'html',
									@recipients		=	@mail3
									                    --'ezhilarasi@amitysoft.com;parthiban.r@amitysoft.com'
						 
									
 end


set nocount off

end
go
if exists(
select * from sys.objects where name = 'CKB_TMS_ALERT_TRIGGER' and type	=	'TR'
)
begin

ENABLE TRIGGER dbo.CKB_TMS_ALERT_TRIGGER ON dbo.tms_pltph_trip_plan_hdr

end