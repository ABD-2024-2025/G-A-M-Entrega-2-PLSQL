create or replace procedure registrar_pedido(
    arg_id_cliente      INTEGER, 
    arg_id_personal     INTEGER, 
    arg_id_primer_plato INTEGER DEFAULT NULL,
    arg_id_segundo_plato INTEGER DEFAULT NULL
) is 

    Pedido_no_valido exception;
    pragma exception_init(Pedido_no_valido, -20002);
    msg_pedido_no_valido constant varchar(50) := 'El pedido debe contener al menos un plato.';
    
    Plato_no_disponible exception;
    pragma exception_init(Plato_no_disponible, -20001);
    msg_plato_no_disponible constant varchar(50) := 'Uno de los platos seleccionados no está disponible.';

    Plato_inexistente exception;
    pragma exception_init(Plato_inexistente, -20004);
    msg_primero_inexistente constant varchar(50) := '‘El primer plato seleccionado no existe.';
    msg_segundo_inexistente constant varchar(50) := '‘El segundo plato seleccionado no existe.';

    Personal_ocupado exception;
    pragma exception_init(Personal_ocupado, -20003);
    msg_personal_ocupado constant varchar(50) := 'El personal de servicio tiene demasiados pedidos.';
  
  total_coste INTEGER;

 begin
  
  if arg_id_primer_plato = NULL and arg_id_segundo_plato = NULL then
    raise_application_error(-20002, msg_pedido_no_valido);
  end if;

  total_coste = 0;

  if arg_id_primer_plato != NULL then
    select disponible into primero from platos where id_plato = arg_id_primer_plato;
    if SQL%NOTFOUND then
      raise_application_error(-20004, msg_primero_inexistente);
    end if;
    if !primero then
      raise_application_error(-20001, msg_plato_no_disponible);
    end if;
    total_coste += select precio from platos where id_plato = arg_id_primer_plato;
  end if;

  if arg_id_segundo_plato != NULL then
    select disponible into segundo from platos where id_plato = arg_id_segundo_plato;
    if SQL%NOTFOUND then
      raise_application_error(-20004, msg_segundo_inexistente);
    end if;
    if !segundo then
      raise_application_error(-20001, msg_plato_no_disponible);
    end if;
    total_coste += select precio from platos where id_plato = arg_id_segundo_plato;
  end if;

  if select pedidos_activos from personal_servicio where id_personal = arg_id_personal >= 5 then
    raise_application_error(-20003, msg_personal_ocupado);

  insert into pedidos 
    values (seq_pedidos.nextval, arg_id_cliente, arg_id_personal, CURRENT_DATE, total_coste);

  if arg_id_primer_plato != NULL and arg_id_segundo_plato != NULL then
    insert into detalle_pedido
      values(seq_pedidos.currval, arg_id_primer_plato, 1);
    insert into detalle_pedido
      values(seq_pedidos.currval, arg_id_segundo_plato, 1);
  end if;

  update personal_servicio set pedidos_activos += 1 where id_personal = arg_id_personal;

end;