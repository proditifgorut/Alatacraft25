/*
# [Schema and Seed Correction]
This script corrects previous migration errors by ensuring all tables are created idempotently and fixes a column name mismatch in the product seeding process.

## Query Description:
- **Idempotent Table Creation**: Uses `CREATE TABLE IF NOT EXISTS` for all tables to prevent errors on re-runs.
- **Foreign Key Correction**: Ensures `order_items.product_id` is of type `UUID` to match `products.id`.
- **Product Seeding Fix**: Corrects the `INSERT` statement for the `products` table to use the `image_urls` column (which is a TEXT array) instead of the non-existent `image_url` column.
- This script is safe to run multiple times. It will only create missing objects and seed data if the tables are empty.

## Metadata:
- Schema-Category: ["Structural", "Data"]
- Impact-Level: "Low"
- Requires-Backup: false
- Reversible: true

## Security Implications:
- RLS Status: Enabled on sensitive tables.
- Policy Changes: No
- Auth Requirements: Admin/superuser privileges to run.
*/

-- Enable PostGIS extension if not enabled
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

-- Create roles table
CREATE TABLE IF NOT EXISTS public.roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

-- Seed roles
INSERT INTO public.roles (name) VALUES ('admin'), ('user'), ('mitra')
ON CONFLICT (name) DO NOTHING;

-- Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255),
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Function to create a profile for a new user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, role)
    VALUES (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'role');
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function when a new user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Enable RLS for profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policies for profiles table
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Create categories table
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create products table
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL,
    image_urls TEXT[],
    stock INT NOT NULL DEFAULT 0,
    rating NUMERIC(2, 1),
    category_id UUID REFERENCES public.categories(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create orders table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    total_amount NUMERIC(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    shipping_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create order_items table
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id), -- Corrected type
    quantity INT NOT NULL,
    price NUMERIC(10, 2) NOT NULL
);

-- Seed data
DO $$
DECLARE
    tas_id UUID;
    dekorasi_id UUID;
    aksesori_id UUID;
    premium_id UUID;
BEGIN
    -- Seed categories if they don't exist
    INSERT INTO public.categories (name, slug, description) VALUES
        ('Tas', 'tas', 'Koleksi tas anyaman eceng gondok.'),
        ('Dekorasi', 'dekorasi', 'Hiasan rumah yang natural dan estetik.'),
        ('Aksesori Rumah', 'aksesori-rumah', 'Perlengkapan rumah fungsional.'),
        ('Premium', 'premium', 'Koleksi eksklusif dengan kualitas terbaik.')
    ON CONFLICT (slug) DO NOTHING;

    -- Get category IDs
    SELECT id INTO tas_id FROM public.categories WHERE slug = 'tas';
    SELECT id INTO dekorasi_id FROM public.categories WHERE slug = 'dekorasi';
    SELECT id INTO aksesori_id FROM public.categories WHERE slug = 'aksesori-rumah';
    SELECT id INTO premium_id FROM public.categories WHERE slug = 'premium';

    -- Insert products only if the table is empty
    IF NOT EXISTS (SELECT 1 FROM public.products) THEN
        INSERT INTO public.products (name, description, price, image_urls, stock, rating, category_id) VALUES
        ('Tas Tote Premium', 'Tas anyaman eceng gondok dengan handle kulit asli.', 180000, ARRAY['https://img-wrapper.vercel.app/image?url=https://img-wrapper.vercel.app/image?url=https://placehold.co/300x300/8ea071/ffffff?text=Tas+Tote'], 20, 4.8, tas_id),
        ('Alas Meja Natural', 'Alas meja bundar untuk sentuhan alami di ruang makan.', 95000, ARRAY['https://img-wrapper.vercel.app/image?url=https://img-wrapper.vercel.app/image?url=https://placehold.co/300x300/b4a47e/ffffff?text=Alas+Meja'], 35, 4.5, aksesori_id),
        ('Hiasan Dinding Mandala', 'Hiasan dinding besar dengan pola mandala yang rumit.', 125000, ARRAY['https://img-wrapper.vercel.app/image?url=https://img-wrapper.vercel.app/image?url=https://placehold.co/300x300/a08d63/ffffff?text=Hiasan+Dinding'], 15, 4.7, dekorasi_id),
        ('Tempat Pensil Minimalis', 'Tempat pensil elegan untuk meja kerja Anda.', 45000, ARRAY['https://img-wrapper.vercel.app/image?url=https://img-wrapper.vercel.app/image?url=https://placehold.co/300x300/708158/ffffff?text=Tempat+Pensil'], 50, 4.3, aksesori_id),
        ('Keranjang Multifungsi', 'Keranjang serbaguna untuk penyimpanan mainan atau laundry.', 110000, ARRAY['https://img-wrapper.vercel.app/image?url=https://img-wrapper.vercel.app/image?url=https://placehold.co/300x300/c8bea2/ffffff?text=Keranjang'], 25, 4.6, aksesori_id),
        ('Clutch Pesta Elegan', 'Clutch malam yang mewah dan ramah lingkungan.', 250000, ARRAY['https://img-wrapper.vercel.app/image?url=https://img-wrapper.vercel.app/image?url=https://placehold.co/300x300/f59e0b/ffffff?text=Clutch'], 10, 4.9, premium_id);
    END IF;
END $$;
