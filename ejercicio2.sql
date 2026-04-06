-- ============================================================
-- JERARQUÍA DE TIPOS EN ORACLE (EJERCICIO COMPLETO)
-- ============================================================

-- ------------------------------------------------------------
-- PARTE 1: DEFINICIÓN DE LOS TIPOS (CREATE TYPE)
-- ------------------------------------------------------------

-- Tipo base: PERSONA
-- Contiene los atributos comunes. NOT FINAL permite la herencia.
CREATE OR REPLACE TYPE Persona AS OBJECT (
codi NUMBER,
dni VARCHAR2(10),
nom VARCHAR2(100),
adreca VARCHAR2(200),
telefon VARCHAR2(15)
) NOT FINAL;
/

-- Subtipo EMPLEAT (Hereda de Persona)
CREATE OR REPLACE TYPE Empleat UNDER Persona (
sou NUMBER,
data_contracte DATE,
correu_corporatiu VARCHAR2(100),
departament VARCHAR2(100),
MEMBER FUNCTION antiguitat RETURN NUMBER
) NOT FINAL;
/

-- Subtipo ALUMNE (Hereda de Persona)
CREATE OR REPLACE TYPE Alumne UNDER Persona (
num_expedient NUMBER,
correu VARCHAR2(100),
data_naixement DATE,
MEMBER FUNCTION edat RETURN NUMBER
) NOT FINAL;
/

-- Subtipo INVESTIGADOR (Hereda de Empleat)
CREATE OR REPLACE TYPE Investigador UNDER Empleat (
especialitat VARCHAR2(100),
num_publicacions NUMBER,
MEMBER FUNCTION nivell_recerca RETURN VARCHAR2
);
/

-- Subtipo ADMINISTRATIU (Hereda de Empleat)
CREATE OR REPLACE TYPE Administratiu UNDER Empleat (
carrec VARCHAR2(100),
tipus_jornada VARCHAR2(20),
MEMBER FUNCTION sou_anual RETURN NUMBER
);
/

-- Subtipo ALUMNE_GRAU (Hereda de Alumne)
CREATE OR REPLACE TYPE AlumneGrau UNDER Alumne (
titulacio VARCHAR2(100),
durada NUMBER,
any_1a_matricula NUMBER,
MEMBER FUNCTION anys_restants RETURN NUMBER,
CONSTRUCTOR FUNCTION AlumneGrau(
codi NUMBER, dni VARCHAR2, nom VARCHAR2, adreca VARCHAR2,
telefon VARCHAR2, num_expedient NUMBER, correu VARCHAR2,
data_naixement DATE, titulacio VARCHAR2
) RETURN SELF AS RESULT
);
/

-- Subtipo ALUMNE_MASTER (Hereda de Alumne)
CREATE OR REPLACE TYPE AlumneMaster UNDER Alumne (
programa VARCHAR2(200),
especialitat VARCHAR2(100),
num_moduls NUMBER,
MEMBER FUNCTION resum_estudis RETURN VARCHAR2,
CONSTRUCTOR FUNCTION AlumneMaster(
codi NUMBER, dni VARCHAR2, nom VARCHAR2, adreca VARCHAR2,
telefon VARCHAR2, num_expedient NUMBER, correu VARCHAR2,
data_naixement DATE
) RETURN SELF AS RESULT
);
/

-- ------------------------------------------------------------
-- PARTE 2: IMPLEMENTACIÓN DE LOS MÉTODOS (CREATE TYPE BODY)
-- ------------------------------------------------------------

CREATE OR REPLACE TYPE BODY Empleat AS
MEMBER FUNCTION antiguitat RETURN NUMBER IS
BEGIN
RETURN TRUNC(MONTHS_BETWEEN(SYSDATE, data_contracte) / 12);
END antiguitat;
END;
/

CREATE OR REPLACE TYPE BODY Alumne AS
MEMBER FUNCTION edat RETURN NUMBER IS
BEGIN
RETURN TRUNC(MONTHS_BETWEEN(SYSDATE, data_naixement) / 12);
END edat;
END;
/

CREATE OR REPLACE TYPE BODY Investigador AS
MEMBER FUNCTION nivell_recerca RETURN VARCHAR2 IS
BEGIN
IF num_publicacions < 5 THEN
  RETURN 'Inicial';
ELSIF num_publicacions <= 15 THEN
  RETURN 'Consolidat';
ELSE
  RETURN 'Senior';
END IF;
END nivell_recerca;
END;
/

CREATE OR REPLACE TYPE BODY Administratiu AS
MEMBER FUNCTION sou_anual RETURN NUMBER IS
BEGIN
RETURN sou * 14;
END sou_anual;
END;
/

