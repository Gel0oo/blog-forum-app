# Blog Forum App — Progress

## Preparation
- [x] Setup a flutter project.
- [x] Repo + git connection setup.
- [x] Supabase setup, schema + RLS done, storage bucket next.
- [x] Supabase storage bucket setup (post_images, public + 2 policies).
- [x] File structure

## Steps (Making the actual Project)
- [x] 1. Flutter Project + Supabase connected
- [x] 2. Auth (register/login/logout)
- [x] 3. Post listing (public, paginated)
- [x] 4. Post create/edit + images
- [x] 5. Post detail + delete
- [x] 6. Comments + images
- [x] 7. Profile (avatar + name)
- [x] 8. Deploy to vercel :D
- [ ] 9. Submit to HR

## Polishing (gotta make the website beautiful right?)
- [x] 1. Show author name + avatar on posts and comments
- [x] 2. Relative timestamps ("e.g. 2w/d/h/m/now ago")
- [ ] 3. Empty states ("No posts yet", "No comments yet")
- [x] 4. Comment count shown on post list cards
- [x] 5. Visual/style pass using design reference (spacing, colors, typography)
- [x] 6. Tap-to-enlarge image viewer
- [x] 7. Dark/Light Mode

## Key Decisions
- Images stored as separate rows (post_images, comment_images) not array columns, makes us so that they can delete individual images without rewriting a whole array.
- RLS policies at DB level (auth.uid() = user_id), not relying on frontend so that we dont end up letting users access others.
- Image files live in Supabase Storage; DB only stores the resulting URL (post_images.url & comment_images.url).
- Storage bucket is Public (handles reads), 2 policies added for insert (authenticated only) and delete (owner only, checked via folder name = user_id).
- Should have a tap to enlarge image view for comments and posts.

## Environment
- Supabase project name: blog_forum_app
- Flutter project name: blog_forum_app
- GitHub repo: https://github.com/Gel0oo/blog-forum-app
- Flutter SDK version: 3.44.0