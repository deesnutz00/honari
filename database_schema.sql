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
-- 1. AUTHENTICATION TABLES (usually auto-created)
-- =====================================================

-- Note: auth.users table is automatically created by Supabase
-- You don't need to create this manually

-- =====================================================
-- 2. BOOKS TABLE
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

-- Ensure description column exists (for existing tables)
ALTER TABLE books ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';
ALTER TABLE books ADD COLUMN IF NOT EXISTS first_page_url TEXT;
ALTER TABLE books ADD COLUMN IF NOT EXISTS book_file_url TEXT;
ALTER TABLE books ADD COLUMN IF NOT EXISTS book_file_path TEXT;

-- =====================================================
-- 3. USER FAVORITES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS user_favorites (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, book_id)
);

-- =====================================================
-- 4. USER PROFILES TABLE
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
-- 6. POSTS TABLE (for social features)
-- =====================================================

CREATE TABLE IF NOT EXISTS posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id UUID REFERENCES books(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  post_type TEXT DEFAULT 'review', -- 'review', 'currently_reading', 'finished_reading'
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 7. POST LIKES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS post_likes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- =====================================================
-- 8. POST COMMENTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS post_comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 9. NOTIFICATIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info', -- 'info', 'like', 'comment', 'follow'
  is_read BOOLEAN DEFAULT FALSE,
  related_id UUID, -- ID of related post, book, or user
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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
-- 12. READING PROGRESS TABLE
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
-- 13. BOOK TAGS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS book_tags (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 14. BOOK TAG RELATIONSHIPS
-- =====================================================

CREATE TABLE IF NOT EXISTS book_tag_relationships (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES book_tags(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(book_id, tag_id)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Books table indexes
CREATE INDEX IF NOT EXISTS idx_books_user_id ON books(user_id);
CREATE INDEX IF NOT EXISTS idx_books_created_at ON books(created_at);
CREATE INDEX IF NOT EXISTS idx_books_genre ON books(genre);
CREATE INDEX IF NOT EXISTS idx_books_title_author ON books(title, author);

-- User favorites indexes
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON user_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_book_id ON user_favorites(book_id);

-- Posts indexes
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_book_id ON posts(book_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at);

-- Search indexes
CREATE INDEX IF NOT EXISTS idx_books_search ON books USING gin(to_tsvector('english', title || ' ' || author || ' ' || COALESCE(description, '')));

-- =====================================================
-- 14. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_tag_relationships ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 15. BOOKS TABLE POLICIES
-- =====================================================

-- Users can insert their own books
CREATE POLICY "Users can insert their own books" ON books
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can view all books
CREATE POLICY "Users can view all books" ON books
  FOR SELECT USING (true);

-- Users can update their own books
CREATE POLICY "Users can update their own books" ON books
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own books
CREATE POLICY "Users can delete their own books" ON books
  FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- 16. USER FAVORITES POLICIES
-- =====================================================

CREATE POLICY "Users can manage their own favorites" ON user_favorites
  FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- 17. USER PROFILES POLICIES
-- =====================================================

CREATE POLICY "Users can view all profiles" ON user_profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

-- Allow users to insert their own profile OR allow service role for signup trigger
CREATE POLICY "Users can insert their own profile" ON user_profiles
  FOR INSERT WITH CHECK (
    auth.uid() = id OR
    auth.role() = 'service_role' OR
    auth.uid() IS NULL  -- Allow during signup when user is not yet authenticated
  );

-- =====================================================
-- 18. POSTS POLICIES
-- =====================================================

CREATE POLICY "Users can view all posts" ON posts
  FOR SELECT USING (true);

CREATE POLICY "Users can create their own posts" ON posts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own posts" ON posts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own posts" ON posts
  FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- 19. OTHER TABLE POLICIES
-- =====================================================

-- User follows
CREATE POLICY "Users can manage their own follows" ON user_follows
  FOR ALL USING (auth.uid() = follower_id OR auth.uid() = following_id);

-- Post likes
CREATE POLICY "Users can manage their own likes" ON post_likes
  FOR ALL USING (auth.uid() = user_id);

-- Post comments
CREATE POLICY "Users can view all comments" ON post_comments
  FOR SELECT USING (true);

CREATE POLICY "Users can manage their own comments" ON post_comments
  FOR ALL USING (auth.uid() = user_id);

-- Notifications
CREATE POLICY "Users can view their own notifications" ON notifications
  FOR ALL USING (auth.uid() = user_id);

-- Reading progress
CREATE POLICY "Users can manage their own reading progress" ON reading_progress
  FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- 20. GRANT PERMISSIONS
-- =====================================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;

-- Grant permissions to authenticated users
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant permissions to anonymous users (for signup)
GRANT SELECT, INSERT ON TABLE user_profiles TO anon;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon;

-- Grant permissions to service role (for triggers and functions)
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO service_role;

-- =====================================================
-- 21. STORAGE BUCKET SETUP
-- =====================================================

-- Note: You'll need to create these buckets manually in the Storage section
-- or use the Storage API to create them programmatically

-- =====================================================
-- 22. TRIGGERS FOR UPDATED_AT
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_books_updated_at BEFORE UPDATE ON books
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_post_comments_updated_at BEFORE UPDATE ON post_comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reading_progress_updated_at BEFORE UPDATE ON reading_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 23. SAMPLE DATA (OPTIONAL)
-- =====================================================

-- Insert some sample achievements
INSERT INTO achievements (name, description, points) VALUES
('First Book', 'Upload your first book', 10),
('Bookworm', 'Upload 10 books', 50),
('Social Butterfly', 'Get 10 followers', 25),
('Reviewer', 'Write 5 book reviews', 30)
ON CONFLICT DO NOTHING;

-- =====================================================
-- 24. FINAL SETUP
-- =====================================================

-- Create a function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_profiles (id, username)
  VALUES (new.id, COALESCE(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'username', 'User'));
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- SCHEMA COMPLETE! 🎉
-- =====================================================

-- IMPORTANT: If you still get permission errors, you may need to run this schema
-- as a database administrator or service role. Alternatively, you can:
-- 1. Go to Supabase Dashboard > SQL Editor
-- 2. Run this schema with proper admin privileges
-- 3. Or ask your database administrator to grant the necessary permissions

-- For development/testing, you can temporarily disable RLS on user_profiles:
-- ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;
-- (Remember to re-enable it for production!)

-- Alternative: If you can't run the full schema, try this minimal setup:
-- 1. Create just the user_profiles table manually in Supabase Dashboard
-- 2. Disable RLS temporarily for testing
-- 3. Re-enable RLS and create proper policies after confirming it works




-- IMPORTANT: Storage policies are managed automatically by Supabase
-- Do NOT run storage policy commands in this schema as they require
-- superuser privileges that regular users don't have.

-- To set up storage buckets for COVERS TO DISPLAY PROPERLY:
-- 1. Go to Supabase Dashboard > Storage
-- 2. Create a bucket named 'books'
-- 3. Go to bucket settings and make it PUBLIC (allow public access)
-- 4. This allows cover images to be displayed without authentication
-- 5. Book files will still use signed URLs for security

-- Alternative: If you don't want public access, you can:
-- 1. Keep bucket private
-- 2. Use signed URLs for covers too (but they expire)
-- 3. Regenerate signed URLs when displaying covers