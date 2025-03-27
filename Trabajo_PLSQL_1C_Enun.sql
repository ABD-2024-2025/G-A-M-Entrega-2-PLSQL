/*
    @author: José Gallardo Caballero
    @author: Sara Abejón Pérez
    @author: María Molina Goyena

    Notes:
        - Hemos identado todo el código utilizando esta extensión de VSCode: 
        https://marketplace.visualstudio.com/items?itemName=adpyke.vscode-sql-formatter
*/

DROP TABLE detalle_pedido CASCADE CONSTRAINTS;
DROP TABLE pedidos CASCADE CONSTRAINTS;
DROP TABLE platos CASCADE CONSTRAINTS;
DROP TABLE personal_servicio CASCADE CONSTRAINTS;
DROP TABLE clientes CASCADE CONSTRAINTS;

DROP SEQUENCE seq_pedidos;


-- Creación de tablas y secuencias
create sequence seq_pedidos;

CREATE TABLE clientes (
    id_cliente INTEGER PRIMARY KEY,
    nombre CHAR(100) NOT NULL,
    apellido CHAR(100) NOT NULL,
    telefono CHAR(20)
);

CREATE TABLE personal_servicio (
    id_personal INTEGER PRIMARY KEY,
    nombre CHAR(100) NOT NULL,
    apellido CHAR(100) NOT NULL,
    pedidos_activos INTEGER DEFAULT 0 CHECK (pedidos_activos <= 5)
);

CREATE TABLE platos (
    id_plato INTEGER PRIMARY KEY,
    nombre CHAR(100) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    disponible INTEGER DEFAULT 1 CHECK (DISPONIBLE in (0,1))
);

CREATE TABLE pedidos (
    id_pedido INTEGER PRIMARY KEY,
    id_cliente INTEGER REFERENCES clientes(id_cliente),
    id_personal INTEGER REFERENCES personal_servicio(id_personal),
    fecha_pedido DATE DEFAULT SYSDATE,
    total DECIMAL(10, 2) DEFAULT 0
);

CREATE TABLE detalle_pedido (
    id_pedido INTEGER REFERENCES pedidos(id_pedido),
    id_plato INTEGER REFERENCES platos(id_plato),
    cantidad INTEGER NOT NULL,
    PRIMARY KEY (id_pedido, id_plato)
);


	
-- Procedimiento a implementar para realizar la reserva
CREATE
OR replace PROCEDURE registrar_pedido(
	arg_id_cliente INTEGER,
	arg_id_personal INTEGER,
	arg_id_primer_plato INTEGER DEFAULT NULL,
	arg_id_segundo_plato INTEGER DEFAULT NULL
) IS Pedido_no_valido
EXCEPTION
;

-- Creamos todos los nombres de las excepciones con sus respectivos códigos y mensajes.
-- Se tratan de tipo CHAR para eliminar los carácteres vaciós que no se utilicen en el mensaje.

PRAGMA exception_init(Pedido_no_valido, -20002);

msg_pedido_no_valido CONSTANT CHAR(200) := 'El pedido debe contener al menos un plato.';

Plato_no_disponible
EXCEPTION
;

PRAGMA exception_init(Plato_no_disponible, -20001);

msg_plato_no_disponible CONSTANT CHAR(200) := 'Uno de los platos seleccionados no está disponible.';

Plato_inexistente
EXCEPTION
;

PRAGMA exception_init(Plato_inexistente, -20004);

msg_primero_inexistente CONSTANT CHAR(200) := 'El primer plato seleccionado no existe.';

msg_segundo_inexistente CONSTANT CHAR(200) := 'El segundo plato seleccionado no existe.';

Personal_ocupado
EXCEPTION
;

PRAGMA exception_init(Personal_ocupado, -20003);

msg_personal_ocupado CONSTANT CHAR(200) := 'El personal de servicio tiene demasiados pedidos.';

-- Variables locales para el procedimiento

