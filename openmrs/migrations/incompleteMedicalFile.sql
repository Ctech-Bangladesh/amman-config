DELETE FROM global_property where property = 'emrapi.sqlSearch.incompleteMedicalFile';
 select uuid() into @uuid;


 INSERT INTO global_property (`property`, `property_value`, `description`, `uuid`)
 VALUES ('emrapi.sqlSearch.incompleteMedicalFile',
"SELECT `Date of File Received`, `identifier`, name , uuid , `Name of MLO` , `Documents Needed to be Complete`
FROM (SELECT
        concat(pn.given_name, ' ', pn.family_name) AS name,
        pi.identifier                              AS `identifier`,
        p.uuid                                     AS uuid,
        GROUP_CONCAT(DISTINCT (IF(obs_fscn.name = 'FSTG, Date received' AND latest_encounter.person_id IS NOT NULL, DATE_FORMAT(o.value_datetime, '%d/%m/%Y'), NULL)) ORDER BY o.obs_id DESC) AS 'Date of File Received',
        `Name of MLO`,
        GROUP_CONCAT(DISTINCT (IF(obs_fscn.name = 'FSTG, Is the medical file complete?' AND latest_encounter.person_id IS NOT NULL,COALESCE(coded_fscn.name, coded_scn.name) , NULL)) ORDER BY o.obs_id DESC) AS 'Isthemedicalfilecomplete?',
        GROUP_CONCAT(DISTINCT (IF(obs_fscn.name = 'FSTG, Document(s) needed to be complete' AND latest_encounter.person_id IS NOT NULL,o.value_text , NULL)) ORDER BY o.obs_id DESC) AS 'Documents Needed to be Complete'
      FROM person p
        JOIN patient_identifier pi ON p.person_id = pi.patient_id
        JOIN person_name pn ON p.person_id = pn.person_id
        JOIN obs o ON p.person_id = o.person_id AND o.voided IS FALSE
        JOIN concept_name obs_fscn ON o.concept_id = obs_fscn.concept_id AND
                                      obs_fscn.name IN
                                      ('FSTG, Date received','FSTG, Document(s) needed to be complete','FSTG, Is the medical file complete?')
                                      AND obs_fscn.voided IS FALSE AND obs_fscn.concept_name_type= 'FULLY_SPECIFIED'
        LEFT OUTER JOIN person_attribute pa ON p.person_id = pa.person_id AND pa.voided is false
        LEFT OUTER JOIN person_attribute_type pat ON pa.person_attribute_type_id = pat.person_attribute_type_id AND pat.retired is false
        LEFT OUTER JOIN concept_name scn ON pat.format = 'org.openmrs.Concept' AND pa.value = scn.concept_id AND scn.concept_name_type = 'SHORT' AND scn.voided is false
        LEFT OUTER JOIN concept_name fscn ON pat.format = 'org.openmrs.Concept' AND pa.value = fscn.concept_id AND fscn.concept_name_type = 'FULLY_SPECIFIED' AND fscn.voided is false
        JOIN encounter e ON o.encounter_id = e.encounter_id AND e.voided is FALSE
        LEFT JOIN concept_name coded_fscn on coded_fscn.concept_id = o.value_coded AND coded_fscn.concept_name_type= 'FULLY_SPECIFIED' AND coded_fscn.voided is false
        LEFT JOIN concept_name coded_scn on coded_scn.concept_id = o.value_coded AND coded_fscn.concept_name_type= 'SHORT' AND coded_scn.voided is false
        LEFT JOIN (SELECT
                     en.visit_id,
                     person_id,
                     obs.concept_id,
                     max(en.encounter_datetime) AS max_encounter_datetime
                   FROM obs
                     JOIN encounter en ON obs.encounter_id = en.encounter_id AND obs.voided IS FALSE
                                          AND en.visit_id IN (SELECT v.visit_id FROM
                       visit v
                       JOIN  (SELECT patient_id AS patient_id, max(date_started) AS date_started
                              FROM visit GROUP BY patient_id) latest_visit
                         ON v.date_started = latest_visit.date_started AND v.patient_id = latest_visit.patient_id AND v.voided IS FALSE )
                   GROUP BY obs.person_id, obs.concept_id) latest_encounter
          ON o.person_id = latest_encounter.person_id AND o.concept_id = latest_encounter.concept_id
             AND latest_encounter.max_encounter_datetime = e.encounter_datetime
        LEFT JOIN (SELECT
                     obs.person_id,
                     encounter.encounter_id,
                     c_name AS name,
                     GROUP_CONCAT(DISTINCT (IF(c_name = 'MH, Name of MLO', COALESCE(coded_fscn.name, coded_scn.name), NULL))) AS 'Name of MLO'
                   FROM (SELECT
                           cn.name                 AS c_name,
                           obs.person_id,
                           obs.encounter_id,
                           max(encounter_datetime) AS max_encounter_datetime,
                           obs.concept_id
                         FROM obs
                           JOIN encounter ON obs.encounter_id = encounter.encounter_id AND obs.voided IS FALSE
                           JOIN concept_name cn ON cn.name IN ('MH, Name of MLO')
                                                   AND cn.concept_id = obs.concept_id
                         GROUP BY person_id, concept_id) result
                     JOIN encounter ON result.max_encounter_datetime = encounter.encounter_datetime
                     JOIN obs ON encounter.encounter_id = obs.encounter_id AND obs.concept_id = result.concept_id AND obs.voided IS FALSE
                     LEFT JOIN concept_name coded_fscn ON coded_fscn.concept_id = obs.value_coded
                                                          AND coded_fscn.concept_name_type = 'FULLY_SPECIFIED'
                                                          AND coded_fscn.voided IS FALSE
                     LEFT JOIN concept_name coded_scn ON coded_scn.concept_id = obs.value_coded
                                                         AND coded_fscn.concept_name_type = 'SHORT'
                                                         AND coded_scn.voided IS FALSE
                   GROUP BY obs.person_id
                  )
                  obs_across_visits ON p.person_id = obs_across_visits.person_id
        JOIN patient_program pp ON p.person_id = pp.patient_id AND pp.date_completed is NULL AND pp.voided =0
      GROUP BY p.person_id) result
WHERE  (`Isthemedicalfilecomplete?` = 'No')",'Incomplete Medical File',@uuid);