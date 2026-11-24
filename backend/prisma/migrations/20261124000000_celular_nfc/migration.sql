-- AlterEnum
ALTER TYPE "MetodoAcesso" ADD VALUE 'CELULAR';

-- CreateTable
CREATE TABLE "nfc_phones" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "chavePublica" TEXT NOT NULL,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "nfc_phones_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "nfc_phones_chavePublica_key" ON "nfc_phones"("chavePublica");

-- CreateIndex
CREATE INDEX "nfc_phones_userId_idx" ON "nfc_phones"("userId");

-- AddForeignKey
ALTER TABLE "nfc_phones" ADD CONSTRAINT "nfc_phones_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

