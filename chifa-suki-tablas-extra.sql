-- ============================================================
-- CHIFA SUKI — Tablas adicionales v2
-- Ejecuta en: Supabase → SQL Editor → New query → Run
-- ============================================================

-- 1. Usuarios del sistema (reemplaza los usuarios locales)
CREATE TABLE IF NOT EXISTS public.usuarios_pos (
  id      serial  primary key,
  nombre  text    not null,
  usuario text    unique not null,
  password text   not null,
  rol     text    not null default 'mozo' check (rol in ('admin','cajero','mozo')),
  activo  boolean not null default true,
  created_at timestamptz not null default now()
);
INSERT INTO public.usuarios_pos (nombre,usuario,password,rol) VALUES
  ('Admin','admin','1234','admin'),
  ('Cajero 1','cajero','1234','cajero')
ON CONFLICT (usuario) DO NOTHING;

-- 2. Jornadas del día (máximo 2 por día)
CREATE TABLE IF NOT EXISTS public.jornadas_dia (
  id           serial  primary key,
  numero       int     not null check (numero in (1,2)),
  fecha        date    not null default current_date,
  caja_inicial numeric(10,2) not null default 0,
  total_ventas numeric(10,2) default 0,
  total_efectivo numeric(10,2) default 0,
  total_yape   numeric(10,2) default 0,
  total_tarjeta numeric(10,2) default 0,
  total_mixto  numeric(10,2) default 0,
  num_pedidos  int     default 0,
  estado       text    not null default 'abierta' check (estado in ('abierta','cerrada')),
  apertura_at  timestamptz not null default now(),
  cierre_at    timestamptz,
  abierta_por  text,
  cerrada_por  text,
  UNIQUE(numero, fecha)
);

-- 3. Turnos del personal (Mi turno)
CREATE TABLE IF NOT EXISTS public.turnos_personal (
  id           serial  primary key,
  usuario_id   int     references public.usuarios_pos(id),
  nombre_usuario text  not null,
  rol          text,
  fecha        date    not null default current_date,
  jornada      int     not null default 1,
  entrada_at   timestamptz not null default now(),
  salida_at    timestamptz,
  notas        text
);

-- 4. Inventario - Items
CREATE TABLE IF NOT EXISTS public.inventario_items (
  id           serial  primary key,
  nombre       text    not null,
  categoria    text,
  unidad       text    not null default 'unid',
  stock_actual numeric(10,3) not null default 0,
  stock_minimo numeric(10,3) not null default 0,
  activo       boolean not null default true,
  created_at   timestamptz not null default now()
);

-- 5. Inventario - Movimientos
CREATE TABLE IF NOT EXISTS public.inventario_movimientos (
  id           serial  primary key,
  item_id      int     not null references public.inventario_items(id) on delete cascade,
  tipo         text    not null check (tipo in ('entrada','salida','ajuste')),
  cantidad     numeric(10,3) not null,
  stock_antes  numeric(10,3),
  stock_despues numeric(10,3),
  motivo       text,
  nombre_usuario text,
  created_at   timestamptz not null default now()
);

-- 6. Agregar columna jornada_num a pedidos
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS jornada_num int not null default 1;

-- 7. RLS policies
ALTER TABLE public.usuarios_pos        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jornadas_dia        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.turnos_personal     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventario_items    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventario_movimientos ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='usuarios_pos'             AND policyname='public_all') THEN CREATE POLICY "public_all" ON public.usuarios_pos FOR ALL USING (true) WITH CHECK (true); END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='jornadas_dia'             AND policyname='public_all') THEN CREATE POLICY "public_all" ON public.jornadas_dia FOR ALL USING (true) WITH CHECK (true); END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='turnos_personal'          AND policyname='public_all') THEN CREATE POLICY "public_all" ON public.turnos_personal FOR ALL USING (true) WITH CHECK (true); END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='inventario_items'         AND policyname='public_all') THEN CREATE POLICY "public_all" ON public.inventario_items FOR ALL USING (true) WITH CHECK (true); END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='inventario_movimientos'   AND policyname='public_all') THEN CREATE POLICY "public_all" ON public.inventario_movimientos FOR ALL USING (true) WITH CHECK (true); END IF;
END $$;

ALTER PUBLICATION supabase_realtime ADD TABLE public.turnos_personal;
ALTER PUBLICATION supabase_realtime ADD TABLE public.jornadas_dia;

-- 8. Inventario inicial de ejemplo
INSERT INTO public.inventario_items (nombre,categoria,unidad,stock_actual,stock_minimo) VALUES
  ('Arroz','Abarrotes','kg',50,10),
  ('Aceite','Abarrotes','lt',20,5),
  ('Salsa de soya','Condimentos','lt',10,2),
  ('Salsa de ostión','Condimentos','kg',5,1),
  ('Pollo entero','Carnes','kg',30,5),
  ('Cerdo','Carnes','kg',20,5),
  ('Pato','Carnes','unid',10,2),
  ('Fideos chinos','Abarrotes','kg',15,3),
  ('Wantanes (masa)','Insumos','paq',20,5),
  ('Verduras mixtas','Frescos','kg',10,2),
  ('Chicha morada (concentrado)','Bebidas','lt',10,2),
  ('Gas','Servicios','bal',2,1)
ON CONFLICT DO NOTHING;
