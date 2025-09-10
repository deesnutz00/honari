-- =====================================================
-- COMPLETE SCHEMA FOR HONARI BOOK APP
-- =====================================================

-- Create public schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS public;

-- Set search path to public
SET search_path TO public;

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. AUTHENTICATION TABLES (auto-created by Supabase)
-- =====================================================

-- Note: auth.users table is automatically created by Supabase
-- You don't need to create this manually

-- =====================================================
-- 2. USER PROFILES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE,
  bio TEXT,
  avatar_url TEXT,
  books_shared INTEGER DEFAULT 0,
  favorites_count INTEGER DEFAULT 0,
  following_count INTEGER DEFAULT 0,
  followers_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 3. BOOKS TABLE (PUBLIC ACCESS)
-- =====================================================

CREATE TABLE IF NOT EXISTS books (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  description TEXT DEFAULT '',
  genre TEXT DEFAULT '',
  cover_url TEXT,
  first_page_url TEXT,
  book_file_url TEXT,
  book_file_path TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 4. USER FAVORITES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS user_favorites (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, book_id)
);

-- =====================================================
-- 5. USER FOLLOWS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS user_follows (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  follower_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK(follower_id != following_id)
);

-- =====================================================
-- 6. POSTS TABLE (SOCIAL FEATURES)
-- =====================================================

CREATE TABLE IF NOT EXISTS posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id UUID REFERENCES books(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  post_type TEXT DEFAULT 'review',
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  -- Note: Foreign key to user_profiles will be added after ensuring all users have profiles
  -- CONSTRAINT fk_posts_user_profiles FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE
);

-- =====================================================
-- 7. POST LIKES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS post_likes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- =====================================================
-- 8. POST COMMENTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS post_comments (
   id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
   post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
   user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
   content TEXT NOT NULL,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
   updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 9. BOOK LIKES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS book_likes (
   id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
   book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
   user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
   UNIQUE(book_id, user_id)
);

-- =====================================================
-- 9. READING PROGRESS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS reading_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  current_page INTEGER DEFAULT 1,
  total_pages INTEGER,
  progress_percentage DECIMAL(5,2) DEFAULT 0.0,
  last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, book_id)
);

-- =====================================================
-- 10. ACHIEVEMENTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS achievements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  icon_url TEXT,
  points INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 11. USER ACHIEVEMENTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS user_achievements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_id UUID REFERENCES achievements(id) ON DELETE CASCADE,
  earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

-- =====================================================
-- 12. QUOTES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS quotes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  content TEXT NOT NULL,
  author TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 13. NOTIFICATIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info',
  is_read BOOLEAN DEFAULT FALSE,
  related_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_books_user_id ON books(user_id);
CREATE INDEX IF NOT EXISTS idx_books_created_at ON books(created_at);
CREATE INDEX IF NOT EXISTS idx_books_genre ON books(genre);
CREATE INDEX IF NOT EXISTS idx_books_title_author ON books(title, author);

CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON user_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_book_id ON user_favorites(book_id);

CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_book_id ON posts(book_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at);

CREATE INDEX IF NOT EXISTS idx_books_search ON books USING gin(to_tsvector('english', title || ' ' || author || ' ' || COALESCE(description, '')));

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- BOOKS POLICIES (PUBLIC ACCESS)
-- =====================================================

-- DROP existing policies to avoid conflicts
DROP POLICY IF EXISTS "All users can view all books" ON books;
DROP POLICY IF EXISTS "Users can insert their own books" ON books;
DROP POLICY IF EXISTS "Users can update their own books" ON books;
DROP POLICY IF EXISTS "Only uploader can delete their own books" ON books;

-- ALL users (including anonymous) can VIEW all books
CREATE POLICY "All users can view all books" ON books
  FOR SELECT USING (true);

-- Authenticated users can INSERT their own books
CREATE POLICY "Users can insert their own books" ON books
  FOR INSERT WITH CHECK (auth.uid() = user_id AND auth.uid() IS NOT NULL);

-- Users can UPDATE their own books
CREATE POLICY "Users can update their own books" ON books
  FOR UPDATE USING (auth.uid() = user_id);

-- ONLY the uploader can DELETE their own books
CREATE POLICY "Only uploader can delete their own books" ON books
  FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- USER PROFILES POLICIES
-- =====================================================

-- Temporarily disable RLS for debugging
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;

-- Re-enable with proper policies after debugging
-- CREATE POLICY "All users can view all profiles" ON user_profiles
--   FOR SELECT USING (true);
--
-- CREATE POLICY "Users can update their own profile" ON user_profiles
--   FOR UPDATE USING (auth.uid() = id);
--
-- CREATE POLICY "Users can insert their own profile" ON user_profiles
--   FOR INSERT WITH CHECK (
--     auth.uid() = id OR
--     auth.role() = 'service_role' OR
--     auth.uid() IS NULL
--   );