total_coste DECIMAL(10, 2);

primero NUMBER(1);

segundo NUMBER(1);

v_precio DECIMAL(10, 2);

v_pedidos_activos INTEGER;

v_plato_existe INTEGER;

BEGIN
	-- Verificar que hay al menos un plato en el pedido
	IF arg_id_primer_plato IS NULL
	AND arg_id_segundo_plato IS NULL THEN raise_application_error(-20002, msg_pedido_no_valido);

END IF;

total_coste := 0;

-- Verificar primer plato
IF arg_id_primer_plato IS NOT NULL THEN -- Verificar si el plato existe
SELECT
	COUNT(*) INTO v_plato_existe
FROM
	platos
WHERE
	id_plato = arg_id_primer_plato;

IF v_plato_existe = 0 THEN raise_application_error(-20004, msg_primero_inexistente);

END IF;

-- Verificar disponibilidad y obtener precio
SELECT
	disponible,
	precio INTO primero,
	v_precio
FROM
	platos
WHERE
	id_plato = arg_id_primer_plato;

IF primero = 0 THEN raise_application_error(-20001, msg_plato_no_disponible);

END IF;

total_coste := total_coste + v_precio;

END IF;

-- Verificar segundo plato
IF arg_id_segundo_plato IS NOT NULL THEN -- Verificar si el plato existe
SELECT
	COUNT(*) INTO v_plato_existe
FROM
	platos
WHERE
	id_plato = arg_id_segundo_plato;

IF v_plato_existe = 0 THEN raise_application_error(-20004, msg_segundo_inexistente);

END IF;

-- Verificar disponibilidad y obtener precio
SELECT
	disponible,
	precio INTO segundo,
	v_precio
FROM
	platos
WHERE
	id_plato = arg_id_segundo_plato;

IF segundo = 0 THEN raise_application_error(-20001, msg_plato_no_disponible);

END IF;

total_coste := total_coste + v_precio;

END IF;

-- Verificar si el personal tiene capacidad para otro pedido
SELECT
	pedidos_activos INTO v_pedidos_activos
FROM
	personal_servicio
WHERE
	id_personal = arg_id_personal FOR
UPDATE -- Este FOR UPDATE explicamos su uso en la respuesta a la pregunta P4.2
;

IF v_pedidos_activos >= 5 THEN raise_application_error(-20003, msg_personal_ocupado);

END IF;

-- Insertar el pedido
INSERT INTO
	pedidos
VALUES
	(
		seq_pedidos.nextval,
		arg_id_cliente,
		arg_id_personal,
		SYSDATE,
		total_coste
	);

-- Insertar detalles del pedido
IF arg_id_primer_plato IS NOT NULL THEN
INSERT INTO
	detalle_pedido
VALUES
	(seq_pedidos.currval, arg_id_primer_plato, 1);

END IF;

IF arg_id_segundo_plato IS NOT NULL THEN
INSERT INTO
	detalle_pedido
VALUES
	(seq_pedidos.currval, arg_id_segundo_plato, 1);

END IF;

-- Actualizar contador de pedidos activos del personal
UPDATE
	personal_servicio
SET
	pedidos_activos = pedidos_activos + 1
WHERE
	id_personal = arg_id_personal;

COMMIT;

EXCEPTION
	WHEN OTHERS THEN -- Realizar un rollback explícito cuando ocurra cualquier error
	    ROLLBACK;

-- Re-lanzar la excepción para que el usuario sepa el error.
RAISE;

END;
/

