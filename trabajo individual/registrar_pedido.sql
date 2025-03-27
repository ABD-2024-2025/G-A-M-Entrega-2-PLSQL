CREATE
OR replace PROCEDURE registrar_pedido(
	arg_id_cliente INTEGER,
	arg_id_personal INTEGER,
	arg_id_primer_plato INTEGER DEFAULT NULL,
	arg_id_segundo_plato INTEGER DEFAULT NULL
) IS Pedido_no_valido
EXCEPTION
;

PRAGMA exception_init(Pedido_no_valido, -20002);

msg_pedido_no_valido CONSTANT VARCHAR2(200) := 'El pedido debe contener al menos un plato.';

Plato_no_disponible
EXCEPTION
;

PRAGMA exception_init(Plato_no_disponible, -20001);

msg_plato_no_disponible CONSTANT VARCHAR2(200) := 'Uno de los platos seleccionados no está disponible.';

Plato_inexistente
EXCEPTION
;

PRAGMA exception_init(Plato_inexistente, -20004);

msg_primero_inexistente CONSTANT VARCHAR2(200) := 'El primer plato seleccionado no existe.';

msg_segundo_inexistente CONSTANT VARCHAR2(200) := 'El segundo plato seleccionado no existe.';

Personal_ocupado
EXCEPTION
;

PRAGMA exception_init(Personal_ocupado, -20003);

msg_personal_ocupado CONSTANT VARCHAR2(200) := 'El personal de servicio tiene demasiados pedidos.';

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
UPDATE
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

-- Re-lanzar la excepción para que el cliente sepa qué ocurrió
RAISE;

END;