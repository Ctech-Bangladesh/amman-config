DELETE FROM global_property WHERE property = 'bahmni.sqlGet.pastAppointments';
SELECT uuid() INTO @uuid;

INSERT INTO global_property (property, property_value, description, uuid)
 VALUES ('bahmni.sqlGet.pastAppointments',
"SELECT
     app_service.name                                                                                AS `DASHBOARD_APPOINTMENTS_SERVICE_KEY`,
     app_service_type.name                                                                           AS `DASHBOARD_APPOINTMENTS_SERVICE_TYPE_KEY`,
     DATE_FORMAT(start_date_time, \"%d/%m/%Y\")                                                        AS `DASHBOARD_APPOINTMENTS_DATE_KEY`,
     CONCAT(DATE_FORMAT(start_date_time, \"%l:%i %p\"), \" - \", DATE_FORMAT(end_date_time, \"%l:%i %p\")) AS `DASHBOARD_APPOINTMENTS_SLOT_KEY`,
     prov.name                                                                                       AS `DASHBOARD_APPOINTMENTS_PROVIDER_KEY`,
     pa.status                                                                                       AS `DASHBOARD_APPOINTMENTS_STATUS_KEY`
FROM
   patient_appointment pa
   JOIN person p ON p.person_id = pa.patient_id AND pa.voided IS FALSE
   JOIN appointment_service app_service
     ON app_service.appointment_service_id = pa.appointment_service_id AND app_service.voided IS FALSE
   LEFT JOIN provider prov ON prov.provider_id = pa.provider_id
   LEFT JOIN appointment_service_type app_service_type
     ON app_service_type.appointment_service_type_id = pa.appointment_service_type_id
        AND app_service_type.voided IS FALSE
 WHERE p.uuid = ${patientUuid} AND start_date_time < CURDATE()
 ORDER BY start_date_time DESC
 LIMIT 5;"
, 'Past appointments for patient', @uuid);