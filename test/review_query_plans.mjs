import {readFile,writeFile} from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {resolve,join} from 'node:path';
import {pathToFileURL} from 'node:url';
// Ephemeral diagnostic only. Run from the repo root; no live database URL.
const packagePath=resolve(process.argv[2]);
const baseline=process.argv[3] ?? '88609a3';
const {PGlite}=await import(pathToFileURL(join(packagePath,'dist/index.js')));
const {pgcrypto}=await import(pathToFileURL(join(packagePath,'dist/contrib/pgcrypto.js')));
const {pg_trgm}=await import(pathToFileURL(join(packagePath,'dist/contrib/pg_trgm.js')));
const db=new PGlite({extensions:{pgcrypto,pg_trgm}});
await db.exec(await readFile('test/review_database_bootstrap.sql','utf8'));
await db.exec(execFileSync('git',['show',baseline+':supabase/full_schema.sql'],{encoding:'utf8',maxBuffer:8*1024*1024}));
await db.exec(`
INSERT INTO auth.users(id,email) SELECT md5('user'||g)::uuid,'fixture'||g||'@example.test' FROM generate_series(1,76) g;
INSERT INTO staff(id,user_id,full_name,email,role,is_senior)
 SELECT md5('staff'||g)::uuid,md5('user'||g)::uuid,'Fixture '||g,'fixture'||g||'@example.test',
 CASE WHEN g=76 THEN 'receptionist' ELSE 'doctor' END::user_role,g=1 FROM generate_series(1,76) g;
INSERT INTO patients(id,full_name,phone_number,clinic,next_visit_date)
 SELECT md5('patient'||g)::uuid,'Fixture Patient '||lpad(g::text,5,'0'),'010'||lpad(g::text,8,'0'),
 CASE WHEN g%3=0 THEN 'masr_elgedida' ELSE 'tagamoa' END::clinic_location,
 CASE WHEN g%30=0 THEN '2026-09-29'::date ELSE NULL END FROM generate_series(1,10000) g;
INSERT INTO patient_doctors(patient_id,doctor_id)
 SELECT md5('patient'||g)::uuid,md5('staff'||(g%75+1))::uuid FROM generate_series(1,10000) g;
INSERT INTO appointments(id,patient_id,type,use_package,scheduled_at)
 SELECT md5('appt'||g)::uuid,md5('patient'||(g%10000+1))::uuid,'normal_pt_session',false,
 '2025-01-01'::timestamptz+(g/150)*interval '1 day'+(g%150)*interval '3 minutes' FROM generate_series(1,100000) g;
INSERT INTO appointment_doctors(appointment_id,doctor_id)
 SELECT md5('appt'||g)::uuid,md5('staff'||((g%10000+1)%75+1))::uuid FROM generate_series(1,100000) g;
ANALYZE;`);
console.log('Seeded 10,000 fictional patients, 100,000 appointments, 76 staff.');
const queries={
 week:`SELECT a.*,row_to_json(p) AS patient FROM appointments a JOIN LATERAL (SELECT * FROM patients p WHERE p.id=a.patient_id AND clinic='tagamoa' LIMIT 1000) p ON true WHERE scheduled_at>='2026-09-22' AND scheduled_at<'2026-09-29' ORDER BY scheduled_at,created_at,id LIMIT 500`,
 all_count:`SELECT count(*) FROM appointments a WHERE EXISTS(SELECT 1 FROM patients p WHERE p.id=a.patient_id AND clinic='tagamoa')`,
 patient_list:`SELECT * FROM patients ORDER BY full_name LIMIT 30`,
 search:`SELECT * FROM patients WHERE full_name ILIKE '%07342%' OR phone_number ILIKE '%07342%' ORDER BY full_name LIMIT 50`,
 due:`SELECT * FROM get_due_patients('2026-09-29',NULL,'tagamoa')`
};
const out={};
for(const phase of ['before','after']){
 if(phase==='after') {
  await db.exec(await readFile('supabase/migrations/20260929020000_read_access_query_plans.sql','utf8'));
  await db.exec('ANALYZE');
 }
 out[phase]={};
 for(const [role,user] of [['reception',76],['junior',2]]){
  await db.exec(`RESET ROLE; SELECT set_config('request.jwt.claim.sub',md5('user${user}')::uuid::text,false); SET ROLE authenticated;`);
  out[phase][role]={};
  for(const [name,q] of Object.entries(queries)){
   const result=await db.query('EXPLAIN (ANALYZE,BUFFERS,FORMAT JSON) '+q);
   const plan=result.rows[0]['QUERY PLAN'][0];
   out[phase][role][name]=plan;
   console.log(phase,role,name,plan['Execution Time'], 'ms',plan.Plan['Actual Rows'],'rows');
  }
 }
 await db.exec('RESET ROLE');
}
if(process.argv[4]) await writeFile(process.argv[4],JSON.stringify(out,null,2));
await db.close();