-- =====================================================
-- USER FAVORITES POLICIES
-- =====================================================

CREATE POLICY "Users can manage their own favorites" ON user_favorites
  FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- USER FOLLOWS POLICIES
-- =====================================================

CREATE POLICY "Users can manage their own follows" ON user_follows
  FOR ALL USING (auth.uid() = follower_id OR auth.uid() = following_id);

-- =====================================================
-- POSTS POLICIES
-- =====================================================

-- Temporarily disable RLS for debugging
ALTER TABLE posts DISABLE ROW LEVEL SECURITY;

-- Re-enable with proper policies after debugging
-- CREATE POLICY "All users can view all posts" ON posts
--   FOR SELECT USING (true);
--
-- CREATE POLICY "Users can create their own posts" ON posts
--   FOR INSERT WITH CHECK (auth.uid() = user_id);
--
-- CREATE POLICY "Users can update their own posts" ON posts
--   FOR UPDATE USING (auth.uid() = user_id);
--
-- CREATE POLICY "Users can delete their own posts" ON posts
--   FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- OTHER TABLE POLICIES
-- =====================================================

CREATE POLICY "Users can manage their own likes" ON post_likes
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "All users can view all comments" ON post_comments
  FOR SELECT USING (true);

CREATE POLICY "Users can manage their own comments" ON post_comments
   FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own book likes" ON book_likes
   FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own reading progress" ON reading_progress
   FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own notifications" ON notifications
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own achievements" ON user_achievements
  FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- QUOTES POLICIES
-- =====================================================

CREATE POLICY "All users can view active quotes" ON quotes
  FOR SELECT USING (is_active = true);

CREATE POLICY "Only authenticated users can manage quotes" ON quotes
  FOR ALL USING (auth.role() = 'authenticated');

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;

GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

GRANT SELECT, INSERT ON TABLE user_profiles TO anon;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon;

GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO service_role;

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_books_updated_at BEFORE UPDATE ON books
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_post_comments_updated_at BEFORE UPDATE ON post_comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_book_likes_updated_at BEFORE UPDATE ON book_likes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reading_progress_updated_at BEFORE UPDATE ON reading_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quotes_updated_at BEFORE UPDATE ON quotes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- USER PROFILE CREATION TRIGGER
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_profiles (id, username)
  VALUES (new.id, COALESCE(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'username', 'User'));
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- ENSURE EXISTING USERS HAVE PROFILES
-- =====================================================

-- Create profiles for any existing users who don't have them
INSERT INTO public.user_profiles (id, username)
SELECT
  au.id,
  COALESCE(au.raw_user_meta_data->>'name', au.raw_user_meta_data->>'username', 'User')
FROM auth.users au
LEFT JOIN public.user_profiles up ON au.id = up.id
WHERE up.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- MANUAL PROFILE CREATION (if needed)
-- =====================================================

-- If user profiles are still missing, run this manually:
INSERT INTO public.user_profiles (id, username)
SELECT id, 'User' FROM auth.users
WHERE id NOT IN (SELECT id FROM public.user_profiles)
ON CONFLICT (id) DO NOTHING;

-- CREATE TEST POST (if needed for debugging)
-- Replace 'your-user-id-here' with an actual user ID from auth.users
-- INSERT INTO posts (user_id, content, post_type)
-- VALUES ('your-user-id-here', 'Test post from database', 'review');

-- =====================================================
-- FORCE CREATE USER PROFILES FOR ALL USERS
-- =====================================================

-- This will ensure ALL users have profiles, even if trigger failed
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN SELECT id FROM auth.users LOOP
        INSERT INTO public.user_profiles (id, username)
        VALUES (user_record.id, 'User')
        ON CONFLICT (id) DO NOTHING;
    END LOOP;
END $$;

-- =====================================================
-- CREATE TEST POST FOR FIRST USER
-- =====================================================

-- Create a test post for the first user found
DO $$
DECLARE
    first_user_id UUID;
BEGIN
    SELECT id INTO first_user_id FROM auth.users LIMIT 1;
    IF first_user_id IS NOT NULL THEN
        INSERT INTO posts (user_id, content, post_type)
        VALUES (first_user_id, 'Welcome to Honari! This is a test post to verify the social features are working.', 'review')
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- =====================================================
-- DEBUG FUNCTION (TEMPORARY)
-- =====================================================

-- Function to check books without RLS restrictions (for debugging)
CREATE OR REPLACE FUNCTION public.get_all_books_debug()
RETURNS TABLE(id UUID, title TEXT, author TEXT, user_id UUID) AS $$
BEGIN
  RETURN QUERY SELECT b.id, b.title, b.author, b.user_id FROM books b;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check user profiles and posts (for debugging)
