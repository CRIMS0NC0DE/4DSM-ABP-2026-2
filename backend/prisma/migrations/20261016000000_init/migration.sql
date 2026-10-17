-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "Perfil" AS ENUM ('ADMIN', 'CONTROLADOR_ACESSO', 'CONDOMINO', 'VISITANTE');

-- CreateEnum
CREATE TYPE "StatusAutorizacao" AS ENUM ('ATIVA', 'CANCELADA');

-- CreateEnum
CREATE TYPE "MetodoAcesso" AS ENUM ('QR', 'NFC');

-- CreateEnum
CREATE TYPE "ResultadoAcesso" AS ENUM ('LIBERADO', 'NEGADO');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "cpf" TEXT NOT NULL,
    "senhaHash" TEXT NOT NULL,
    "perfil" "Perfil" NOT NULL,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "nfc_tags" (
    "id" TEXT NOT NULL,
    "uid" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "ativa" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "nfc_tags_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "buildings" (
    "id" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "endereco" TEXT NOT NULL,

    CONSTRAINT "buildings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gates" (
    "id" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "buildingId" TEXT NOT NULL,

    CONSTRAINT "gates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "doors" (
    "id" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "gateId" TEXT NOT NULL,

    CONSTRAINT "doors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "access_points" (
    "id" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "doorId" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "raioMetros" INTEGER NOT NULL DEFAULT 100,

    CONSTRAINT "access_points_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "terminals" (
    "id" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "accessPointId" TEXT NOT NULL,
    "chaveHash" TEXT NOT NULL,
    "ultimoSinal" TIMESTAMP(3),
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,

    CONSTRAINT "terminals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "authorizations" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "accessPointId" TEXT NOT NULL,
    "dataInicio" DATE NOT NULL,
    "dataFim" DATE NOT NULL,
    "horaInicio" TEXT NOT NULL,
    "horaFim" TEXT NOT NULL,
    "maxUsos" INTEGER NOT NULL,
    "usosRealizados" INTEGER NOT NULL DEFAULT 0,
    "status" "StatusAutorizacao" NOT NULL DEFAULT 'ATIVA',
    "canceladaEm" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "authorizations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "access_events" (
    "id" TEXT NOT NULL,
    "metodo" "MetodoAcesso" NOT NULL,
    "resultado" "ResultadoAcesso" NOT NULL,
    "motivo" TEXT,
    "userId" TEXT,
    "accessPointId" TEXT,
    "terminalId" TEXT,
    "authorizationId" TEXT,
    "credencial" TEXT,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "distanciaMetros" DOUBLE PRECISION,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "access_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "used_qr_tokens" (
    "jti" TEXT NOT NULL,
    "usedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "used_qr_tokens_pkey" PRIMARY KEY ("jti")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_cpf_key" ON "users"("cpf");

-- CreateIndex
CREATE UNIQUE INDEX "nfc_tags_uid_key" ON "nfc_tags"("uid");

-- CreateIndex
CREATE UNIQUE INDEX "terminals_accessPointId_key" ON "terminals"("accessPointId");

-- CreateIndex
CREATE INDEX "authorizations_userId_accessPointId_idx" ON "authorizations"("userId", "accessPointId");

-- CreateIndex
CREATE INDEX "access_events_createdAt_idx" ON "access_events"("createdAt");

-- AddForeignKey
ALTER TABLE "nfc_tags" ADD CONSTRAINT "nfc_tags_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gates" ADD CONSTRAINT "gates_buildingId_fkey" FOREIGN KEY ("buildingId") REFERENCES "buildings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "doors" ADD CONSTRAINT "doors_gateId_fkey" FOREIGN KEY ("gateId") REFERENCES "gates"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "access_points" ADD CONSTRAINT "access_points_doorId_fkey" FOREIGN KEY ("doorId") REFERENCES "doors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "terminals" ADD CONSTRAINT "terminals_accessPointId_fkey" FOREIGN KEY ("accessPointId") REFERENCES "access_points"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "authorizations" ADD CONSTRAINT "authorizations_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "authorizations" ADD CONSTRAINT "authorizations_accessPointId_fkey" FOREIGN KEY ("accessPointId") REFERENCES "access_points"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "access_events" ADD CONSTRAINT "access_events_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "access_events" ADD CONSTRAINT "access_events_accessPointId_fkey" FOREIGN KEY ("accessPointId") REFERENCES "access_points"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "access_events" ADD CONSTRAINT "access_events_terminalId_fkey" FOREIGN KEY ("terminalId") REFERENCES "terminals"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "access_events" ADD CONSTRAINT "access_events_authorizationId_fkey" FOREIGN KEY ("authorizationId") REFERENCES "authorizations"("id") ON DELETE SET NULL ON UPDATE CASCADE;