------ Deja aquí tus respuestas a las preguntas del enunciado:
-- NO SE CORREGIRÁN RESPUESTAS QUE NO ESTÉN AQUÍ (utiliza el espacio que necesites para cada una)
-- * P4.1 
/*
    Garantizamos que un miembro del personal de servicio no supere el límite de pedidos activos 
    realizando una verificación explícita antes de registrar el pedido:
    
    ```sql
    SELECT pedidos_activos INTO v_pedidos_activos
    FROM personal_servicio
    WHERE id_personal = arg_id_personal;

    IF v_pedidos_activos >= 5 THEN 
        raise_application_error(-20003, msg_personal_ocupado);
    END IF;
    ```
    
    Esta validación se realiza antes de insertar cualquier registro en la base de datos,
    evitando así que se creen pedidos para personal que ya ha alcanzado su límite máximo.
    Además, el test del caso 8 verifica específicamente este escenario para asegurar que
    se lanza la excepción correcta cuando un miembro del personal ya tiene 5 pedidos activos.
*/
-- * P4.2
/*
    Para evitar problemas de concurrencia donde dos transacciones podrían asignar simultáneamente
    pedidos al mismo personal que está cerca del límite, decidimos implementar un bloqueo a nivel de fila
    usando la cláusula FOR UPDATE en la consulta que verifica los pedidos activos:
    
    ```
    SELECT pedidos_activos INTO v_pedidos_activos
    FROM personal_servicio
    WHERE id_personal = arg_id_personal
    FOR UPDATE;
    ```
    
    Esta cláusula bloquea la fila del personal consultado hasta que se complete la transacción,
    evitando que otras transacciones concurrentes puedan modificar los mismos datos.
    De esta manera, si dos transacciones intentan asignar un pedido al mismo personal,
    una de ellas tendrá que esperar hasta que la primera libere el bloqueo,
    garantizando así la integridad de la restricción de pedidos activos.
*/
-- * P4.3
/*
    Incluso después de implementar las comprobaciones y el bloqueo con FOR UPDATE,
    no se puede garantizar al 100% que el pedido se realizará correctamente sin inconsistencias,
    por varias razones:
    
    1. Pueden ocurrir errores durante la inserción del pedido o sus detalles que no están relacionados
       con las validaciones previas (por ejemplo, problemas de almacenamiento, restricciones adicionales).
    
    2. En un entorno con conexiones concurrentes, pueden surgir deadlocks si múltiples transacciones
       intentan bloquear recursos en diferente orden.
    
    3. Si el sistema se cae entre la inserción del pedido y la actualización de pedidos_activos,
       podría quedar en un estado inconsistente.
    
    Para mitigar estos problemas, el procedimiento utiliza un manejo de transacciones explícito con
    COMMIT al final y ROLLBACK en el bloque de excepciones, lo que garantiza la atomicidad de todas
    las operaciones. Si cualquier parte falla, todas las operaciones se deshacen, manteniendo así
    la consistencia de los datos.
*/
-- * P4.4
/*
    Si modificásemos la tabla personal_servicio añadiendo CHECK (pedidos_activos <= 5):
    
    - Implicaciones en el código:
        La restricción CHECK proporcionaría una capa adicional de seguridad a nivel de base de datos,
        actuando como una "red de seguridad" incluso si la validación en el código fallara.
        Esta redundancia es positiva para garantizar la integridad de los datos.
    
    - Efecto en la gestión de excepciones:
        Si se intenta actualizar pedidos_activos a un valor mayor que 5, la base de datos lanzaría
        una excepción ORA-02290 (restricción CHECK violada). Esta excepción tendría que ser capturada
        en el bloque EXCEPTION del procedimiento, diferenciándola de otras excepciones.
    
    - Modificaciones necesarias:
        1. Podríamos mantener la validación previa por claridad y mejor experiencia de usuario,
        permitiendo mensajes de error más específicos.
        2. El bloque EXCEPTION debería ampliarse para capturar específicamente la violación de CHECK:
      
      ```sql
        EXCEPTION
            WHEN check_constraint_violated THEN
                -- Definir un código de error personalizado para esta excepción
                ROLLBACK;
                raise_application_error(-20003, msg_personal_ocupado);
            WHEN OTHERS THEN
                ROLLBACK;
                RAISE;
      ```
      
        3. Para mejorar el rendimiento, podríamos incluso considerar eliminar la validación previa
        y depender completamente de la restricción CHECK, simplificando el código pero sacrificando
        la personalización del mensaje de error.
*/
-- * P4.5
/*
    En la implementación de registrar_pedido hemos utilizado varias estrategias de programación:
    
    1. Programación defensiva: El código verifica múltiples condiciones antes de realizar cualquier
    operación crítica (validación de platos existentes, disponibilidad, límites de pedidos). Esto
    se evidencia en las validaciones previas a las inserciones y actualizaciones:
    
    ```sql
    IF arg_id_primer_plato IS NULL AND arg_id_segundo_plato IS NULL THEN
        raise_application_error(-20002, msg_pedido_no_valido);
    END IF;
    ```
    
    2. Manejo estructurado de excepciones: Definimos excepciones personalizadas con códigos específicos
    para diferentes tipos de errores, lo que facilita la identificación y gestión de problemas:
    
    ```sql
    PRAGMA exception_init(Plato_no_disponible, -20001);
    PRAGMA exception_init(Pedido_no_valido, -20002);
    PRAGMA exception_init(Personal_ocupado, -20003);
    PRAGMA exception_init(Plato_inexistente, -20004);
    ```
    
    3. Transaccionalidad: Aseguramos la atomicidad de las operaciones mediante el uso de COMMIT al final
    del procedimiento y ROLLBACK en caso de cualquier error:
    
    ```sql
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    ```
    
    4. Modularidad: El código está estructurado en bloques lógicos separados (validación, inserciones
    de pedidos, inserciones de detalles, actualización de contadores), lo que mejora la legibilidad
    y mantenibilidad.
*/


