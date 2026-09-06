import { readFile, readdir } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { pathToFileURL } from 'node:url';

// Usage: node test/review_database.mjs <path-to-@electric-sql/pglite> [SQL files...]
// Uses an ephemeral PostgreSQL WASM database and never accepts a database URL.
const packagePath = resolve(process.argv[2]);
const { PGlite } = await import(pathToFileURL(join(packagePath, 'dist/index.js')));
const { pgcrypto } = await import(pathToFileURL(join(packagePath, 'dist/contrib/pgcrypto.js')));
const { pg_trgm } = await import(pathToFileURL(join(packagePath, 'dist/contrib/pg_trgm.js')));
const db = new PGlite({ extensions: { pgcrypto, pg_trgm } });
const run = async (file) => {
  const sql = (await readFile(file, 'utf8')).replace(/^\\(?:set|echo) .*$/gm, '');
  try { await db.exec(sql); } catch (error) {
    const line = sql.slice(0, Number(error.position ?? 1)).split('\n').length;
    console.error(`SQL file: ${file}, line: ${line}`);
    throw error;
  }
  console.log(`PASS ${file}`);
};
try {
  await run('test/review_database_bootstrap.sql');
  const files = process.argv.slice(3);
  if (files[0] === '--migrations') {
    files.shift();
    for (const name of (await readdir('supabase/migrations')).filter((n) => n.endsWith('.sql')).sort()) {
      await run(join('supabase/migrations', name));
    }
  } else {
    await run('supabase/full_schema.sql');
  }
  for (const file of files.length ? files : [
    'test/trigger_sanity.sql', 'test/doctor_role_integrity.sql',
    'test/patient_document_permissions.sql', 'test/review_access_boundaries.sql',
    'test/review_financial_integrity.sql', 'test/review_booking_and_edits.sql',
  ]) await run(file);
  const tables = await db.query(`SELECT count(*)::int AS count FROM pg_tables WHERE schemaname='public'`);
  console.log(`Public tables loaded: ${tables.rows[0].count}`);
} catch (error) {
  console.error(`FAIL ${error.message}`);
  if (error.where) console.error(error.where);
  process.exitCode = 1;
} finally {
  await db.close();
}