CREATE OR REPLACE TYPE BODY AlumneGrau AS
MEMBER FUNCTION anys_restants RETURN NUMBER IS
BEGIN
RETURN durada - (EXTRACT(YEAR FROM SYSDATE) - any_1a_matricula);
END anys_restants;

CONSTRUCTOR FUNCTION AlumneGrau(
codi NUMBER, dni VARCHAR2, nom VARCHAR2, adreca VARCHAR2,
telefon VARCHAR2, num_expedient NUMBER, correu VARCHAR2,
data_naixement DATE, titulacio VARCHAR2
) RETURN SELF AS RESULT IS
BEGIN
SELF.codi := codi;
SELF.dni := dni;
SELF.nom := nom;
SELF.adreca := adreca;
SELF.telefon := telefon;
SELF.num_expedient := num_expedient;
SELF.correu := correu;
SELF.data_naixement := data_naixement;
SELF.titulacio := titulacio;
SELF.durada := 4;
SELF.any_1a_matricula := EXTRACT(YEAR FROM SYSDATE);
RETURN;
END;
END;
/

CREATE OR REPLACE TYPE BODY AlumneMaster AS
MEMBER FUNCTION resum_estudis RETURN VARCHAR2 IS
BEGIN
RETURN 'Prog: ' || programa || ' | Esp: ' || especialitat || ' | Módulos: ' || num_moduls;
END resum_estudis;

CONSTRUCTOR FUNCTION AlumneMaster(
codi NUMBER, dni VARCHAR2, nom VARCHAR2, adreca VARCHAR2,
telefon VARCHAR2, num_expedient NUMBER, correu VARCHAR2,
data_naixement DATE
) RETURN SELF AS RESULT IS
BEGIN
SELF.codi := codi;
SELF.dni := dni;
SELF.nom := nom;
SELF.adreca := adreca;
SELF.telefon := telefon;
SELF.num_expedient := num_expedient;
SELF.correu := correu;
SELF.data_naixement := data_naixement;
SELF.programa := 'Màster en Enginyeria del Software';
SELF.especialitat := 'Arquitectura';
SELF.num_moduls := 10;
RETURN;
END;
END;
/

-- ------------------------------------------------------------
-- PARTE 3: CREACIÓN DE TABLAS (Tarea 5)
-- ------------------------------------------------------------

CREATE TABLE taula_persona OF Persona;
CREATE TABLE taula_empleat OF Empleat;
CREATE TABLE taula_alumne OF Alumne;
CREATE TABLE taula_investigador OF Investigador;
CREATE TABLE taula_administratiu OF Administratiu;
CREATE TABLE taula_alumne_grau OF AlumneGrau;
CREATE TABLE taula_alumne_master OF AlumneMaster;

-- ------------------------------------------------------------
-- PARTE 4: INSERCIÓN DE DATOS (Tarea 6)
-- ------------------------------------------------------------

INSERT INTO taula_empleat VALUES (
Empleat(1, '111A', 'Pepe', 'BCN', '600', 2000,
TO_DATE('2020-01-01','YYYY-MM-DD'), 'pepe@corp.com', 'IT')
);

INSERT INTO taula_alumne_grau VALUES (
AlumneGrau(2, '222B', 'Ana', 'MAD', '611', 101, 'ana@edu.com',
TO_DATE('2000-05-05','YYYY-MM-DD'), 'Informática')
);

INSERT INTO taula_alumne_master VALUES (
AlumneMaster(3, '333C', 'Luis', 'VAL', '622', 202, 'luis@edu.com',
TO_DATE('1995-10-10','YYYY-MM-DD'))
);

-- ------------------------------------------------------------
-- PARTE 5: COMPROBACIÓN DE FUNCIONES (Tarea 7)
-- ------------------------------------------------------------

SELECT e.nom, e.antiguitat()
FROM taula_empleat e;

SELECT ag.nom, ag.anys_restants()
FROM taula_alumne_grau ag;

SELECT am.nom, am.resum_estudis()
FROM taula_alumne_master am;

-- ------------------------------------------------------------
-- PARTE 6: POLIMORFISMO EN TAULA_PERSONA (Tarea 8)
-- ------------------------------------------------------------

INSERT INTO taula_persona VALUES (
Investigador(10, '100X', 'Dra. Elena', 'Lab', '900', 4000,
SYSDATE-3000, 'elena@uni.edu', 'IA', 20)
);

SELECT p.nom,
TREAT(VALUE(p) AS Investigador).nivell_recerca() AS nivel
FROM taula_persona p
WHERE VALUE(p) IS OF (Investigador);