create or replace
procedure reset_seq( p_seq_name CHAR )
is
    l_val number;
begin
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by -' || l_val || 
                                                          ' minvalue 0';
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by 1 minvalue 0';

end;
/


create or replace procedure inicializa_test is
begin
    
    reset_seq('seq_pedidos');
        
  
    delete from Detalle_pedido;
    delete from Pedidos;
    delete from Platos;
    delete from Personal_servicio;
    delete from Clientes;
    
    -- Insertar datos de prueba
    insert into Clientes (id_cliente, nombre, apellido, telefono) values (1, 'Pepe', 'Perez', '123456789');
    insert into Clientes (id_cliente, nombre, apellido, telefono) values (2, 'Ana', 'Garcia', '987654321');
    
    insert into Personal_servicio (id_personal, nombre, apellido, pedidos_activos) values (1, 'Carlos', 'Lopez', 0);
    insert into Personal_servicio (id_personal, nombre, apellido, pedidos_activos) values (2, 'Maria', 'Fernandez', 5);
    
    insert into Platos (id_plato, nombre, precio, disponible) values (1, 'Sopa', 10.0, 1);
    insert into Platos (id_plato, nombre, precio, disponible) values (2, 'Pasta', 12.0, 1);
    insert into Platos (id_plato, nombre, precio, disponible) values (3, 'Carne', 15.0, 0);

    commit;
end;
/

exec inicializa_test;

-- Completa lost test, incluyendo al menos los del enunciado y añadiendo los que consideres necesarios
CREATE
OR replace PROCEDURE test_registrar_pedido IS v_contador INTEGER;

v_expected_error BOOLEAN;

BEGIN
  -- Caso 1: Pedido correcto, se realiza exitosamente
  BEGIN
    inicializa_test;

DBMS_OUTPUT.PUT_LINE(
  'Caso 1: Pedido correcto con primer y segundo plato'
);

registrar_pedido(1, 1, 1, 2);

-- Cliente 1, Personal 1, Plato 1 y 2 (disponibles)
-- Verificamos que el pedido se registró correctamente
SELECT
  COUNT(*) INTO v_contador
FROM
  pedidos
WHERE
  id_cliente = 1
  AND id_personal = 1;

