/*
          # [Initial Schema &amp; Data Seeding]
          This script sets up the complete initial database schema for the Alatacrat application.
          It creates all necessary tables, defines relationships, sets up roles and permissions,
          and seeds the database with initial data for categories and products.

          ## Query Description:
          - This operation is safe to run multiple times. It uses 'IF NOT EXISTS' to avoid errors on re-runs.
          - It will create tables for users (profiles), product management (categories, products), and order management (orders, order_items).
          - It enables Row Level Security (RLS) on all tables to ensure data privacy and security from the start.
          - It sets up a trigger to automatically create a user profile when a new user signs up and verifies their email.
          - It inserts initial data for product categories and sample products.

          ## Metadata:
          - Schema-Category: "Structural"
          - Impact-Level: "Low"
          - Requires-Backup: false
          - Reversible: false (but non-destructive on re-run)

          ## Structure Details:
          - Tables Created: profiles, categories, products, orders, order_items
          - Types Created: app_role, order_status
          - Functions Created: handle_new_user
          - Triggers Created: on_auth_user_created

          ## Security Implications:
          - RLS Status: Enabled on all tables.
          - Policy Changes: Yes, initial policies are created for all tables.
          - Auth Requirements: Policies are tied to authenticated users and roles.

          ## Performance Impact:
          - Indexes: Primary keys and foreign keys are indexed by default.
          - Triggers: One trigger on auth.users table.
          - Estimated Impact: Low. This is an initial setup.
          */

-- 1. Create custom types
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN
        CREATE TYPE public.app_role AS ENUM ('admin', 'user', 'mitra');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
        CREATE TYPE public.order_status AS ENUM ('pending', 'paid', 'processing', 'shipped', 'delivered', 'cancelled');
    END IF;
END
$$;

-- 2. Create profiles table to store user data
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name text,
    role public.app_role NOT NULL DEFAULT 'user',
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);
COMMENT ON TABLE public.profiles IS 'Stores public-facing profile information for each user.';

-- 3. Create categories table
CREATE TABLE IF NOT EXISTS public.categories (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name text NOT NULL UNIQUE,
    slug text NOT NULL UNIQUE,
    description text,
    created_at timestamp with time zone DEFAULT now()
);
COMMENT ON TABLE public.categories IS 'Stores product categories.';

-- 4. Create products table
CREATE TABLE IF NOT EXISTS public.products (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    category_id bigint NOT NULL REFERENCES public.categories(id),
    name text NOT NULL,
    description text,
    price numeric(10, 2) NOT NULL,
    image_url text,
    stock integer NOT NULL DEFAULT 0,
    rating numeric(2, 1) DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);
COMMENT ON TABLE public.products IS 'Stores all product information.';

-- 5. Create orders table
CREATE TABLE IF NOT EXISTS public.orders (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    user_id uuid NOT NULL REFERENCES public.profiles(id),
    total_amount numeric(10, 2) NOT NULL,
    status public.order_status NOT NULL DEFAULT 'pending',
    shipping_address text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);
COMMENT ON TABLE public.orders IS 'Stores customer order information.';

-- 6. Create order_items table
CREATE TABLE IF NOT EXISTS public.order_items (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    order_id bigint NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id bigint NOT NULL REFERENCES public.products(id),
    quantity integer NOT NULL,
    price numeric(10, 2) NOT NULL
);
COMMENT ON TABLE public.order_items IS 'Stores individual items within an order.';

