/*
          # [Operation Name] Enable Row Level Security (RLS) and Define Policies
          [This script secures the database by enabling RLS on all public tables and creating specific access policies for different user roles (users, admins) and actions (SELECT, INSERT, UPDATE, DELETE).]

          ## Query Description: [This operation is a critical security enhancement. It restricts data access based on user authentication and roles. For example, users will only be ableto view their own orders, and only admins will be able to modify products. This prevents unauthorized data access and modification. No data will be lost, but access will become more restrictive as intended.]
          
          ## Metadata:
          - Schema-Category: ["Structural", "Security"]
          - Impact-Level: ["High"]
          - Requires-Backup: [false]
          - Reversible: [true]
          
          ## Structure Details:
          - Tables affected: profiles, categories, products, orders, order_items, reviews
          - Operations: ALTER TABLE ... ENABLE ROW LEVEL SECURITY, CREATE POLICY
          
          ## Security Implications:
          - RLS Status: [Enabled]
          - Policy Changes: [Yes]
          - Auth Requirements: [Policies are based on auth.uid() and user roles from the 'profiles' table.]
          
          ## Performance Impact:
          - Indexes: [No changes]
          - Triggers: [No changes]
          - Estimated Impact: [Slight overhead on queries due to policy checks, which is necessary for security. The impact is generally minimal with proper indexing.]
          */

-- Step 1: Enable Row Level Security (RLS) on all public tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies to ensure a clean slate and make the script re-runnable.
DROP POLICY IF EXISTS "Public can view all categories." ON public.categories;
DROP POLICY IF EXISTS "Admins can manage categories." ON public.categories;
DROP POLICY IF EXISTS "Public can view all products." ON public.products;
DROP POLICY IF EXISTS "Admins can manage products." ON public.products;
DROP POLICY IF EXISTS "Users can view their own profile." ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile." ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own orders." ON public.orders;
DROP POLICY IF EXISTS "Users can create new orders." ON public.orders;
DROP POLICY IF EXISTS "Admins can manage all orders." ON public.orders;
DROP POLICY IF EXISTS "Users can view their own order items." ON public.order_items;
DROP POLICY IF EXISTS "Users can create new order items." ON public.order_items;
DROP POLICY IF EXISTS "Admins can manage all order items." ON public.order_items;
DROP POLICY IF EXISTS "Public can view all reviews." ON public.reviews;
DROP POLICY IF EXISTS "Users can create reviews." ON public.reviews;
DROP POLICY IF EXISTS "Users can manage their own reviews." ON public.reviews;
DROP POLICY IF EXISTS "Users can delete their own reviews." ON public.reviews;
DROP POLICY IF EXISTS "Admins can manage all reviews." ON public.reviews;

-- Step 3: Create policies for each table

-- Table: profiles
-- Users can see and modify their own profile data.
CREATE POLICY "Users can view their own profile." ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile." ON public.profiles
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Table: categories
-- Anyone can read categories, but only admins can modify them.
CREATE POLICY "Public can view all categories." ON public.categories
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage categories." ON public.categories
  FOR ALL USING ((EXISTS ( SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin' )))
  WITH CHECK ((EXISTS ( SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin' )));

-- Table: products
-- Anyone can read products, but only admins can modify them.
CREATE POLICY "Public can view all products." ON public.products
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage products." ON public.products
  FOR ALL USING ((EXISTS ( SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin' )))
  WITH CHECK ((EXISTS ( SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin' )));

-- Table: orders
-- Users can only see and create their own orders. Admins can see all.
CREATE POLICY "Users can view their own orders." ON public.orders
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create new orders." ON public.orders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can manage all orders." ON public.orders
  FOR ALL USING ((EXISTS ( SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin' )));

-- Table: order_items
-- Logic mirrors the 'orders' table.
CREATE POLICY "Users can view their own order items." ON public.order_items
  FOR SELECT USING ((EXISTS ( SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid() )));

CREATE POLICY "Users can create new order items." ON public.order_items
  FOR INSERT WITH CHECK ((EXISTS ( SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid() )));

CREATE POLICY "Admins can manage all order items." ON public.order_items
  FOR ALL USING ((EXISTS ( SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin' )));

-- Table: reviews
-- Anyone can read reviews. Authenticated users can create them. Users can only manage their own reviews. Admins can manage all.
CREATE POLICY "Public can view all reviews." ON public.reviews
  FOR SELECT USING (true);

CREATE POLICY "Users can create reviews." ON public.reviews
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own reviews." ON public.reviews
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reviews." ON public.reviews
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all reviews." ON public.reviews
  FOR ALL USING ((EXISTS ( SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin' )));