IF v_contador = 1 THEN DBMS_OUTPUT.PUT_LINE('✓ ÉXITO: Pedido registrado correctamente');

ELSE DBMS_OUTPUT.PUT_LINE('✗ ERROR: No se registró el pedido');

END IF;

EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('✗ ERROR inesperado: ' || SQLERRM);

END;

-- Caso 2: Pedido correcto con solo primer plato
BEGIN
  inicializa_test;

DBMS_OUTPUT.PUT_LINE('Caso 2: Pedido correcto con solo primer plato');

registrar_pedido(1, 1, 1);

-- Cliente 1, Personal 1, Solo primer plato
-- Verificamos que el pedido se registró correctamente
SELECT
  COUNT(*) INTO v_contador
FROM
  pedidos
WHERE
  id_cliente = 1
  AND id_personal = 1;

IF v_contador = 1 THEN DBMS_OUTPUT.PUT_LINE(
  '✓ ÉXITO: Pedido con un solo plato registrado correctamente'
);

ELSE DBMS_OUTPUT.PUT_LINE(
  '✗ ERROR: No se registró el pedido con un solo plato'
);

END IF;

EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('✗ ERROR inesperado: ' || SQLERRM);

END;

-- Caso 3: Pedido correcto con solo segundo plato
BEGIN
  inicializa_test;

DBMS_OUTPUT.PUT_LINE('Caso 3: Pedido correcto con solo segundo plato');

registrar_pedido(1, 1, NULL, 2);

-- Cliente 1, Personal 1, Solo segundo plato
-- Verificamos que el pedido se registró correctamente
SELECT
  COUNT(*) INTO v_contador
FROM
  pedidos
WHERE
  id_cliente = 1
  AND id_personal = 1;

IF v_contador = 1 THEN DBMS_OUTPUT.PUT_LINE(
  '✓ ÉXITO: Pedido con solo segundo plato registrado correctamente'
);

ELSE DBMS_OUTPUT.PUT_LINE(
  '✗ ERROR: No se registró el pedido con solo segundo plato'
);

END IF;

EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('✗ ERROR inesperado: ' || SQLERRM);

END;

-- Caso 4: Pedido vacío (sin platos), debe devolver error -20002
BEGIN
  inicializa_test;

DBMS_OUTPUT.PUT_LINE('Caso 4: Pedido vacío (sin platos)');

v_expected_error := FALSE;

registrar_pedido(1, 1, NULL, NULL);

-- Sin platos
DBMS_OUTPUT.PUT_LINE(
  '✗ ERROR: No se lanzó excepción por pedido vacío'
);

EXCEPTION
  WHEN OTHERS THEN IF SQLCODE = -20002 THEN DBMS_OUTPUT.PUT_LINE(
    '✓ ÉXITO: Error correcto (-20002) por pedido vacío'
  );

ELSE DBMS_OUTPUT.PUT_LINE(
  '✗ ERROR: Se esperaba error -20002, pero se obtuvo: ' || SQLCODE || ' - ' || SQLERRM
);

END IF;

END;

-- Caso 5: Pedido con un plato que no existe, debe devolver error -20004
BEGIN
  inicializa_test;

DBMS_OUTPUT.PUT_LINE('Caso 5: Pedido con primer plato inexistente');

registrar_pedido(1, 1, 99);

-- Primer plato no existe
DBMS_OUTPUT.PUT_LINE(
  '✗ ERROR: No se lanzó excepción por plato inexistente'
);

EXCEPTION
  WHEN OTHERS THEN IF SQLCODE = -20004 THEN DBMS_OUTPUT.PUT_LINE(
    '✓ ÉXITO: Error correcto (-20004) por plato inexistente'
  );

ELSE DBMS_OUTPUT.PUT_LINE(
  '✗ ERROR: Se esperaba error -20004, pero se obtuvo: ' || SQLCODE || ' - ' || SQLERRM
);

END IF;

END;