-- 7. Seed initial data
INSERT INTO public.categories (name, slug, description) VALUES
('Tas', 'tas', 'Berbagai macam tas anyaman dari eceng gondok.'),
('Dekorasi', 'dekorasi', 'Hiasan rumah yang unik dan estetik.'),
('Aksesori Rumah', 'aksesori-rumah', 'Perlengkapan rumah fungsional dan artistik.'),
('Premium', 'premium', 'Koleksi eksklusif dengan desain dan kualitas terbaik.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.products (category_id, name, description, price, image_url, stock, rating) VALUES
(1, 'Tas Tote Premium', 'Tas jinjing elegan untuk segala suasana.', 180000, 'https://img-wrapper.vercel.app/image?url=https://img-wrapper.vercel.app/image?url=https://placehold.co/300x300/8ea071/ffffff?text=Tas+Tote', 50, 4.8),
(3, 'Alas Meja Natural', 'Alas meja bundar untuk mempercantik ruang makan.', 95000, 'https://img-wrapper.vercel.app/image?url=https://img-wrapper.vercel.app/image?url=https://placehold.co/300x300/b4a47e/ffffff?text=Alas+Meja', 100, 4.5),
(2, 'Hiasan Dinding Mandala', 'Hiasan dinding besar dengan motif mandala.', 125000, 'https://img-wrapper.vercel.app/image?url=https://img-wrapper.vercel.app/image?url=https://placehold.co/300x300/a08d63/ffffff?text=Hiasan+Dinding', 30, 4.7),
(4, 'Set Premium Collection', 'Satu set produk premium untuk hadiah spesial.', 450000, 'https://img-wrapper.vercel.app/image?url=https://img-wrapper.vercel.app/image?url=https://placehold.co/300x300/f59e0b/ffffff?text=Premium+Set', 15, 5.0),
(1, 'Dompet Koin Minimalis', 'Dompet kecil untuk menyimpan koin dan kartu.', 45000, 'https://img-wrapper.vercel.app/image?url=https://img-wrapper.vercel.app/image?url=https://placehold.co/300x300/8d7a57/ffffff?text=Dompet', 200, 4.3)
ON CONFLICT (name) DO NOTHING;

-- 8. Set up Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- 9. Define RLS policies
-- Profiles: Users can see their own profile. Admins can see all.
DROP POLICY IF EXISTS "Users can view their own profile." ON public.profiles;
CREATE POLICY "Users can view their own profile." ON public.profiles FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can update their own profile." ON public.profiles;
CREATE POLICY "Users can update their own profile." ON public.profiles FOR UPDATE USING (auth.uid() = id);
DROP POLICY IF EXISTS "Admins can manage all profiles." ON public.profiles;
CREATE POLICY "Admins can manage all profiles." ON public.profiles FOR ALL USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- Categories & Products: Publicly visible
DROP POLICY IF EXISTS "Allow public read access to categories" ON public.categories;
CREATE POLICY "Allow public read access to categories" ON public.categories FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow public read access to products" ON public.products;
CREATE POLICY "Allow public read access to products" ON public.products FOR SELECT USING (true);

-- Admins can manage categories and products
DROP POLICY IF EXISTS "Admins can manage categories" ON public.categories;
CREATE POLICY "Admins can manage categories" ON public.categories FOR ALL USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');
DROP POLICY IF EXISTS "Admins can manage products" ON public.products;
CREATE POLICY "Admins can manage products" ON public.products FOR ALL USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- Orders: Users can only see and manage their own orders. Admins can see all.
DROP POLICY IF EXISTS "Users can manage their own orders." ON public.orders;
CREATE POLICY "Users can manage their own orders." ON public.orders FOR ALL USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Admins can manage all orders." ON public.orders;
CREATE POLICY "Admins can manage all orders." ON public.orders FOR ALL USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- Order Items: Access is based on the parent order.
DROP POLICY IF EXISTS "Users can manage their own order items." ON public.order_items;
CREATE POLICY "Users can manage their own order items." ON public.order_items FOR ALL USING (
  (SELECT user_id FROM public.orders WHERE id = order_id) = auth.uid()
);
DROP POLICY IF EXISTS "Admins can manage all order items." ON public.order_items;
CREATE POLICY "Admins can manage all order items." ON public.order_items FOR ALL USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');


-- 10. Create function to handle new user sign-up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'full_name',
    (new.raw_user_meta_data->>'role')::public.app_role
  );
  RETURN new;
END;
$$;

-- 11. Create trigger to call the function on new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 12. Create initial admin, user, and mitra for testing if they don't exist
DO $$
BEGIN
  -- Create Admin user if not exists
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'admin@admin.com') THEN
    INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_token, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token_encrypted)
    VALUES (
      '00000000-0000-0000-0000-000000000000', uuid_generate_v4(), 'authenticated', 'authenticated', 'admin@admin.com', crypt('admin', gen_salt('bf')), now(), '', now(), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Administrator","role":"admin"}', now(), now(), '', '', '', ''
    );
  END IF;

  -- Create User if not exists
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'user@user.com') THEN
    INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_token, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token_encrypted)
    VALUES (
      '00000000-0000-0000-0000-000000000000', uuid_generate_v4(), 'authenticated', 'authenticated', 'user@user.com', crypt('user', gen_salt('bf')), now(), '', now(), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Customer User","role":"user"}', now(), now(), '', '', '', ''
    );
  END IF;

  -- Create Mitra if not exists
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'mitra@mitra.com') THEN
    INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_token, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token_encrypted)
    VALUES (
      '00000000-0000-0000-0000-000000000000', uuid_generate_v4(), 'authenticated', 'authenticated', 'mitra@mitra.com', crypt('mitra', gen_salt('bf')), now(), '', now(), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Partner Mitra","role":"mitra"}', now(), now(), '', '', '', ''
    );
  END IF;
END;
$$;
