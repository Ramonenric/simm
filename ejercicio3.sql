-- ============================================================
-- EJERCICIO 3: MODELO CONCEPTUAL Y ASOCIACIONES
-- ============================================================

-- ------------------------------------------------------------
-- PARTE 1: DEFINICIÓN DE LOS TYPES (Tarea 9)
-- ------------------------------------------------------------

-- Tipo base CURS
CREATE OR REPLACE TYPE curs AS OBJECT (
idCurs NUMBER,
nom VARCHAR2(50),
hores NUMBER,
preu NUMBER(10,2),
MEMBER FUNCTION coordinador RETURN VARCHAR2,
MEMBER FUNCTION actiu RETURN VARCHAR2
) NOT FINAL;
/

-- Tipo base EMPLEAT_CURS
CREATE OR REPLACE TYPE empleat_curs AS OBJECT (
dni VARCHAR2(10),
nom VARCHAR2(50),
cognoms VARCHAR2(50),
dataContracte DATE,
telefon VARCHAR2(15),
MEMBER FUNCTION antiguitat RETURN NUMBER
) NOT FINAL;
/

-- Tipo colección de referencias a CURS
CREATE OR REPLACE TYPE taula_refs_curs AS TABLE OF REF curs;
/

-- Tipo CLIENT con tabla anidada de cursos
CREATE OR REPLACE TYPE client AS OBJECT (
nif VARCHAR2(10),
nom VARCHAR2(50),
adreca VARCHAR2(100),
telefon VARCHAR2(15),
cursos_contractats taula_refs_curs,
MEMBER FUNCTION numCursos RETURN NUMBER
);
/

-- Subtipo CURS_ACTIU
CREATE OR REPLACE TYPE curs_actiu UNDER curs (
dataInici DATE,
dataFiPrevista DATE,
modalitat VARCHAR2(20),
MEMBER FUNCTION modulActual RETURN VARCHAR2
);
/

-- Subtipo CURS_HISTORIC
CREATE OR REPLACE TYPE curs_historic UNDER curs (
dataFinal DATE,
valoracio NUMBER
);
/

-- Subtipo FORMADOR
CREATE OR REPLACE TYPE formador UNDER empleat_curs (
especialitat VARCHAR2(50),
nivell VARCHAR2(20)
);
/

-- Subtipo COORDINADOR
CREATE OR REPLACE TYPE coordinador UNDER empleat_curs (
area VARCHAR2(50),
despatx VARCHAR2(20)
);
/

-- Subtipo TECNIC
CREATE OR REPLACE TYPE tecnic UNDER empleat_curs (
certificacio VARCHAR2(50),
sistema VARCHAR2(50)
);
/

-- Tipo MODUL
CREATE OR REPLACE TYPE modul AS OBJECT (
idModul NUMBER,
nom VARCHAR2(50),
dataInici DATE,
dataFi DATE,
MEMBER FUNCTION numCursos RETURN NUMBER
);
/

-- Tipo asociación COORDINA
CREATE OR REPLACE TYPE coordina AS OBJECT (
ref_curs REF curs,
ref_empleat REF empleat_curs
);
/

-- Tipo asociación PARTICIPA
CREATE OR REPLACE TYPE participa AS OBJECT (
ref_curs REF curs,
ref_empleat REF empleat_curs
);
/

-- Tipo asociación MODULSCURS
CREATE OR REPLACE TYPE modulscurs AS OBJECT (
ref_curs_actiu REF curs_actiu,
ref_modul REF modul
);
/

-- ------------------------------------------------------------
-- PARTE 2: CREACIÓN DE TABLAS (Tarea 10)
-- ------------------------------------------------------------

CREATE TABLE t_clients OF client (
nif PRIMARY KEY
) NESTED TABLE cursos_contractats STORE AS cursos_client_nt;

CREATE TABLE t_cursos OF curs (
idCurs PRIMARY KEY
);

CREATE TABLE t_empleats_curs OF empleat_curs (
dni PRIMARY KEY
);

CREATE TABLE t_moduls OF modul (
idModul PRIMARY KEY
);

CREATE TABLE t_coordina OF coordina;
CREATE TABLE t_participa OF participa;
CREATE TABLE t_modulscurs OF modulscurs;

-- ------------------------------------------------------------
-- PARTE 3: INSERCIÓN DE DATOS (Tarea 11)
-- ------------------------------------------------------------

INSERT INTO t_cursos VALUES (
curs_actiu(
1, 'Introducció a Oracle', 20, 150.0,
TO_DATE('2026-04-01', 'YYYY-MM-DD'),
TO_DATE('2026-04-30', 'YYYY-MM-DD'),
'Online'
)
);

