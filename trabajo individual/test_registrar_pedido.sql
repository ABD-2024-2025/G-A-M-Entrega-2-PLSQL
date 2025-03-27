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