CREATE OR REPLACE FUNCTION public.debug_social_data()
RETURNS TABLE(
  user_id UUID,
  username TEXT,
  posts_count BIGINT,
  has_profile BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    au.id as user_id,
    up.username,
    COUNT(p.id) as posts_count,
    CASE WHEN up.id IS NOT NULL THEN true ELSE false END as has_profile
  FROM auth.users au
  LEFT JOIN public.user_profiles up ON au.id = up.id
  LEFT JOIN public.posts p ON au.id = p.user_id
  GROUP BY au.id, up.username, up.id
  ORDER BY au.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SAMPLE DATA
-- =====================================================

-- Insert sample achievements
INSERT INTO achievements (name, description, points) VALUES
('First Book', 'Upload your first book', 10),
('Bookworm', 'Upload 10 books', 50),
('Social Butterfly', 'Get 10 followers', 25),
('Reviewer', 'Write 5 book reviews', 30)
ON CONFLICT DO NOTHING;

-- Insert sample quotes
INSERT INTO quotes (content, author) VALUES
('The more that you read, the more things you will know. The more that you learn, the more places you''ll go.', 'Dr. Seuss'),
('A reader lives a thousand lives before he dies. The man who never reads lives only one.', 'George R.R. Martin'),
('Books are a uniquely portable magic.', 'Stephen King'),
('Reading is a discount ticket to everywhere.', 'Mary Schmich'),
('There is no friend as loyal as a book.', 'Ernest Hemingway'),
('Books are mirrors: you only see in them what you already have inside you.', 'Carlos Ruiz Zafón'),
('Reading gives us someplace to go when we have to stay where we are.', 'Mason Cooley'),
('A book is a dream that you hold in your hand.', 'Neil Gaiman'),
('The world was hers for the reading.', 'Betty Smith'),
('Reading is an exercise in empathy; an exercise in walking in someone else''s shoes for a while.', 'Malorie Blackman'),
('Books are the quietest and most constant of friends; they are the most accessible and wisest of counselors, and the most patient of teachers.', 'Charles W. Eliot'),
('Reading is to the mind what exercise is to the body.', 'Joseph Addison'),
('A great book should leave you with many experiences, and slightly exhausted at the end. You live several lives while reading.', 'William Styron'),
('Books serve to show a man that those original thoughts of his aren''t very new after all.', 'Abraham Lincoln'),
('The reading of all good books is like conversation with the finest men of past centuries.', 'René Descartes')
ON CONFLICT DO NOTHING;

-- Sample books cannot be pre-inserted due to foreign key constraints
-- Users should upload their own books through the app
-- The RLS policies ensure all uploaded books are visible to all users

-- =====================================================
-- SCHEMA COMPLETE! 🎉
-- =====================================================

-- IMPORTANT NOTES:
-- 1. All books are PUBLIC - anyone can view them
-- 2. Only the uploader can DELETE their own books
-- 3. Users can favorite any public book
-- 4. Social features work with proper user permissions
-- 5. Reading progress is private to each user
-- 6. Quotes are PUBLIC - anyone can view active quotes
--
-- DEBUG MODE:
-- - RLS temporarily disabled for posts and user_profiles
-- - App now uses manual joins to avoid PostgREST relationship issues
-- - Re-enable RLS after debugging is complete
--
-- FOREIGN KEY CONSTRAINTS:
-- - All foreign keys use CASCADE for user deletions
-- - Book references use SET NULL to preserve posts when books are deleted
-- - NOT NULL constraints ensure data integrity
-- - Use LEFT JOIN in queries when user_profiles might not exist
--
-- SAMPLE DATA INCLUDED:
-- - Achievement system with sample achievements
-- - Quotes system with 15 inspirational book-related quotes
-- - Debug function for troubleshooting RLS issues
-- - No sample books (users must upload their own)
--
-- TESTING BOOKS DISPLAY:
-- 1. Run this schema in Supabase SQL Editor (no errors)
-- 2. Sign up/Login to create a user account
-- 3. Upload a book through the Upload screen
-- 4. Books should appear in dashboard for all users
-- 5. Quotes should appear randomly in the daily quote section
-- 6. If issues, check logs for "BookService: Current user"
-- 7. Debug with: SELECT * FROM get_all_books_debug();
--
-- TROUBLESHOOTING:
-- - Check Supabase authentication status
-- - Verify RLS policies are correct
-- - Look for "BookService: Current user" in app logs
-- - Check user profiles: SELECT * FROM debug_social_data();
-- - Use debug functions: SELECT * FROM get_all_books_debug();
-- - Verify posts exist: SELECT * FROM posts LIMIT 5;
-- - Check quotes: SELECT * FROM quotes WHERE is_active = true;