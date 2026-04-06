-- ==========================================
-- EXERCICI 1: BASES DE DADES OBJECTE-RELACIONALS
-- ==========================================

-- 1. CREACIÓN DE LOS TIPOS (TYPES)
-- Creamos el tipo básico para la dirección
CREATE OR REPLACE TYPE adreca AS OBJECT (
carrer VARCHAR2(100),
ciutat VARCHAR2(50),
codi_postal VARCHAR2(10)
);
/

-- Creamos el tipo para almacenar un teléfono individual
CREATE OR REPLACE TYPE telefon AS OBJECT (
tipus VARCHAR2(20),
numero VARCHAR2(15)
);
/

-- Creamos un VARRAY (array de tamaño fijo) para almacenar hasta 2 teléfonos
CREATE OR REPLACE TYPE vec_telefons AS VARRAY(2) OF telefon;
/

-- Creamos el tipo proveedor que incluye la dirección y el array de teléfonos
CREATE OR REPLACE TYPE proveidor AS OBJECT (
codi NUMBER,
nom VARCHAR2(50),
adreca_prov adreca,
telefons vec_telefons,
correu_electronic VARCHAR2(50)
);
/

-- Tipo simple para almacenar los datos del material
CREATE OR REPLACE TYPE material AS OBJECT (
codi NUMBER,
nom VARCHAR2(50),
descripcio VARCHAR2(100),
cost_unitari NUMBER(10,2)
);
/

-- Tipo para la línea de compra. Incluye una referencia (REF) al material
-- y declaramos la cabecera del método para calcular el subtotal.
CREATE OR REPLACE TYPE linia_compra AS OBJECT (
codi NUMBER,
ref_material REF material,
quantitat NUMBER,
descompte NUMBER(10,2),
MEMBER FUNCTION subtotal RETURN NUMBER
);
/

-- Creamos un tipo tabla (Nested Table) que contendrá múltiples líneas de compra
CREATE OR REPLACE TYPE taula_linies AS TABLE OF linia_compra;
/

-- Tipo principal de la compra que enlaza con el proveedor e incluye
-- la tabla anidada de líneas
CREATE OR REPLACE TYPE compra AS OBJECT (
codi NUMBER,
data_compra DATE,
ref_proveidor REF proveidor,
linies taula_linies,
MEMBER FUNCTION cost_total RETURN NUMBER
);
/

-- 2. CREACIÓN DE LAS TABLAS PARA ALMACENAR LOS OBJETOS
-- Estas tablas físicas guardarán las instancias de nuestros tipos
CREATE TABLE taula_materials OF material (
codi PRIMARY KEY
);

CREATE TABLE taula_proveidors OF proveidor (
codi PRIMARY KEY
);

-- Al usar una tabla anidada (linies), debemos indicar cómo se almacenará físicamente
CREATE TABLE taula_compres OF compra (
codi PRIMARY KEY
) NESTED TABLE linies STORE AS linies_compra_nt;

-- 3. IMPLEMENTACIÓN DE LOS MÉTODOS (TYPE BODIES)
CREATE OR REPLACE TYPE BODY linia_compra AS
MEMBER FUNCTION subtotal RETURN NUMBER IS
v_cost NUMBER(10,2);
BEGIN
-- Usamos DEREF para acceder al objeto material a través de su referencia
-- y así obtener su coste unitario sin hacer un JOIN explícito con la tabla.
SELECT DEREF(self.ref_material).cost_unitari INTO v_cost FROM DUAL;

-- Calculamos: (coste * cantidad) - descuento
RETURN (v_cost * self.quantitat) - self.descompte;
END;
END;
/

CREATE OR REPLACE TYPE BODY compra AS
MEMBER FUNCTION cost_total RETURN NUMBER IS
v_total NUMBER(10,2) := 0;
BEGIN
-- Recorremos la tabla anidada de líneas (si existe) y sumamos los subtotales
IF self.linies IS NOT NULL THEN
FOR i IN 1..self.linies.COUNT LOOP
v_total := v_total + self.linies(i).subtotal();
END LOOP;
END IF;

RETURN v_total;
END;
END;
/

-- 4. INSERCIÓN DE DATOS DE PRUEBA
INSERT INTO taula_materials VALUES (1, 'Fusta', 'Taulons de fusta', 15.50);
INSERT INTO taula_materials VALUES (2, 'Claus', 'Caixa 100 claus', 5.00);

-- Insertamos un proveedor construyendo los objetos anidados (adreca y vec_telefons) en línea
INSERT INTO taula_proveidors VALUES (
100, 'Fustes SL',
adreca('C/ Major 1', 'Barcelona', '08001'),
vec_telefons(telefon('Fix', '931234567'), telefon('Mobil', '600123456')),
'contacte@fustes.cat'
);

-- Insertamos una compra. Usamos subconsultas con REF() para obtener los punteros
-- al proveedor y a los materiales que ya existen en sus respectivas tablas.
INSERT INTO taula_compres VALUES (
1000, SYSDATE,
(SELECT REF(p) FROM taula_proveidors p WHERE p.codi = 100),
taula_linies(
linia_compra(1, (SELECT REF(m) FROM taula_materials m WHERE m.codi = 1), 10, 5),
linia_compra(2, (SELECT REF(m) FROM taula_materials m WHERE m.codi = 2), 2, 0)
)
);

-- 5. COMPROBACIÓN (CONSULTA)
-- Llamamos al método cost_total() de la compra para ver si calcula bien (debería dar 160)
SELECT c.codi, c.cost_total() AS total_compra
FROM taula_compres c;
