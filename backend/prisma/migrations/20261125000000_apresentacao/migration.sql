-- Sprint 3 (apresentação): quem criou a autorização ("Meus visitantes"), comunicados e configurações.
-- AlterTable
ALTER TABLE "authorizations" ADD COLUMN     "criadaPorId" TEXT;

-- CreateTable
CREATE TABLE "comunicados" (
    "id" TEXT NOT NULL,
    "titulo" TEXT NOT NULL,
    "mensagem" TEXT NOT NULL,
    "autorId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "comunicados_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "configuracoes" (
    "id" INTEGER NOT NULL DEFAULT 1,
    "nomeCondominio" TEXT NOT NULL DEFAULT 'Condomínio',
    "contatoPortaria" TEXT NOT NULL DEFAULT 'Fale com a portaria pelo interfone.',
    "moradorPodeConvidar" BOOLEAN NOT NULL DEFAULT true,
    "visitanteMaxUsos" INTEGER NOT NULL DEFAULT 2,
    "visitanteDiasMax" INTEGER NOT NULL DEFAULT 7,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "configuracoes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "comunicados_createdAt_idx" ON "comunicados"("createdAt");

-- CreateIndex
CREATE INDEX "authorizations_criadaPorId_idx" ON "authorizations"("criadaPorId");

-- AddForeignKey
ALTER TABLE "authorizations" ADD CONSTRAINT "authorizations_criadaPorId_fkey" FOREIGN KEY ("criadaPorId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "comunicados" ADD CONSTRAINT "comunicados_autorId_fkey" FOREIGN KEY ("autorId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- A linha única das configurações já nasce com os valores padrão.
INSERT INTO "configuracoes" ("id") VALUES (1) ON CONFLICT DO NOTHING;