INSERT INTO t_cursos VALUES (
curs_historic(
2, 'Java Bàsic', 30, 200.0,
TO_DATE('2025-12-01', 'YYYY-MM-DD'),
8
)
);

INSERT INTO t_empleats_curs VALUES (
coordinador(
'12345678A', 'Joan', 'Garcia',
TO_DATE('2020-01-01', 'YYYY-MM-DD'),
'666111222',
'Informàtica', 'D-101'
)
);

INSERT INTO t_empleats_curs VALUES (
formador(
'87654321B', 'Marta', 'Sánchez',
TO_DATE('2023-05-15', 'YYYY-MM-DD'),
'666333444',
'Bases de Dades', 'Expert'
)
);

INSERT INTO t_moduls VALUES (
modul(
101, 'Fonaments SQL',
TO_DATE('2026-04-01', 'YYYY-MM-DD'),
NULL
)
);

INSERT INTO t_coordina VALUES (
coordina(
(SELECT REF(c) FROM t_cursos c WHERE idCurs = 1),
(SELECT REF(e) FROM t_empleats_curs e WHERE dni = '12345678A')
)
);

INSERT INTO t_modulscurs VALUES (
modulscurs(
(SELECT TREAT(REF(c) AS REF curs_actiu)
 FROM t_cursos c
 WHERE idCurs = 1),
(SELECT REF(m)
 FROM t_moduls m
 WHERE idModul = 101)
)
);

COMMIT;

-- ------------------------------------------------------------
-- PARTE 4: IMPLEMENTACIÓN DE MÉTODOS (Tarea 12)
-- ------------------------------------------------------------

CREATE OR REPLACE TYPE BODY client AS
MEMBER FUNCTION numCursos RETURN NUMBER IS
BEGIN
RETURN self.cursos_contractats.COUNT;
END;
END;
/

CREATE OR REPLACE TYPE BODY curs AS
MEMBER FUNCTION coordinador RETURN VARCHAR2 IS
v_nom VARCHAR2(100);
BEGIN
SELECT DEREF(tc.ref_empleat).nom || ' ' || DEREF(tc.ref_empleat).cognoms
INTO v_nom
FROM t_coordina tc
WHERE DEREF(tc.ref_curs).idCurs = self.idCurs;
RETURN v_nom;
EXCEPTION
WHEN NO_DATA_FOUND THEN RETURN 'Sense Coordinador';
END;

MEMBER FUNCTION actiu RETURN VARCHAR2 IS
BEGIN
IF self IS OF (curs_actiu) THEN
  RETURN 'T';
ELSE
  RETURN 'F';
END IF;
END;
END;
/

CREATE OR REPLACE TYPE BODY curs_actiu AS
MEMBER FUNCTION modulActual RETURN VARCHAR2 IS
v_nom_modul VARCHAR2(50);
BEGIN
SELECT DEREF(tmc.ref_modul).nom
INTO v_nom_modul
FROM t_modulscurs tmc
WHERE DEREF(tmc.ref_curs_actiu).idCurs = self.idCurs
AND DEREF(tmc.ref_modul).dataFi IS NULL
FETCH FIRST 1 ROWS ONLY;
RETURN v_nom_modul;
EXCEPTION
WHEN NO_DATA_FOUND THEN RETURN 'Cap mòdul actiu';
END;
END;
/

CREATE OR REPLACE TYPE BODY empleat_curs AS
MEMBER FUNCTION antiguitat RETURN NUMBER IS
BEGIN
RETURN EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM self.dataContracte);
END;
END;
/

CREATE OR REPLACE TYPE BODY modul AS
MEMBER FUNCTION numCursos RETURN NUMBER IS
v_count NUMBER;
BEGIN
SELECT COUNT(*)
INTO v_count
FROM t_modulscurs tmc
WHERE DEREF(tmc.ref_modul).idModul = self.idModul;
RETURN v_count;
END;
END;
/

-- ------------------------------------------------------------
-- PARTE 5: COMPROBACIÓN DE FUNCIONES (Tarea 13)
-- ------------------------------------------------------------

SELECT
c.nom,
c.coordinador() AS nom_coordinador,
c.actiu() AS es_actiu,
TREAT(VALUE(c) AS curs_actiu).modulActual() AS modul_actiu
FROM t_cursos c;

SELECT m.nom, m.numCursos()
FROM t_moduls m;

SELECT e.nom, e.cognoms, e.antiguitat()
FROM t_empleats_curs e;