-- Caso 6: Pedido con segundo plato inexistente, debe devolver error -20004
BEGIN
  inicializa_test;

DBMS_OUTPUT.PUT_LINE('Caso 6: Pedido con segundo plato inexistente');

registrar_pedido(1, 1, 1, 99);

-- Segundo plato no existe
DBMS_OUTPUT.PUT_LINE(
  '✗ ERROR: No se lanzó excepción por plato inexistente'
);

EXCEPTION
  WHEN OTHERS THEN IF SQLCODE = -20004 THEN DBMS_OUTPUT.PUT_LINE(
    '✓ ÉXITO: Error correcto (-20004) por plato inexistente'
  );

ELSE DBMS_OUTPUT.PUT_LINE(
  '✗ ERROR: Se esperaba error -20004, pero se obtuvo: ' || SQLCODE || ' - ' || SQLERRM
);

END IF;

END;

-- Caso 7: Pedido con plato no disponible, debe devolver error -20001
BEGIN
  inicializa_test;

DBMS_OUTPUT.PUT_LINE('Caso 7: Pedido con plato no disponible');

registrar_pedido(1, 1, 3);

-- Plato 3 no está disponible
DBMS_OUTPUT.PUT_LINE(
  '✗ ERROR: No se lanzó excepción por plato no disponible'
);

EXCEPTION
  WHEN OTHERS THEN IF SQLCODE = -20001 THEN DBMS_OUTPUT.PUT_LINE(
    '✓ ÉXITO: Error correcto (-20001) por plato no disponible'
  );

ELSE DBMS_OUTPUT.PUT_LINE(
  '✗ ERROR: Se esperaba error -20001, pero se obtuvo: ' || SQLCODE || ' - ' || SQLERRM
);

END IF;

END;

-- Caso 8: Personal con máximo de pedidos activos, debe devolver error -20003
BEGIN
  inicializa_test;

DBMS_OUTPUT.PUT_LINE('Caso 8: Personal con máximo de pedidos activos');

registrar_pedido(1, 2, 1);

-- Personal 2 ya tiene 5 pedidos activos
DBMS_OUTPUT.PUT_LINE(
  '✗ ERROR: No se lanzó excepción por personal con máximo de pedidos'
);

EXCEPTION
  WHEN OTHERS THEN IF SQLCODE = -20003 THEN DBMS_OUTPUT.PUT_LINE(
    '✓ ÉXITO: Error correcto (-20003) por personal con máximo de pedidos'
  );

ELSE DBMS_OUTPUT.PUT_LINE(
  '✗ ERROR: Se esperaba error -20003, pero se obtuvo: ' || SQLCODE || ' - ' || SQLERRM
);

END IF;

END;

-- Caso 9: Verificación de incremento en pedidos_activos del personal
BEGIN
  inicializa_test;

DBMS_OUTPUT.PUT_LINE(
  'Caso 9: Verificación de incremento en pedidos_activos'
);

-- Capturar valor inicial
SELECT
  pedidos_activos INTO v_contador
FROM
  personal_servicio
WHERE
  id_personal = 1;

-- Registrar pedido
registrar_pedido(1, 1, 1);

-- Verificar incremento
DECLARE
  v_nuevos_pedidos INTEGER;

BEGIN
  SELECT
    pedidos_activos INTO v_nuevos_pedidos
  FROM
    personal_servicio
  WHERE
    id_personal = 1;

IF v_nuevos_pedidos = v_contador + 1 THEN DBMS_OUTPUT.PUT_LINE(
  '✓ ÉXITO: El contador de pedidos_activos se incrementó correctamente'
);

ELSE DBMS_OUTPUT.PUT_LINE(
  '✗ ERROR: El contador de pedidos_activos no se incrementó correctamente'
);

END IF;

END;

EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('✗ ERROR inesperado: ' || SQLERRM);

END;

END;
/


set serveroutput on;
exec test_registrar_pedido;