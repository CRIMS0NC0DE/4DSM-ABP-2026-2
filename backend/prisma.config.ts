import 'dotenv/config';
import { defineConfig } from 'prisma/config';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
    seed: 'tsx prisma/seed.ts',
  },
  datasource: {
    // "prisma generate" não precisa de banco; por isso o valor padrão.
    url: process.env.DATABASE_URL ?? 'postgresql://app:app@localhost:5432/app',
  },
});
